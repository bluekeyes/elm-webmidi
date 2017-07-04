effect module WebMidi
    where { command = MidiCmd, subscription = MidiSub }
    exposing
        ( inputs
        , listen
        )

{-| Send and receive MIDI messages.


# Receiving MIDI

@docs inputs, listen

-}

import Maybe exposing (Maybe(..))
import Process
import Task exposing (Task)
import WebMidi.Event exposing (Event)
import WebMidi.LowLevel as LowLevel


-- COMANDS


type MidiCmd msg
    = Inputs (List String -> msg)


cmdMap : (a -> b) -> MidiCmd a -> MidiCmd b
cmdMap func cmd =
    case cmd of
        Inputs tagger ->
            Inputs (tagger >> func)


{-| Get the connected MIDI inputs.

If no inputs are connected or MIDI access is not available, the list is empty.

-}
inputs : (List String -> msg) -> Cmd msg
inputs tagger =
    command (Inputs tagger)



-- SUBSCRIPTIONS


type MidiSub msg
    = Listen String (Event -> msg)


subMap : (a -> b) -> MidiSub a -> MidiSub b
subMap func sub =
    case sub of
        Listen input tagger ->
            Listen input (tagger >> func)


{-| Listen for MIDI events on an input.
-}
listen : (Event -> msg) -> String -> Sub msg
listen tagger input =
    subscription (Listen input tagger)



-- MANAGER


type alias State msg =
    { access : Access msg
    , inputs : List String
    }


type Access msg
    = Unknown
    | Requesting Process.Id (List (Maybe LowLevel.MidiAccess -> Task Never ()))
    | Known (Maybe LowLevel.MidiAccess)


init : Task Never (State msg)
init =
    Task.succeed (State Unknown [])



-- HANDLE APP MESSAGES


andThenReturn val t =
    Task.andThen (\_ -> Task.succeed val) t


onEffects : Platform.Router msg Msg -> List (MidiCmd msg) -> List (MidiSub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    runCommands router cmds state
        |> Task.andThen (runSubscriptions router subs)


runCommands : Platform.Router msg Msg -> List (MidiCmd msg) -> State msg -> Task Never (State msg)
runCommands router cmds state =
    case cmds of
        [] ->
            Task.succeed state

        (Inputs tagger) :: rest ->
            let
                getInputs : Maybe LowLevel.MidiAccess -> List String
                getInputs =
                    Maybe.withDefault [] << Maybe.map inputNames

                sendInputs : Maybe LowLevel.MidiAccess -> Task Never ()
                sendInputs =
                    Platform.sendToApp router << tagger << getInputs
            in
            withAccess state router sendInputs
                |> Task.andThen (runCommands router rest)


runSubscriptions : Platform.Router msg Msg -> List (MidiSub msg) -> State msg -> Task Never (State msg)
runSubscriptions router subs state =
    case subs of
        [] ->
            Task.succeed state

        (Listen name tagger) :: rest ->
            let
                listener event =
                    Platform.sendToApp router (tagger event)

                getInput access =
                    List.head (List.filter (\i -> inputName i == name) (LowLevel.inputs access))

                register maybeAccess =
                    case maybeAccess of
                        Nothing ->
                            Task.succeed ()

                        Just access ->
                            case getInput access of
                                Nothing ->
                                    Task.succeed ()

                                Just input ->
                                    LowLevel.listen input listener
            in
            withAccess state router register
                |> Task.andThen (runSubscriptions router rest)


withAccess : State msg -> Platform.Router msg Msg -> (Maybe LowLevel.MidiAccess -> Task Never ()) -> Task Never (State msg)
withAccess state router action =
    case state.access of
        Unknown ->
            requestAccess router
                |> Task.andThen
                    (\pid ->
                        Task.succeed
                            { state
                                | access = Requesting pid [ action ]
                            }
                    )

        Requesting pid pending ->
            Task.succeed
                { state
                    | access = Requesting pid (action :: pending)
                }

        Known access ->
            action access |> andThenReturn state


requestAccess : Platform.Router msg Msg -> Task x Process.Id
requestAccess router =
    let
        goodAccess access =
            Platform.sendToSelf router (ReceiveAccess (Just access))

        badAccess _ =
            Platform.sendToSelf router (ReceiveAccess Nothing)

        attemptAccess =
            LowLevel.requestAccess { sysex = False, software = False }
                |> Task.andThen goodAccess
                |> Task.onError badAccess
    in
    Process.spawn attemptAccess


inputNames : LowLevel.MidiAccess -> List String
inputNames access =
    List.map inputName (LowLevel.inputs access)


inputName : LowLevel.MidiInput -> String
inputName =
    .name << LowLevel.portDetails << LowLevel.Input



-- HANDLE SELF MESSAGES


type Msg
    = ReceiveAccess (Maybe LowLevel.MidiAccess)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router selfMsg state =
    case selfMsg of
        ReceiveAccess access ->
            let
                runPending =
                    case state.access of
                        Requesting _ pending ->
                            Task.sequence (List.map (\action -> action access) pending)

                        _ ->
                            Task.succeed [ () ]
            in
            runPending |> andThenReturn { state | access = Known access }

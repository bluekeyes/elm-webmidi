effect module WebMidi where { command = MidiCmd, subscription = MidiSub } exposing
    ( inputs
    , listen
    )

{-| Send and receive MIDI messages.

# Receiving MIDI
@docs inputs, listen

-}

import Process
import Task exposing (Task)
import Maybe exposing (Maybe(..))

import WebMidi.LowLevel as LowLevel
import WebMidi.Event exposing (Event)


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
listen : String -> (Event -> msg) -> Sub msg
listen input tagger =
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

{- Discards the result of a task and succeeds with a given value.
-}
andThenReturn val t = Task.andThen (\_ -> Task.succeed val) t


onEffects : Platform.Router msg Msg -> List (MidiCmd msg) -> List (MidiSub msg) -> State msg -> Task Never (State msg)
onEffects router cmds subs state =
    runCommands router cmds state
        |> Task.andThen (runSubscriptions router subs)


runCommands : Platform.Router msg Msg -> List (MidiCmd msg) -> State msg -> Task Never (State msg)
runCommands router cmds state =
    case cmds of
        [] ->
            Task.succeed state

        Inputs tagger :: rest ->
            let
                getAndTagInputs = tagger << Maybe.withDefault [] << Maybe.map getInputNames
                sendInputs = Platform.sendToApp router << getAndTagInputs
            in
                withAccess state router sendInputs
                    |> Task.andThen (runCommands router rest)


runSubscriptions : Platform.Router msg Msg -> List (MidiSub msg) -> State msg -> Task Never (State msg)
runSubscriptions router subs state =
    case subs of
        [] ->
            Task.succeed state

        Listen name tagger :: rest ->
            Task.succeed state


withAccess : State msg -> Platform.Router msg Msg -> (Maybe LowLevel.MidiAccess -> Task Never ()) -> Task Never (State msg)
withAccess state router action =
    case state.access of
        Unknown ->
            requestAccess router |> Task.andThen (\pid ->
                Task.succeed { state |
                    access = Requesting pid [action]
                })

        Requesting pid pending ->
            Task.succeed { state |
                access = Requesting pid (action :: pending)
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


getInputNames : LowLevel.MidiAccess -> List String
getInputNames access =
    let
        getName input = (LowLevel.portDetails (LowLevel.Input input)) |> .name
    in
        List.map getName (LowLevel.inputs access)


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
                            Task.succeed [()]
            in
                runPending |> andThenReturn { state | access = Known access }

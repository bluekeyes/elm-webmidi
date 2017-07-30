effect module WebMidi
    where { command = MidiCmd, subscription = MidiSub }
    exposing
        ( checkAccess
        , inputs
        , listen
        )

{-| Send and receive MIDI messages.

MIDI is the standard protocol used by music software and digital instruments to
communicate. This module lets you interact with these devices from your web
application, in [supported browsers](http://caniuse.com/#feat=midi).

It provides a simple interface for sending and receiving messages, which should
support typical applications. Applications that need full access to the Web
MIDI API should use lower-level module.


# Errors

To simplify the API, any errors encountered when opening ports or sending and
receiving messages are silently discarded. In particular, this module will
silently not work in browsers that do not support the Web MIDI API. Be sure to
test for MIDI access before taking any actions if this is a problem.


# Receiving Messages

@docs inputs, listen


# Testing For Access

@docs checkAccess

-}

import Dict exposing (Dict)
import Process
import Task exposing (Task)
import WebMidi.Event exposing (Event)
import WebMidi.LowLevel as LowLevel


-- COMANDS


type MidiCmd msg
    = Inputs (List String -> msg)
    | CheckAccess (Bool -> msg)


cmdMap : (a -> b) -> MidiCmd a -> MidiCmd b
cmdMap func cmd =
    case cmd of
        Inputs tagger ->
            Inputs (tagger >> func)

        CheckAccess tagger ->
            CheckAccess (tagger >> func)


{-| Get the connected MIDI inputs.

If no inputs are connected or MIDI access is not available, the list is empty.

-}
inputs : (List String -> msg) -> Cmd msg
inputs tagger =
    command (Inputs tagger)


{-| Checks if MIDI access is available.
-}
checkAccess : (Bool -> msg) -> Cmd msg
checkAccess tagger =
    command (CheckAccess tagger)



-- SUBSCRIPTIONS


type MidiSub msg
    = Listen String (Event -> msg)


subMap : (a -> b) -> MidiSub a -> MidiSub b
subMap func sub =
    case sub of
        Listen input tagger ->
            Listen input (tagger >> func)


{-| Listen for MIDI events on an input.

If the input is not connected or MIDI access is not available, no messages will
be delivered for the subscription.

-}
listen : (Event -> msg) -> String -> Sub msg
listen tagger input =
    subscription (Listen input tagger)



-- MANAGER


type alias InputDict msg =
    Dict String (List (Event -> msg))


type alias State msg =
    { access : Access
    , inputs : InputDict msg
    }


type Access
    = Unknown
    | Requesting Process.Id (List (Maybe LowLevel.MidiAccess -> Task Never ()))
    | Known (Maybe LowLevel.MidiAccess)


init : Task Never (State msg)
init =
    Task.succeed (State Unknown Dict.empty)



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

        (CheckAccess tagger) :: rest ->
            let
                hasAccess =
                    Maybe.withDefault False << Maybe.map (always True)

                checkAccess =
                    Platform.sendToApp router << tagger << hasAccess
            in
            withAccess state router checkAccess
                |> Task.andThen (runCommands router rest)


runSubscriptions : Platform.Router msg Msg -> List (MidiSub msg) -> State msg -> Task Never (State msg)
runSubscriptions router subs state =
    let
        newInputs =
            List.foldl addInput Dict.empty subs

        left name taggers ( toClose, toOpen ) =
            ( toClose, name :: toOpen )

        both _ _ _ ( toClose, toOpen ) =
            ( toClose, toOpen )

        right name taggers ( toClose, toOpen ) =
            ( name :: toClose, toOpen )

        ( toClose, toOpen ) =
            Dict.merge left both right newInputs state.inputs ( [], [] )

        closeAndOpenInputs access =
            closeInputs access toClose
                |> Task.andThen (\_ -> openInputs router access toOpen)

        action =
            Maybe.withDefault (Task.succeed ()) << Maybe.map closeAndOpenInputs
    in
    withAccess state router action
        |> Task.andThen (\newState -> Task.succeed { newState | inputs = newInputs })


addInput : MidiSub msg -> InputDict msg -> InputDict msg
addInput (Listen name tagger) state =
    case Dict.get name state of
        Nothing ->
            Dict.insert name [ tagger ] state

        Just taggers ->
            Dict.insert name (tagger :: taggers) state


closeInputs : LowLevel.MidiAccess -> List String -> Task x ()
closeInputs access inputs =
    case inputs of
        [] ->
            Task.succeed ()

        name :: rest ->
            let
                spawnClose =
                    Process.spawn << LowLevel.close << LowLevel.Input

                closeInput =
                    Maybe.map spawnClose (findInput access name)
                        |> Maybe.map (andThenReturn ())
                        |> Maybe.withDefault (Task.succeed ())
            in
            closeInput
                |> Task.andThen (\_ -> closeInputs access rest)


openInputs : Platform.Router msg Msg -> LowLevel.MidiAccess -> List String -> Task x ()
openInputs router access inputs =
    case inputs of
        [] ->
            Task.succeed ()

        name :: rest ->
            let
                listener =
                    Platform.sendToSelf router << ReceiveEvent name

                spawnOpen input =
                    Process.spawn (LowLevel.listen input listener)

                openInput =
                    Maybe.map spawnOpen (findInput access name)
                        |> Maybe.map (andThenReturn ())
                        |> Maybe.withDefault (Task.succeed ())
            in
            openInput
                |> Task.andThen (\_ -> openInputs router access rest)


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


findInput : LowLevel.MidiAccess -> String -> Maybe LowLevel.MidiInput
findInput access name =
    List.head (List.filter (\i -> inputName i == name) (LowLevel.inputs access))



-- HANDLE SELF MESSAGES


type Msg
    = ReceiveAccess (Maybe LowLevel.MidiAccess)
    | ReceiveEvent String Event


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

        ReceiveEvent name event ->
            case Dict.get name state.inputs of
                Nothing ->
                    Task.succeed state

                Just taggers ->
                    let
                        notify =
                            Task.sequence << List.map (\tagger -> Platform.sendToApp router (tagger event))
                    in
                    notify taggers |> andThenReturn state

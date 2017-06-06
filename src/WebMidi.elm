effect module WebMidi where { command = MidiCmd, subscription = MidiSub } exposing
    ( inputs
    , listen
    )

{-| Send and receive MIDI messages.

# Receiving MIDI
@docs inputs, listen

-}

import Process
import Maybe exposing (Maybe(..))
import Task exposing (Task)

import WebMidi.LowLevel
import WebMidi.Event exposing (Event)


-- COMANDS

type MidiCmd msg
    = None


cmdMap : (a -> b) -> MidiCmd a -> MidiCmd b
cmdMap func cmd =
    case cmd of
        None -> None



-- SUBSCRIPTIONS

type MidiSub msg
    = Inputs (List String -> msg)
    | Listen String (Event -> msg)


subMap : (a -> b) -> MidiSub a -> MidiSub b
subMap func sub =
    case sub of
        Inputs tagger ->
            Inputs (tagger >> func)

        Listen input tagger ->
            Listen input (tagger >> func)


{-| Get notified when input devices are connected or disconnected.

An event is sent each time a device connects or disconnects and contains a full
list of connected device names. The current devices are also sent when the
subscription is created.
-}
inputs : (List String -> msg) -> Sub msg
inputs tagger =
    subscription (Inputs tagger)



{-| Listen for MIDI events on an input.
-}
listen : String -> (Event -> msg) -> Sub msg
listen input tagger =
    subscription (Listen input tagger)


-- MANAGER

type alias State =
    { access : Maybe WebMidi.LowLevel.MidiAccess
    }

init : Task Never State
init =
    Task.succeed { access = Nothing }


onEffects : Platform.Router msg Msg -> List (MidiCmd msg) -> List (MidiSub msg) -> State -> Task Never State
onEffects router cmds subs state =
    Task.succeed state


type Msg
    = ReceiveInputs (List String)

onSelfMsg : Platform.Router msg Msg -> Msg -> State -> Task Never State
onSelfMsg router selfMsg state =
    Task.succeed state

module WebMidi.Event exposing
    ( Event
    , Channel, Message(..)
    )

{-| Event type for the Web MIDI API.

@docs Event, Channel, Message

-}

import Time exposing (Time)


{-| A MIDI event, a message at a specific time.
-}
type alias Event =
    { time : Time
    , message : Message
    }


{-| A MIDI channel (1 - 16).
-}
type alias Channel = Int


{-| A MIDI message.
-}
type Message
    {- channel messages -}
    = NoteOff Channel Int Int
    | NoteOn Channel Int Int
    | KeyPressure Channel Int Int
    | ControlChange Channel Int Int
    | ProgramChange Channel Int
    | ChannelPressure Channel Int
    | PitchBend Channel Int

    {- system messages -}
    | SysEx (List Int)
    | TimeCodeQuarterFrame Int Int
    | SongPosition Int
    | SongSelect Int
    | TuneRequest
    | TimingClock
    | StartSequence
    | ContinueSequence
    | StopSequence
    | ActiveSensing
    | Reset

module WebMidi.Event exposing
    ( Event
    , Channel, Message(..)
    , formatMessage
    )

{-| Event type for the Web MIDI API.

@docs Event, Channel, Message

# Display Functions

@docs formatMessage

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


{-| Creates a string representation of a message. Useful for debugging or
logging messages.
-}
formatMessage : Message -> String
formatMessage m =
    let
        fmt name fields =
            name ++ "[" ++ String.join ", " (List.map (\(k, v) -> k ++ ": " ++ toString v) fields) ++ "]"
    in
        case m of
            NoteOff c note vel ->
                fmt "NoteOff" [("chan", c), ("note", note), ("vel", vel)]
            NoteOn c note vel ->
                fmt "NoteOn" [("chan", c), ("note", note), ("vel", vel)]
            KeyPressure c note val ->
                fmt "KeyPressure" [("chan", c), ("note", note), ("val", val)]
            ControlChange c ctrl val ->
                fmt "ControlChange" [("chan", c), ("ctrl", ctrl), ("val", val)]
            ProgramChange c prgm ->
                fmt "ProgramChange" [("chan", c), ("prgm", prgm)]
            ChannelPressure c val ->
                fmt "ChannelPressure" [("chan", c), ("val", val)]
            PitchBend c val ->
                fmt "PitchBend" [("chan", c), ("val", val)]
            SysEx data ->
                fmt "SysEx" [("bytes", List.length data)]
            TimeCodeQuarterFrame typ val ->
                fmt "TimeCodeQuarterFrame" [("type", typ), ("val", val)]
            SongPosition pos ->
                fmt "SongPosition" [("pos", pos)]
            SongSelect song ->
                fmt "SongPosition" [("song", song)]
            TuneRequest ->
                "TuneRequest"
            TimingClock ->
                "TimingClock"
            StartSequence ->
                "StartSequence"
            ContinueSequence ->
                "ContinueSequence"
            StopSequence ->
                "StopSequence"
            ActiveSensing ->
                "ActiveSensing"
            Reset ->
                "Reset"

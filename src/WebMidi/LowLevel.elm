module WebMidi.LowLevel
    exposing
        ( BadAccess(..)
        , ConnectionState(..)
        , DeviceState(..)
        , MidiAccess
        , MidiInput
        , MidiOutput
        , MidiPort(..)
        , Options
        , PortDetails
        , close
        , inputs
        , listen
        , portDetails
        , requestAccess
        )

{-| Low-level access for the Web MIDI API.


# Access

@docs MidiAccess, Options
@docs requestAccess, BadAccess


# Ports

@docs MidiPort, PortDetails, DeviceState, ConnectionState
@docs portDetails, close


# Inputs

@docs MidiInput
@docs inputs, listen


# Outputs

@docs MidiOutput

-}

import Array exposing (Array)
import Native.WebMidi
import Task exposing (Task)
import WebMidi.Event exposing (Event)


{-| Provides access to MIDI inputs and outputs.
-}
type MidiAccess
    = MidiAccess


{-| Requests access to MIDI functionality from the browser.
-}
requestAccess : Options -> Task BadAccess MidiAccess
requestAccess =
    Native.WebMidi.requestAccess


{-| Possible errors when requesting MIDI access.
-}
type BadAccess
    = BadSecurity
    | BadAbort
    | BadState
    | BadSupport


{-| Options for requesting MIDI access.
-}
type alias Options =
    { sysex : Bool
    , software : Bool
    }


{-| The state of the MIDI device attached to a port.
-}
type DeviceState
    = Disconnected
    | Connected


{-| The state of a connection on a MIDI port.
-}
type ConnectionState
    = Open
    | Closed
    | Pending


{-| Information about a MIDI port (input or output)
-}
type alias PortDetails =
    { id : String
    , manufacturer : String
    , name : String
    , version : String
    , state : DeviceState
    , connection : ConnectionState
    }


{-| An opaque type for input ports.
-}
type MidiInput
    = MidiInput


{-| An opaque type for output ports.
-}
type MidiOutput
    = MidiOutput


{-| A MIDI port.
-}
type MidiPort
    = Input MidiInput
    | Output MidiOutput


{-| Returns details about a MIDI port.
-}
portDetails : MidiPort -> PortDetails
portDetails =
    Native.WebMidi.portDetails


{-| Closes a MIDI port.
-}
close : MidiPort -> Task x ()
close =
    Native.WebMidi.close


{-| Lists the available inputs.
-}
inputs : MidiAccess -> List MidiInput
inputs =
    Native.WebMidi.inputs


{-| Listens for messages on an input.
-}
listen : MidiInput -> (Event -> Task Never ()) -> Task x ()
listen =
    Native.WebMidi.listen

module WebMidi.LowLevel exposing
    ( MidiAccess
    , Options
    , MidiInput, MidiOutput, MidiPort(..), PortDetails
    , DeviceState(..), ConnectionState(..)
    , MidiMessage(..)
    , requestAccess
    , portDetails
    , inputs
    , listen
    , BadAccess(..)
    )


{-| Low-level access for the Web MIDI API.

# Access
@docs MidiAccess, Options, BadAccess

# Ports
@docs MidiInput, MidiOutput, MidiPort
@docs PortDetails, DeviceState, ConnectionState

# Messages
@docs MidiMessage

# Functions
@docs requestAccess, portDetails, inputs, listen

-}


import Array exposing (Array)
import Task exposing (Task)
import Time exposing (Time)

import Native.WebMidi


{-| Provides access to MIDI inputs and outputs.
-}
type MidiAccess = MidiAccess


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
type DeviceState = Disconnected | Connected


{-| The state of a connection on a MIDI port.
-}
type ConnectionState = Open | Closed | Pending


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
type MidiInput = MidiInput


{-| An opaque type for output ports.
-}
type MidiOutput = MidiOutput


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


{-| Lists the available inputs.
-}
inputs : MidiAccess -> List MidiInput
inputs =
    Native.WebMidi.inputs

{-| A generic MIDI message.
-}
type MidiMessage
    = Channel Int Int Int
    | System Int Int Int
    | SysEx (Array Int)

{-| Listens for messages on an input.
-}
listen : (Time -> MidiMessage -> Task Never a) -> MidiInput -> ()
listen =
    Native.WebMidi.listen

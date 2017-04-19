module WebMidi.LowLevel exposing
    ( MidiAccess
    , BadAccess
    , requestAccess
    , inputs
    )


{-| Low-level access for the Web MIDI API.

# Types
@docs MidiAccess, BadAccess

# Functions
@docs requestAccess, inputs

-}


import Native.WebMidi
import Task exposing (Task)


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


type alias Options =
    { sysex : Bool
    , software : Bool
    }


{-| Lists the available inputs.
-}
inputs : MidiAccess -> Task Never (List String)
inputs =
    Native.WebMidi.inputs

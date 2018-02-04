:warning: **This library is incomplete and unsupported!**

_After working more with Elm, I've decided that it is not the right tool 
for the application that originally led to this library. As a result, I
won't be implementing output ports or fixing issues with the code. Feel
free to create a fork if you'd like to continue development, but rumor has
it that native and effect modules will be completely different in Elm 0.19._

# WebMIDI

The [WebMIDI API](https://webaudio.github.io/web-midi-api/) lets you access
MIDI devices from the browser. This is an [Elm](https://elm-lang.org) library
for using this API.

It's compatible with Elm 0.18 and uses native and effect modules, so it works
without any external dependencies.

This library is still in development and the API may change in the future. In
particular, only input ports are supported at the moment.

## Credits

[newlandsvalley/elm-webmidi](https://github.com/newlandsvalley/elm-webmidi)
provided inspiration and is an alternative for older versions of Elm.

[newlandsvalley/elm-webmidi-ports](https://github.com/newlandsvalley/elm-webmidi-ports)
is another alternative for Elm 0.18, but uses ports and is therefore not
available in the package repository.

[elm-lang/websockets](https://github.com/elm-lang/websocket) provided a helpful
example of how to write native integrations and use effect modules.

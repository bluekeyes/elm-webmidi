var _bluekeyes$elm_webmidi$Native_WebMidi = (function () {

  const errorCtors = {
    'SecurityError': 'BadSecurity',
    'AbortError': 'BadAbort',
    'InvalidStateError': 'BadState',
    'NotSupportedError': 'BadSupport',
  };

  function requestAccess(options) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      navigator.requestMIDIAccess(options).then(
        function (access) {
          callback(_elm_lang$core$Native_Scheduler.succeed(access));
        },
        function (err) {
          callback(_elm_lang$core$Native_Scheduler.fail({
            ctor: errorCtors[err.name] || 'BadSupport',
            _0: err.message,
          }));
        }
      );
    });
  }

  function strToType(str) {
    return { ctor: str.charAt(0).toUpperCase() + str.slice(1) };
  }

  function channelMsg(data) {
    const chan = (data[0] & 0x0F) + 1;
    switch (data[0] & 0xF0) {
      case 0x80:
        return {
          ctor: 'NoteOff',
          _0: chan,
          _1: data[1],
          _2: data[2],
        };
      case 0x90:
        return {
          ctor: 'NoteOn',
          _0: chan,
          _1: data[1],
          _2: data[2],
        };
      case 0xA0:
        return {
          ctor: 'KeyPressure',
          _0: chan,
          _1: data[1],
          _2: data[2],
        };
      case 0xB0:
        return {
          ctor: 'ControlChange',
          _0: chan,
          _1: data[1],
          _2: data[2],
        };
      case 0xC0:
        return {
          ctor: 'ProgramChange',
          _0: chan,
          _1: data[1],
        };
      case 0xD0:
        return {
          ctor: 'ChannelPressure',
          _0: chan,
          _1: data[1],
        };
      case 0xE0:
        return {
          ctor: 'PitchBend',
          _0: chan,
          _1: (data[2] << 7) | data[1],
        };
    }
  }

  function systemMsg(data) {
    switch (data[0] & 0x0F) {
      case 0x0:
        return {
          ctor: 'SysEx',
          _0: _elm_lang$core$Native_List.fromArray(data.slice(1)),
        };
      case 0x1:
        return {
          ctor: 'TimeCodeQuarterFrame',
          _0: (data[1] >> 4) & 0x70,
          _1: data[1] & 0x0F,
        };
      case 0x2:
        return {
          ctor: 'SongPosition',
          _0: (data[2] << 7) | data[1],
        };
      case 0x3:
        return {
          ctor: 'SongSelect',
          _0: data[1],
        };
      case 0x6:
        return {
          ctor: 'TuneRequest',
        };
      case 0x8:
        return {
          ctor: 'TimingClock',
        };
      case 0xA:
        return {
          ctor: 'StartSequence',
        };
      case 0xB:
        return {
          ctor: 'ContinueSequence',
        };
      case 0xC:
        return {
          ctor: 'StopSequence',
        };
      case 0xE:
        return {
          ctor: 'ActiveSensing',
        };
      case 0xF:
        return {
          ctor: 'Reset',
        };
    }
  }

  function portDetails(port) {
    port = port._0;
    return {
      ctor: 'PortDetails',
      id: port.id,
      manufacturer: port.manufacturer || '',
      name: port.name || '',
      version: port.version || '',
      state: strToType(port.state),
      connection: strToType(port.connection),
    };
  }

  function close(port) {
    port = port._0
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      port.close().then(
        function () {
          callback(_elm_lang$core$Native_Scheduler.succeed());
        },
        function () {
          callback(_elm_lang$core$Native_Scheduler.fail());
        }
      );
    });
  }

  function inputs(access) {
    return _elm_lang$core$Native_List.fromArray(Array.from(access.inputs.values()));
  }

  function listen(input, onMessage) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      input.onmidimessage = function (event) {
        const time = _elm_lang$core$Time$millisecond * event.timeStamp;
        const msg = (event.data & 0xF0) === 0xF0 ? systemMsg(event.data) : channelMsg(event.data);

        _elm_lang$core$Native_Scheduler.rawSpawn(onMessage({
          ctor: 'Event',
          time: time,
          message: msg,
        }));
      };

      callback(_elm_lang$core$Native_Scheduler.succeed());
    });
  }

  return {
    close: close,
    inputs: inputs,
    listen: F2(listen),
    portDetails: portDetails,
    requestAccess: requestAccess,
  };

})();

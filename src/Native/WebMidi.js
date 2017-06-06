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

  function inputs(access) {
    return _elm_lang$core$Native_List.fromArray(Array.from(access.inputs.values()));
  }

  function listen(onMessage, input) {
    input.onmidimessage = function (event) {
      var time = _elm_lang$core$Time$millisecond * event.timeStamp;
      var data = event.data;

      var msg;
      if (data[0] & 0xF0 === 0xF0) {
        if (data[0] & 0x0F === 0x00) {
          msg = {
            ctor: 'SysEx',
            _0: _elm_lang$core$Native_Array.initialize(data.length, function (i) {
              return data[i];
            }),
          };
        } else {
          msg = {
            ctor: 'System',
            _0: data[0], _1: data[1], _2: data[2],
          };
        }
      } else {
        msg = {
          ctor: 'Channel',
          _0: data[0], _1: data[1], _2: data[2],
        };
      }

      _elm_lang$core$Native_Scheduler.rawSpawn(A2(onMessage, time, msg));
    };
  }

  return {
    requestAccess: requestAccess,
    portDetails: portDetails,
    inputs: inputs,
    listen: F2(listen),
  };

})();

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

  function inputs(access) {
    return _elm_lang$core$Native_Scheduler.nativeBinding(function (callback) {
      let inputs = _elm_lang$core$Native_List.Nil
      for (let input of access.inputs.values()) {
        inputs = _elm_lang$core$Native_List.Cons(input.name, inputs);
      }
      callback(_elm_lang$core$Native_Scheduler.succeed(inputs));
    });
  }

  return {
    requestAccess: requestAccess,
    inputs: inputs,
  };

})();

var _pauldijou$elm_macros$Native_Runner = function () {
  var scheduler = _elm_lang$core$Native_Scheduler

  function handle(handler, content) {
    console.log('HANDLE');
    var result

    try {
      result = handler(content)
    } catch (e) {
      return Promise.reject(e)
    }

    console.log('typeof', typeof result)
    if (typeof result !== 'Promise') {
      result = Promise.resolve(result)
    }

    return scheduler.nativeBinding(function (callback) {
      result.then(content => {
        callback(scheduler.succeed(content))
      }).catch(err => {
        callback(scheduler.fail(content))
      })
    })
  }

  return {
    handle: F2(handle)
  }
}()

const Elm = require('../src/Macros/Runner')

function start(config) {
  var runner = Elm.Macros.Runner.worker(config)

  runner.ports.render.subscribe(result => {
    const { timeoutId, resolve, reject } = result.meta

    clearTimeout(timeoutId)

    if (result.error) {
      reject(result.error)
    } else {
      resolve(result.content)
    }
  })

  runner.parse = content =>
    new Promise((resolve, reject) => {
      const timeoutId = setTimeout(function () {
        reject(new Error('Timeout, failed to parse and generate macro in less than 5sec'))
      }, 5000)

      const portValue = {
        content: content,
        meta: {
          timeoutId: timeoutId,
          resolve: resolve,
          reject: reject,
        }
      }

      runner.ports.parse.send(portValue)
    })

  return runner
}

module.exports = {
  start: start
}

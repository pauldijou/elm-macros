const loaderUtils = require('loader-utils')
const startRunner = require('../dist/runner').start

var runner = undefined

function elmMacrosLoader(content) {
  const callback = this.async()

  if (!runner) {
    const options = loaderUtils.getOptions(this)
    const macros = Object.keys(options.macros || {}).reduce((acc, key) => {
      acc.push([ key, options.macros[key] ])
      return acc
    }, [])

    runner = startRunner({
      debug: options.debug,
      macros: macros
    })
  }

  runner.parse(content)
    .then(output => {
      callback(null, output)
    })
    .catch(error => {
      if (typeof error === 'string') {
        error = new Error(error)
      }
      callback(error)
    })
}

module.exports = elmMacrosLoader

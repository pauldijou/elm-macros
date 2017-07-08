var path = require('path')
var elmMacros = require('../index')

console.log('EXAMPLE CONFIG')

module.exports = {
  entry: './index.js',

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: "[name].js"
  },

  resolve: {
    extensions: ['.js', '.elm']
  },

  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: [
        'elm-webpack-loader',
        {
          // Replace with: loader: 'elm-macros-loader',
          loader: require.resolve('../lib/loader'),
          options: {
            debug: false,
            macros: {
              decoder: function (content) {
                console.log("MACRO DECODER")
                return content
              }
            }
          }
        }
      ]
    }]
  }
};

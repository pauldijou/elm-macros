var path = require('path')
var webpack = require('webpack')

console.log('ROOT CONFIG')

module.exports = {
  target: 'node',

  entry: {
    runner: './lib/runner.js',
    // loader: './lib/loader.js'
  },

  output: {
    path: path.resolve(__dirname, 'dist'),
    filename: '[name].js',
    libraryTarget: 'commonjs2'
  },

  resolve: {
    extensions: ['.js', '.elm']
  },

  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      loader: 'elm-webpack-loader'
    }]
  },

  plugins: [
    new webpack.optimize.ModuleConcatenationPlugin()
  ]
};

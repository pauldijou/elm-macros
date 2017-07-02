# elm-macros

> *WORK IN PROGRESS* Does not work at all right now.

Simple but useful macros in Elm using Webpack loader. Everything happens right before compile time so it's just as safe as any standard Elm code.

## Usage

```elm
module Main exposing (..)

type alias User =
  { name: String
  , age: Maybe Int
  }

-- You write
userDecoder: Macro
userDecoder =
  Macros.generate "decoder" [ Macros.param "ctor" User ]

userKeys: Macro
userKeys =
  Macros.generate "keys" [ Macro.param "ctor" User ]

-- Macros will generate
userDecoder: Json.Decode.Decoder User
userDecoder =
  Json.Decode.map2
    User
    (Json.Decode.string)
    (Json.Decode.maybe (Json.Decode.int))

userKeys: List String
userKeys =
  [ "name", "age" ]
```

## Install

The easiest way to use `elm-macros` is through a Webpack loader.

```bash
npm install --save-dev elm-macros
yarn add --dev elm-macros
```

```javascript
// webpack.config.js
var elmMacros = require('../index')

module.exports = {
  entry: './index.js',
  output: { path: './dist', filename: "[name].js" },
  resolve: { extensions: ['.js', '.elm'] },

  module: {
    rules: [{
      test: /\.elm$/,
      exclude: [/elm-stuff/, /node_modules/],
      use: [
        'elm-webpack-loader',
        // Must be after you Elm loader so it runs before it
        {
          loader: 'elm-macros',
          options: {
            // If true, all macros will be in debug mode
            debug: false,
            // You can register as many macros as you want
            // The object key is the name you will need to use in "Macros.generate"
            macros: {
              decoder: elmMacros.decoder,
              keys: elmMacros.keys,
            }
          }
        }
      ]
    }]
  }
};
```

## Use a macro

All macros use the same declaration API.

```elm
-- You must put the Macro, it is used to detect the beginning of a macro
yourVariable: Macro
yourVariable =
  Macros.generate
    -- This is the key from webpack.config.js
    -- specify which macro to use
    "macroName"
    -- Those are modifiers used to customize the resulting generated code
    -- Check each macro documentation to know which ones are used
    [ Macros.debug -- Enable debug mode for the macro, will print the generated code
    , Macros.param "ctor" User -- Apply needed params to the macro
    , Macros.override "field" "customValue" -- Override parts of generated code in order to fit your needs
    ]

-- Sample
userDecoder: Macro
userDecoder =
  Macros.generate "decoder" [ Macros.param "ctor" User, Macros.override "age" "customAgeDecoder" ]
```

## Write a macro

Coming soon...

## License

This software is licensed under the Apache 2 license, quoted below.

Copyright Paul Dijou ([http://pauldijou.fr](http://pauldijou.fr)).

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this project except in compliance with the License. You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0).

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

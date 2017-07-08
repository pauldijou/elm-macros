module Main exposing (main)

import Macros exposing (Macro)

{-|

@docs main

-}

type alias Model = String

type Msg
  = None

type alias User = { name: String }

userDecoder: Macro (Json.Decode.Decoder User)
userDecoder =
  Macros.generate "decoder" [ Macros.param "ctor" User ]

{-| Yo lol -}
main: Program Never Model Msg
main =
  Platform.program
    { init = init
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
  "" ! []

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    None -> model ! []

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.none

module Main exposing (main)

{-|

@docs main

-}

type alias Model =
  {}

type Msg
  = None

{-| -}
main: Program Never Model Msg
main =
  Platform.program
    { init = init
    , update = update
    , subscriptions = subscriptions
    }

init: (Model, Cmd Msg)
init =
  {} ! []

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    None -> model ! []

subscriptions: Model -> Sub Msg
subscriptions model =
  Sub.none

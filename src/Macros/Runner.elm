port module Macros.Runner exposing (main)

import Task exposing (Task)
import Json.Encode
import Json.Decode

import Ast
import Ast.Statement exposing (..)

import Macros.Helpers exposing (..)
import Macros.Internal exposing (..)

type alias Flags =
  { debug: Bool
  , macros: List (String, Json.Encode.Value)
  }

type alias Model =
  { debug: Bool
  , macros: List (String, Json.Encode.Value)
  }

type Msg
  = Parse In
  | Parsed Meta (Result String String)

type alias Meta =
  { timeoutId: Json.Encode.Value
  , resolve: Json.Encode.Value
  , reject: Json.Encode.Value
  }

type alias In =
  { content: String
  , meta: Meta
  }

type alias Out =
  { content: String
  , meta: Meta
  , error: Maybe String
  }

main: Program Flags Model Msg
main =
  Platform.programWithFlags
    { init = init
    , update = update
    , subscriptions = subscriptions
    }

init: Flags -> (Model, Cmd Msg)
init flags =
  { debug = flags.debug
  , macros = flags.macros
  } ! []

update: Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Parse input ->
      model ! [ Task.attempt (Parsed input.meta) (parseContent model input.content) ]

    Parsed meta res ->
      case res of
        Ok output -> model ! [ render { content = output, meta = meta, error = Nothing } ]
        Err err -> model ! [ render { content = "", meta = meta, error = Just err } ]

subscriptions: Model -> Sub Msg
subscriptions model =
  parse Parse

port parse: (In -> msg) -> Sub msg

port render: Out -> Cmd msg

parseContent: Model -> String -> Task String String
parseContent model content =
  case Ast.parse content of
    Ok (_, _, statements) ->
      handleStatements model content statements

    -- Invalid Elm syntax, let's Elm compiler display the error
    Err _ ->
      Task.succeed content

handleStatements: Model -> String -> List Statement -> Task String String
handleStatements model content statements =
  List.foldl
    (\stmt acc ->
      case stmt of
        ImportStatement moduleName mAlias mExposing ->
          { acc | context = Context.addImport moduleName mAlias mExposing }

        stmt ->
          if 
    )
    { context = Context.init, task = Task.succeed content }
    statement

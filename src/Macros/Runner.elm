port module Macros.Runner exposing (main)

import Task exposing (Task)
import Json.Encode
import Json.Decode

import Ast
import Ast.Statement exposing (..)

import Macros.Helpers as Helpers exposing (..)
import Macros.Internal as Internal exposing (..)
import Macros.Context as Context exposing (..)

import Native.Runner

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
  case Debug.log "AST" <| Ast.parse <| Debug.log "content" content of
    Ok (_, _, statements) ->
      handleStatements model statements Context.init (Task.succeed content)

    -- Invalid Elm syntax, let's Elm compiler display the error
    Err _ ->
      Task.succeed content

handleStatements: Model -> List Statement -> Context -> Task String String -> Task String String
handleStatements model statements context task =
  case statements of
    [] -> task
    [ stmt ] -> task
    stmt1 :: stmt2 :: rest ->
      case Internal.isMacroDeclaration stmt1 of
        -- We found a macro declaration !
        Just res -> case Debug.log "isMacroDeclaration" res of
          Err e -> Task.fail e
          Ok target ->
            -- Let's parse the macro on the next statement
            case Internal.ast2macro target stmt2 of
              Ok macro ->
                let
                  mHandler =
                    model.macros
                    |> List.filter (\(name, _) -> name == macro.name)
                    |> List.head
                    |> Maybe.map Tuple.second
                in
                  case mHandler of
                    Nothing -> Task.fail <| "Unknow macro [" ++ macro.name ++ "]. Did you forgot to add it to your webpack config?"
                    Just handler ->
                      task
                      |> Task.andThen (\content ->
                        handle handler content
                      )

              Err e -> Task.fail e

        -- Normal statement
        Nothing ->
          case stmt1 of
            ImportStatement moduleName mAlias mExposing ->
              let
                ctx = Context.addImport moduleName mAlias mExposing context
              in
                handleStatements model (stmt2 :: rest) ctx task

            FunctionTypeDeclaration name signature ->
              let
                ctx = Context.addVariable name signature context
              in
                handleStatements model (stmt2 :: rest) ctx task

            _ ->
              handleStatements model (stmt2 :: rest) context task

handle: Json.Encode.Value -> String -> Task String String
handle =
  Native.Runner.handle

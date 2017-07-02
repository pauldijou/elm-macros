module Macros.Internal exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode

import Ast
import Ast.BinOp exposing (..)
import Ast.Expression exposing (..)
import Ast.Statement exposing (..)

import Macros.Helpers as Helpers exposing (Macro, Modifier(..))

moduleName: String
moduleName = "Macros"

isMacroDeclaration: Statement -> Result String (Maybe String)
isMacroDeclaration stmt =
  case stmt of
    FunctionTypeDeclaration variable typ ->
      case typ of
        TypeConstructor ["Macro"] target ->
          case target of
            [] -> Err "You must specify a target for the macro. Ex: Macro (Decoder String)"
            [ tgt ] -> Ok <| Just <| Helpers.stringifyType tgt
            _ -> Err <| "A macro can only have one target, found " ++ (toString <| List.length target)
        _ -> Ok Nothing
    _ -> Ok Nothing

ast2arguments: List Expression -> List String
ast2arguments exprs =
  List.filterMap
    (\exp -> case exp of
      Variable names -> Just (Helpers.stringifyQualifiedType names)
      _ -> Nothing
    )
    exprs

ast2macro: Statement -> Result String Macro
ast2macro stmt =
  case stmt of
    FunctionDeclaration variable args exp ->
      case exp of
        Application left right -> case left of
          Application (Access (Variable ["Macros"]) ["generate"]) (String name) ->
            case right of
              List modifs ->
                let
                  resModifiers: Result String (List Modifier)
                  resModifiers =
                    List.foldl
                      (\exp acc ->
                        acc
                        |> Result.andThen (\modifiers ->
                          case ast2modifier exp of
                            Ok mod -> Ok (mod :: modifiers)
                            Err e -> Err e
                        )
                      )
                      (Ok [])
                      modifs
                in
                  case resModifiers of
                    Ok modifiers ->
                      Ok <| List.foldl
                        (\mod macro -> case mod of
                          Debug -> { macro | debug = True }
                          Param key value -> { macro | params = Dict.insert key value macro.params }
                          Override key value -> { macro | overrides = Dict.insert key value macro.overrides }
                        )
                        (Helpers.emptyMacro name variable (ast2arguments args))
                        modifiers
                    -- Failed to parse at least one modifier
                    Err e -> Err e

              -- Modifiers is not a list
              _ -> Err "The last param of generate should be a list of modifiers"
          -- Calling another function then generate
          _ -> Err "Use the 'generate' function to start rendering a macro"
        -- Totally wrong
        _ -> Err "Invalid macro syntax, should be an Application AST"
    _ -> Err "Invalid macro syntax, the root statement should be a function declaration"

ast2modifier: Expression -> Result String Modifier
ast2modifier exp =
  case exp of
    -- Debug
    Access (Variable ["Macros"]) ["debug"] -> Ok Debug
    Access (Variable ["Macros"]) names -> Err <| "Unknow Macros function: " ++ (toString names)
    Application left right ->
      case left of
        -- Param
        Application (Access (Variable ["Macros"]) ["param"]) (String key) ->
          let
            ok = Ok << (Param key)
          in case right of
            String str -> ok str
            Integer i -> ok (toString i)
            Float f -> ok (toString f)
            Variable names -> ok (String.join "." names)
            _ -> Err "Invalid param value"
        -- Override
        Application (Access (Variable ["Macros"]) ["override"]) (String key) ->
          case right of
            String str -> Ok (Override key str)
            _ -> Err "Invalid override value, must be a string"
        -- Error
        e -> Err <| "Invalid modifier syntax [" ++ (toString e) ++ "]"
    e -> Err <| "Invalid modifier syntax [" ++ (toString e) ++ "]"

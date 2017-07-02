module Macros.Helpers exposing (..)

import Dict exposing (Dict)
import Json.Encode as Encode

import Ast
import Ast.BinOp exposing (..)
import Ast.Expression exposing (..)
import Ast.Statement exposing (..)

type alias Macro =
  { name: String
  , variable: String
  , target: String
  , arguments: List String
  , debug: Bool
  , params: Dict String String
  , overrides: Dict String String
  }

emptyMacro: String -> String -> List String -> Macro
emptyMacro name variable args =
  { name = name
  , variable = variable
  , target = ""
  , arguments = args
  , debug = False
  , params = Dict.empty
  , overrides = Dict.empty
  }

encodeDict: Dict String String -> Encode.Value
encodeDict dict =
  dict
  |> Dict.map (\key value -> Encode.string value)
  |> Dict.toList
  |> Encode.object

encode: Macro -> Encode.Value
encode macro =
  Encode.object
    [ ("name", Encode.string macro.name)
    , ("variable", Encode.string macro.variable)
    , ("target", Encode.string macro.target)
    , ("arguments", Encode.list <| List.map Encode.string macro.arguments)
    , ("debug", Encode.bool macro.debug)
    , ("params", encodeDict macro.params)
    , ("overrides", encodeDict macro.overrides)
    ]

type Modifier
  = Debug
  | Param String String
  | Override String String

type Primitive
  = Str
  | Integer
  | Number
  | Boolean

type alias CtorType =
  { ctor: String
  , args: List ElmType
  }

type ElmType
  = PrimitiveType Primitive
  | RecordType String (Dict String ElmType)
  | UnionType (List CtorType)

-- ast2elmType: Statement -> Result String ElmType
-- ast2elmType stmt =
--   case stmt of
--     TypeAliasDeclaration (TypeConstructor ["Record"] []) (TypeRecord ([("field1",TypeConstructor ["String"] []),("field2",TypeConstructor ["Int"] [])]))

stringifyQualifiedType: List String -> String
stringifyQualifiedType qt =
  String.join "." qt

stringifyRecord: List (String, Type) -> String
stringifyRecord types =
  String.join ", " <| List.map (\(field, typ) -> field ++ ": " ++ (stringifyType typ)) types

stringifyType: Type -> String
stringifyType typ =
  case typ of
    TypeConstructor qt types ->
      stringifyQualifiedType qt ++ " " ++ (String.join " " <| List.map stringifyType types)
    TypeVariable name ->
      name
    TypeRecordConstructor t types ->
      "{" ++ (stringifyType t) ++ " | " ++ (stringifyRecord types) ++ "}"
    TypeRecord types ->
      "{" ++ (stringifyRecord types) ++ "}"
    TypeTuple types ->
      "(" ++ (String.join ", " <| List.map stringifyType types) ++ ")"
    TypeApplication left right ->
      (stringifyType left) ++ " -> " ++ (stringifyType right)

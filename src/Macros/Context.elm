module Macros.Context exposing (..)

import Ast.Statement exposing (..)

import Macros.Helpers as Helpers

type alias Import =
  { qualifiedName: String
  , aliasName: String
  , exposed: List String
  }

type Signature = Constant Type | Function (List Type)

type alias LocalVariable =
  { name: String
  , signature: Signature
  }

type alias Context =
  { imports: List Import
  , types: List Type
  , variables: List LocalVariable
  }

init: Context
init =
  { imports = []
  , types = []
  , variables = []
  }

addImport: (List String) -> Maybe String -> Maybe ExportSet -> Context -> Context
addImport qualifiedName mAlias mExposing ctx =
  let
    moduleName = Helpers.stringifyQualifiedType qualifiedName
    moduleAlias = Maybe.withDefault moduleName mAlias

    moduleExposing = case mExposing of
      Nothing -> []
      Just AllExport -> []
      Just (SubsetExport subs) ->
        List.filterMap
          (\sub -> case sub of
            FunctionExport name -> Just name
            TypeExport name mExposing -> Just name
            _ -> Nothing
          )
          subs
      Just (FunctionExport name) -> []
      Just (TypeExport name mExposing) -> []

    imp =
      { qualifiedName = moduleName
      , aliasName = moduleAlias
      , exposed = moduleExposing
      }
  in
    { ctx | imports = imp :: ctx.imports }

flattenSignature: Type -> List Type
flattenSignature type_ =
  case type_ of
    TypeConstructor _ _       -> [ type_ ]
    TypeVariable _            -> [ type_ ]
    TypeRecordConstructor _ _ -> [ type_ ]
    TypeRecord _              -> [ type_ ]
    TypeTuple _               -> [ type_ ]
    TypeApplication t1 t2     -> t1 :: (flattenSignature t2)

addVariable: String -> Type -> Context -> Context
addVariable name signature ctx =
  let
    variable = { name = name, signature = Constant signature }
  in case signature of
    TypeConstructor _ _       -> ctx
    TypeVariable _            -> { ctx | variables = variable :: ctx.variables }
    TypeRecordConstructor _ _ -> { ctx | variables = variable :: ctx.variables }
    TypeRecord _              -> { ctx | variables = variable :: ctx.variables }
    TypeTuple _               -> { ctx | variables = variable :: ctx.variables }
    TypeApplication _ _       ->
      let
        functionSignature = flattenSignature signature
        functionVariable = { variable | signature = Function functionSignature }
      in
        { ctx | variables = functionVariable :: ctx.variables }

-- ex: import Json.Encode as Encode
-- getQualifiedName "Encode" => "Json.Encode"
getQualifiedName: Context -> String -> Maybe String
getQualifiedName ctx name =
  ctx.imports
  |> List.filter (\imp -> imp.qualifiedName == name || imp.aliasName == name)
  |> List.head
  |> Maybe.map .qualifiedName

-- ex: import Json.Encode as Encode
-- getLocalName "Json.Encode" => "Encode"
getLocalName: Context -> String -> Maybe String
getLocalName ctx qualifiedName =
  ctx.imports
  |> List.filter (\imp -> imp.qualifiedName == qualifiedName)
  |> List.head
  |> Maybe.map .aliasName

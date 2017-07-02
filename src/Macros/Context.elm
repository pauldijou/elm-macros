module Macros.Context exposing (..)

type alias Import =
  { qualifiedName: String
  , aliasName: String
  , exposed: List String
  }

type alias Context =
  { imports: List Import
  }

init: Context
init =
  { imports = []
  }

addImport: String -> Maybe String -> Maybe ExportSet -> Context -> Context
addImport moduleName mAlias mExposing ctx =
  let
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

-- ex: import Json.Encode as Encode
-- getQualifiedName "Encode" => "Json.Encode"
getQualifiedName: String -> Maybe String
getQualifiedName name =
  ctx.imports
  |> List.filter (\imp -> imp.qualifiedName == name || imp.aliasName == name)
  |> List.head
  |> Maybe.map .qualifiedName

-- ex: import Json.Encode as Encode
-- getLocalName "Json.Encode" => "Encode"
getLocalName: Context -> String -> String
getLocalName ctx qualifiedName =
  ctx.imports
  |> List.filter (\imp -> imp.qualifiedName == qualifiedName)
  |> List.head
  |> Maybe.map .aliasName
  |> Maybe.withDefault qualifiedName

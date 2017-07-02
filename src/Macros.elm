module Macros exposing (Macro, generate, debug, param, override)

{-|

@docs Macro, generate, debug, param, override

-}

import Dict exposing (Dict)
import Macros.Helpers exposing (Macro, Modifier(..), emptyMacro)

{-| -}
type alias Macro = Macro

{-| -}
generate: String -> List Modifier -> Macro
generate name modifiers =
  emptyMacro name "" []

{-| -}
debug: Modifier
debug =
  Debug

{-| -}
param: String -> a -> Modifier
param key value =
  Param key (toString value)

{-| -}
override: String -> String -> Modifier
override =
  Override

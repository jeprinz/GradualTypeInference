module Type(
    Type(Var, Atomic, Fun, Dynamic),
    intersect,
    Type.union,
    replace,
    typeToString,
    typesToStrings,
    Substitutions,
    applySubs,
    Id(Id, Idx)
)where

import Data.Set as Set
-- import Data.BiMap as BiMap
import Data.Map as Map
import Control.Monad.State
import NameGiver

data Id = Id Int | Idx Id Id deriving (Show, Eq, Ord)
data Type = Var Id | Atomic String | Fun Type Type | Dynamic deriving (Show, Eq, Ord)

replace :: Type -> Id -> Type -> Type -- replace t v x = t[x/v]
replace (Fun t1 t2) var x = Fun (replace t1 var x) (replace t2 var x)
replace (Var v) var x = if v == var then x else Var v
replace t _ _ = t

type Substitutions = [(Id, Type)]

data Empty

--args already ordered by union
intersectI :: Type -> Type -> Maybe (Type, Substitutions)
intersectI (Var i) t = return (t, [(i, t)])
intersectI (Atomic s1) (Atomic s2) = if s1 == s2 then Just (Atomic s1, []) else Nothing
intersectI (Atomic s) anything = Nothing
intersectI (Fun t1 t2) (Fun t1' t2') =
    do (t, subs) <- intersectI t1 t1'
       let t2New = applySubs subs t2
           t2'New = applySubs subs t2'
       (t', subs') <- intersectI t2New t2'New
       return (Fun t t', subs ++ subs')
intersectI (Fun _ _) Dynamic = Nothing
intersectI Dynamic Dynamic = Just (Dynamic, [])

intersect :: Type -> Type -> Maybe (Type, Substitutions)
intersect t1 t2 = if t1 < t2 then intersectI t1 t2 else intersectI t2 t1

unionI :: Type -> Type -> (Type, Substitutions)
unionI (Var i) t = (t, [(i, t)])
unionI (Atomic s1) (Atomic s2) = if s1 == s2 then (Atomic s1, []) else (Dynamic, [])
unionI (Atomic s) anything = (Dynamic, [])
unionI (Fun t1 t2) (Fun t1' t2') =
    let (t, subs) = unionI t1 t1'
        t2New = applySubs subs t2
        t2'New = applySubs subs t2'
        (t', subs') = unionI t2New t2'New
    in  (Fun t t', subs ++ subs')
unionI (Fun _ _) Dynamic = (Dynamic, [])
unionI Dynamic Dynamic = (Dynamic, [])

union :: Type -> Type -> (Type, Substitutions)
union t1 t2 = if t1 < t1 then unionI t1 t2 else unionI t2 t1

applySubs :: Substitutions -> Type -> Type
applySubs [] t = t
applySubs ((i, v) : ss) t = replace (applySubs ss t) i v


-- everthing below here is for converting types to strings
type TypeState' = TypeState Id Char

typeToStringI :: Type -> Bool -> TypeState' String
typeToStringI (Fun t1 t2) parens = do
    s1 <- typeToStringI t1 True
    s2 <- typeToStringI t2 False
    return (if parens then ("(" ++  s1 ++ "->" ++ s2 ++ ")")
                      else (s1 ++ "->" ++ s2))


typeToStringI (Var v) _ = do name <- getName v
                             return [name]
typeToStringI Dynamic _ = return "?"

typeToString :: Type -> String
typeToString t = evalState (typeToStringI t False) (['A'..'Z'], Map.empty)

typesToStringsI :: [Type] -> TypeState' [String]
typesToStringsI (t:ts) =
    do s <- typeToStringI t False
       rest <- typesToStringsI ts
       return (s : rest)

typesToStrings :: [Type] -> [String]
typesToStrings ts = evalState (typesToStringsI ts) (['A'..'Z'], Map.empty)

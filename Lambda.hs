module Lambda(
    Exp (Var, App, Lam, LAtomic),
    LId (LId)
) where

import Data.Map as Map
import Type

data LId = LId Int deriving(Show, Eq, Ord)
data Exp = Var LId | App Exp Exp | Lam LId Exp | LAtomic Type deriving(Show)

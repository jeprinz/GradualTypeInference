module LambdaParse(
  lambdaParse,
  lambdaParseInfo
)where

import Lambda
import NameGiver

import Text.ParserCombinators.Parsec
import Text.ParserCombinators.Parsec.Expr
import Text.ParserCombinators.Parsec.Language
import qualified Text.ParserCombinators.Parsec.Token as Token

import Control.Monad.State
import Data.Map as Map
import Data.List as List

import Type

-- This is adaped from the following tutorial:
-- https://wiki.haskell.org/Parsing_a_simple_imperative_language

data MedExp = MedApp MedExp MedExp | MedLambda String MedExp | MedVar String | MedAtomic Type deriving(Show)

--The following is a list of built in constants
constants :: [(Type, String)]
constants = [(Atomic "num", "5"),
             (Atomic "num", "0"),
             (Atomic "num", "1"),
             (Atomic "bool", "true"),
             (Atomic "bool", "false"),
             (Fun (Atomic "num") (Fun (Atomic "num") (Atomic "num")), "plus"),
             (Fun (Atomic "bool") (Fun (Atomic "num") (Fun (Atomic "num") (Atomic "num"))), "if"),
             (Fun (Atomic "num") (Fun (Atomic "num") (Atomic "bool")), "equals")]

languageDef =
  emptyDef { Token.commentStart    = "/*"
           , Token.commentEnd      = "*/"
           , Token.commentLine     = "//"
           , Token.identStart      = letter
           , Token.identLetter     = alphaNum
           , Token.reservedNames   = [ "l" ] ++ snd (unzip constants)
           , Token.reservedOpNames = [ "." ] -- TODO: what is difference between reservedNames and reservedOpNames
           }

lexer = Token.makeTokenParser languageDef

identifier = Token.identifier lexer -- parses an identifier
reserved   = Token.reserved   lexer -- parses a reserved name
reservedOp = Token.reservedOp lexer -- parses an operator
parens     = Token.parens     lexer -- parses surrounding parenthesis:
                                    --   parens p
                                    -- takes care of the parenthesis and
                                    -- uses p to parse what's inside them
-- integer    = Token.integer    lexer -- parses an integer
whiteSpace = Token.whiteSpace lexer -- parses whitespace

whileParser :: Parser MedExp -- the main parser which calls all other ones I think
whileParser = whiteSpace >> expression

expression :: Parser MedExp
expression = seqOfExpression

seqOfExpression =
  do list <- (sepBy1 expression' whiteSpace)
     -- If there's only one statement return it without using Seq.
     return $ if length list == 1 then head list else foldl1 MedApp list

expression' :: Parser MedExp
expression' = (parens expression) <|> varExp <|> lamExp <|> builtinExps
-- expression :: Parser MedExp
-- expression =   parens expression
--           <|> seqOfExpression
--
-- seqOfExpression =
--   do list <- (sepBy1 expression' whiteSpace)
--      -- If there's only one statement return it without using Seq.
--      return $ if length list == 1 then head list else foldl1 App list
--
-- expression' :: Parser MedExp
-- expression' = varExp <|> lamExp

varExp :: Parser MedExp
varExp = do varName <- identifier
            return (MedVar varName)

lamExp :: Parser MedExp
lamExp = do reserved "l"
            varName <- identifier
            reservedOp "."
            e <- expression
            return (MedLambda varName e)

makeBuiltinExp :: Type -> String -> Parser MedExp
makeBuiltinExp t name = do reserved name
                           return $ MedAtomic t

builtinExps = List.foldr1 (<|>) $ List.map (\(t, s) -> makeBuiltinExp t s) constants

appExp :: Parser MedExp
appExp = do e1 <- expression
            e2 <- expression
            return (MedApp e1 e2)

parseMed :: String -> MedExp
parseMed str =
  case Text.ParserCombinators.Parsec.parse whileParser "" str of
    Left e  -> error $ show e
    Right r -> r


-- final function converts string vars to Id vars
type TypeState' = TypeState String LId

varsConvertI :: MedExp -> TypeState' Exp
varsConvertI (MedVar v) = do id <- getName v
                             return (Lambda.Var id)
varsConvertI (MedApp me1 me2) = do e1 <- varsConvertI me1
                                   e2 <- varsConvertI me2
                                   return (App e1 e2)
varsConvertI (MedLambda v me) = do id <- getName v
                                   e <- varsConvertI me
                                   return (Lam id e)
varsConvertI (MedAtomic s) = return $ LAtomic s

lambdaParse :: String -> Exp
lambdaParse str = evalState (varsConvertI (parseMed str)) (ids, Map.empty) where
  ids = [LId n | n <- [0..]]

lambdaParseInfo :: String -> (Exp, Map LId String)
lambdaParseInfo str = let ids = [LId n | n <- [0..]]
                          (e, state) = runState (varsConvertI (parseMed str)) (ids, Map.empty) where
                          varMap = snd state
                          reversed = fromList $ Prelude.map (\(a,b) -> (b,a)) (toList varMap)
                      in (e, reversed)

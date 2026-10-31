{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes

dec_rinv :: [LTp] -> LTp -> Bool
dec_rinv [] (Atm a) = False
dec_rinv listy (DivL a b) =
  dec_rinv (a : listy) b
dec_rinv listy (DivR a b) =
  dec_rinv (listy ++ [b]) a
dec_rinv listy (Atm p) =
  or [dec_lfoc (take i listy) (listy !! i) (drop (i+1) listy) p
      | i <- [0..(length listy) - 1]]


dec_lfoc :: [LTp] -> LTp -> [LTp] -> Atm -> Bool
dec_lfoc gammaL a gammaR p = undefined

isGrammatical :: Lexicon sem -> [String] -> Bool
isGrammatical lex ws = undefined


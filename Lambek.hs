{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes

dec_rinv :: [LTp] -> LTp -> Bool
dec_rinv [] _ = False
dec_rinv listy (DivL a b) =
  dec_rinv (a : listy) b
dec_rinv listy (DivR a b) =
  dec_rinv (listy ++ [b]) a
dec_rinv listy (Atm p) =
  or [dec_lfoc (take i listy) (listy !! i) (drop (i+1) listy) p
      | i <- [0..(length listy) - 1]]


splits :: [a] -> [([a], [a])]
splits xs = [ (take i xs, drop i xs) | i <- [0 .. length xs]]

dec_lfoc :: [LTp] -> LTp -> [LTp] -> Atm -> Bool
dec_lfoc gL (Atm q) gR p = if (length gL == 0) && (length gR == 0) &&  p == q
  then True
  else False
dec_lfoc gL (DivL a b) gR p =
  or [ (dec_rinv gL2 a) && (dec_lfoc gL1 b gR p) | (gL1, gL2) <- splits gL]
dec_lfoc gL (DivR b a) gR p =
  or [ (dec_rinv gR1 a) && (dec_lfoc gL b gR2 p) | (gR1, gR2) <- splits gR]

isGrammatical :: Lexicon sem -> [String] -> Bool
isGrammatical lex ws = undefined


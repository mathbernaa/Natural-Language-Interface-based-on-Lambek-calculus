{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes

dec_rinv :: [LTp] -> LTp -> Bool
dec_rinv [] (Atm a) = False
dec_rinv gamma (DivL a b) =
  dec_rinv (a : gamma) b
dec_rinv gamma (DivR a b) =
  dec_rinv (gamma ++ [b]) a
dec_rinv gamma (Atm p) =
  or [dec_lfoc (take i gamma) (gamma !! i) (drop (i+1) gamma) p | i <- [0..(length gamma) - 1]]


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
isGrammatical lex ws = any (\ts -> dec_rinv ts (stp lex)) (mapM typesOf ws)
  where
    typesOf w = [ t | (w', t, _) <- items lex, w' == w ]


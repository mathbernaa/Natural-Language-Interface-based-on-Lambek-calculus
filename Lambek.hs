{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module Lambek where

import LTypes
import LExp

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

der_rinv :: [(Var, LTp)] -> LTp -> [LExp]
der_rinv [] _ = []
der_rinv g (DivL a b) = [ L x e | e <- der_rinv ((x,a) : g) b]
  where x = fresh (map (V . fst) g)
der_rinv g (DivR b a) = [L x e | e <- der_rinv (g ++ [(x,a)]) b ]
  where x = fresh (map (V . fst) g)
der_rinv g (Atm p) = 
  [ foldl A (V x) args | i <- [0 .. length g - 1],
  let (x,t) = g !! i, 
  args <- der_lfoc (take i g) t (drop (i+1) g) p ]

der_lfoc :: [(Var, LTp)] -> LTp -> [(Var, LTp)] -> Atm -> [[LExp]]
der_lfoc gL (Atm q) gR p = if null gL && null gR && p == q then [[]] else []
der_lfoc gL (DivL a b) gR p = [e : es | (gL1, gL2) <- splits gL , e <- (der_rinv gL2 a), es <- (der_lfoc gL1 b gR p)]
der_lfoc gL (DivR b a) gR p = [e : es | (gR1, gR2) <- splits gR , e <- (der_rinv gR1 a), es <- (der_lfoc gL b gR2 p)]

derivations :: Lexicon sem -> [String] -> [LExp]
derivations lex ws = concat [der_rinv ctx (stp lex) | ctx <- combinations (zip [1..] ws)]
  where
    combinations [] = [[]]
    combinations (iw : rest) = [x:xs | x <- pick iw, xs <- combinations rest]
    pick (i,w) = [ (w ++ "_" ++ show i, t) | (w', t, _) <- items lex, w' == w]

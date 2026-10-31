module LTypes where

type Atm = String
data LTp = Atm Atm | DivL LTp LTp | DivR LTp LTp -- Atm = "np" or "s"
  deriving (Show,Eq)                             -- DivL = "A implies B"; DivR = "B implies A" -- for A _ B

data Lexicon sem = Lexicon { items :: [(String,LTp,sem)] , stp :: LTp }

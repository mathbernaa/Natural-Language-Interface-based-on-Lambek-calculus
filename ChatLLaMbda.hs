import Data.Char
import System.IO
import Control.Exception

import LTypes
import LExp
import qualified Lambek

import Parser
import PySupport

-- "standardize" the capitalization of a word by making the first
-- letter uppercase and the following letters lowercase.
-- (This will make it easier to look up words in the lexicon.)
stdize (c:cs) = toUpper c : map toLower cs


toPython :: [(Var, PythonCode)] -> LExp -> String
toPython env (V x) = case lookup x env of
  Just meaning -> "(" ++ text meaning ++ ")"
  Nothing -> pyVar x
toPython env (A e1 e2) = "(" ++ toPython env e1 ++ ")(" ++ toPython env e2 ++ ")"
toPython env (L x e) = "(lambda " ++ pyVar x ++ ": " ++ toPython (filter ((/= x) . fst) env) e ++ ")"

pyVar :: Var -> String
pyVar x = "_" ++ map(\c -> if c == '\'' then '_' else c) x

-- lexicon, but deriving questions (type q) instead of sentences 
asQuestions :: Lexicon sem -> Lexicon sem
asQuestions lex = lex { stp = Atm "q" }


evalDerivation :: PythonHandle -> (LExp, [(Var, PythonCode)]) -> IO String
evalDerivation phandle (expr, env) = runPythonCode phandle (PCode ("print(" ++ toPython env expr ++ ")"))


repl :: Lexicon PythonCode -> PythonHandle -> IO ()
repl lexicon pythonHandle = do
  -- print the prompt
  putStr "> "
  -- get a line of input
  line <- getLine

  -- split it up into "standardized" words, ignoring ponctuations
  let wordsList = map stdize (words (filter (`notElem` "?.,!") line))
  -- test if the string of words is a grammatical sentence according to the lexicon
  let goals = [stp lexicon, Atm "q"]
  let derivations = Lambek.derivationsWithSemanticValue lexicon wordsList ++ Lambek.derivationsWithSemanticValue (asQuestions lexicon) wordsList

  case derivations of
    _ | null wordsList -> return ()
    [] -> putStrLn "That is not a well-formed sentence"

    [derivation] -> do
      result <- evalDerivation pythonHandle derivation
      putStrLn result

    _ -> do
      putStrLn "That sentence is ambiguous"
      printDerivations derivations

  -- repeat
  repl lexicon pythonHandle

  where
    printDerivations [] = return ()
    printDerivations ((expression, environment):rest) = do
      result <- evalDerivation pythonHandle (expression, environment)
      putStrLn ("Sense [" ++ prettyLExp expression ++ "]: " ++ result)
      printDerivations rest

      
main = do
  -- send console output immediately to the user
  hSetBuffering stdout NoBuffering
  -- input a lexicon file
  elx <- getLex
  -- input a database of facts
  db <- getDB
  -- launch a Python interpreter
  phandle <- launchPython db
  -- start the read-eval-print loop
  putStrLn "Starting chat..."
  repl elx phandle
  where
    getDB :: IO PythonCode
    getDB = do
      putStr "Facts about the world: "
      dname <- getLine
      mdb <- try (readFile dname) :: IO (Either IOError String)
      case mdb of
        Left err -> putStrLn ("Error loading file " ++ show err) >> getDB
        Right db -> return (PCode db)
      
    getLex :: IO (Lexicon PythonCode)
    getLex = do
      putStr "Lexicon file: "
      lname <- getLine
      res <- parseFile lexicon lname
      case res of
        Left err -> putStrLn ("Error loading file " ++ show err) >> getLex
        Right (Left err) -> putStrLn ("parse error at " ++ lname ++ ":" ++ show err) >> getLex
        Right (Right lex) -> return lex

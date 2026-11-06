# Natural-Language-Interface-based-on-Lambek-calculus

## How to run

### Build

From the project folder: 

```
ghc ChatLLaMbda.hs
```

This compiles all the modules and creates the program `ChatLLaMbda`.

### Run

```
./ChatLLaMbda
```

The program first asks for two files: the lexicon and the facts about the world. For the
example world of animals, answer `animals.elx` and `aniworld.py`:

```
Lexicon file: animals.elx
Facts about the world: aniworld.py
Starting chat...
>
```

Then type a sentence or a question after the `>` prompt and press Enter. Capitalization does
not matter, and punctuation such as `?` or `.` is ignored. To stop the program, press Ctrl-C.

### What to expect

A statement is answered with `True` or `False`, according to the facts in `aniworld.py`:

```
> Conor sleeps
False
> every grey cat sleeps
True
> Seamus sleeps and Seamus is grey
True
```

A question is answered with the names of the animals, or with `yes` or `no`:

```
> Who is hungry?
Conor, Dara, Ronan
> Which dog does Seamus fear?
Dara
> Does Brian swim?
yes
> Which mouse sleeps?
nobody
```

If a sentence has more than one meaning, every reading is shown with its lambda expression
and its own answer:

```
> every cat fears a dog
That sentence is ambiguous
Sense [Every_1 Cat_2 (\a. A_4 Dog_5 (\b. Fears_3 a b))]: True
Sense [A_4 Dog_5 (\a. Every_1 Cat_2 (\b. Fears_3 b a))]: False
```

Here the first reading is "every cat fears some dog" (true), and the second is "there is one
dog that every cat fears" (false).

If the sentence is not grammatical according to the lexicon (unknown words, or words in the
wrong order), the program says so:

```
> sleeps Conor
That is not a well-formed sentence
```

The words the program knows are the ones in `animals.elx`: the animals Brian, Conor, Dara,
Fiona, Ronan, Seamus and Tara; the nouns animal, badger, cat, dog and mouse; the verbs sleeps,
swims, chases and fears; the adjectives hungry and grey; and the words every, a, someone, and,
is, who, which and does.

## Lambek.hs - descriptions of the functions


### dec_rinv

We use this function to determine whether some type is derivable from a sequence of types. 
We do so by iterating over every type in the sequence, and trying to derive the sequence using that type as the focus and claling dec_lfoc on it.
If the type we are deriving is composite, we decompose recursively it until an atomic type is reached, then, we try to derive it using dec_lfoc.


### dec_lfoc

We use this function to discover if, with a type in focus and a determined set of
arguments in a certain order to its left and right, we can reach our atomic goal:

```
ΓL [A] ΓR ⟶ p
```

Where [A] is our focus and ΓL and ΓR are the arguments to the left and right
respectively of [A]. The focus is chosen beforehand by `dec_rinv` (rule F):

```
ΓL [A] ΓR ⟶ p
──────────────── F
ΓL, A, ΓR ⟶ p
```

For this we use the following algorithm:

```
                 ΓL2 ⟶ A    ΓL1 [B] ΓR ⟶ p            ΓR1 ⟶ A    ΓL [B] ΓR2 ⟶ p
───────── X     ────────────────────────────── L      ────────────────────────────── L′
 [p] ⟶ p         ΓL1, ΓL2 [A \ B] ΓR ⟶ p               ΓL [B / A] ΓR1, ΓR2 ⟶ p
```

If the focus is an atom (rule X), there are no arguments left to use, so we succeed
only if ΓL and ΓR are both empty and the atom is our goal p. Otherwise we split either
the arguments to the left or the right of our focus, depending on whether it is a left
division A \ B (`DivL a b`) or a right division B / A (`DivR b a`), and then simplify
our list of arguments: the part of the split next to the focus is used up to produce
A, and the focus becomes B.

To split the arguments to the left and to the right of the focus, I wrote the helper
function `splits` that outputs a list with all the possible ways we can split a list
in 2, keeping the order of it. Then we test if our conditions (ΓL2 ⟶ A and
ΓL1 [B] ΓR ⟶ p) or (ΓR1 ⟶ A and ΓL [B] ΓR2 ⟶ p) are satisfied, depending if we are
executing the L or the L' rule: the first condition is checked with `dec_rinv` and the
second with a recursive call to `dec_lfoc`, so the two functions are mutually
recursive. The rule succeeds if at least one of the splits works.
### isGrammatical

For this function we have to extract all the possible combinations of word types from
the words that we have on the string list (as each word can have more than 1 type in the
lexicon), and then we test with `dec_rinv` if any of the combinations derives the
sentence type we are looking for, which is given by `stp lex` (the `SENTENCE : s.` line
of the lexicon file). The sentence is grammatical if at least one combination works.

### der_rinv

The goal of this function is to find which terms we can build, using lambda notation,
from the items in the context g (a list of (name, type) pairs), such that they have our
goal type. If the context is empty, we cannot build anything, so we return [].

If we fall on the case DivL a b, then we need to check whether (x, a) : g results in
type b, so we have to call recursion: we assume we are given an extra argument x of
type a on the left. To get a name for x we use fresh, which generates a string "a",
"b", ... that is not present in g (we use map (V . fst) g to turn the names already in
g into variables, so that fresh can avoid them). Then we output the result as a lambda
abstraction L x e, for every e in der_rinv ((x, a) : g) b. The case DivR b a is the same,
but the argument is added at the end of the list: g ++ [(x, a)].

If our goal is an atomic type, then we try every item of g as the focus: we split g
into the items to its left and to its right, and call the next function der_lfoc,
looking for the wanted type. der_lfoc returns all the possible lists of arguments for
the focus, and for each of them we apply the focused variable to its arguments with
foldl A (V x) args.

### der_lfoc

The goal of this function is, from two lists (gL and gR, the items to the left and to
the right of the focus) and a focus type, to find which arguments our focus needs,
taken from gL and gR, so that our intended atomic type p is reached. It returns a list
of all the possible argument lists ([[LExp]]), since the focus can sometimes be used in
more than one way.

Base case (rule X): if the focus is an atom, it needs no arguments, so we succeed with
[[]] (one way, with no arguments) only if gL and gR are empty and the atom is p;
otherwise we return [] (no way).

In the case DivL a b, for every split of gL into gL1 and gL2, we need that gL2 -> a and
that gL1 [b] gR -> p, so for the first case we call our function der_rinv (which gives
the argument e) and for the latter we call der_lfoc recursively (which gives the
remaining arguments es), and we output e : es. Same process for DivR b a, but splitting
gR instead of gL.

Each inner list [e1, ..., en] is one way of using the focus: it lists the
arguments the focus must be applied to, in order, to produce the atom p. For example,
with focus `Fears_2 : np\(s/np)`, gL = `[Conor_1 : np]` and gR = `[Fiona_3 : np]`, the
output is `[[Conor_1, Fiona_3]]`: one way, applying the focus first to `Conor_1` and then
to `Fiona_3`. The meaning of the whole output is:

- `[]`: the focus cannot be used to reach p (no derivation);
- `[[]]`: it reaches p directly, with no arguments (the focus is already p);
- `[[e1, ..., en]]`: there is one way, with arguments e1, ..., en;
- several inner lists: there are several ways (ambiguity).

der_lfoc does not know the name of the focus, so it only returns the arguments; der_rinv
then builds the full term `x e1 ... en` with `foldl A (V x) args`, here
`Fears_2 Conor_1 Fiona_3`.

### derivations

This function is the version of `isGrammatical` for derivations: instead of answering
True or False, it returns all the lambda terms that derive the sentence, one for each
possible reading.

First, each word is numbered by its position in the sentence with `zip [1..] ws`, and
the helper `pick` turns each numbered word into all its possible (name, type) pairs
from the lexicon, where the name is the word followed by its position (for example
`("Conor", 1)` gives `("Conor_1", np)`). The number makes the names distinct even when
the same word appears twice in a sentence.

Then the helper `combinations` builds every possible context, choosing one entry for
each word: the empty list of words has one context, the empty one ([[]]), and for a
word followed by the rest of the sentence, we combine each of its entries with every
context for the rest. This is needed because some words have more than one type
(for example `Every`, `A` or `And`).

Finally, for each context we call `der_rinv` with the sentence type `stp lex` as the
goal, and we join all the resulting lists of terms with `concat`. If the result is
empty the sentence is not grammatical; if it has more than one term the sentence is
ambiguous.


### derivationsWithSemanticValue

This function iterates over all possible derivable meanings of a sentence, generating ones that make sense grammatically, as well as their semantic meanings. 

Does everything "derivations" does, but returns the meaning, to be used later, when implementing a Python interface. 


### toPython

This funciton converts a lambda expression into a piece of executable Python code. 
 - a variable gets sent to the corresponding Python meaning from the environment, or into a Python variable name
 - an application gets sent to a Python function call
 - a lambda abstraction gets sent to a Python lambda function


 ### pyVar 

This function converts lambda calculus variable names into valid Python variables: prefixing them with an underscore, replacing apostrophes with underscores.



### repl

This function performs a Read-Eval-Print Loop (REPL), which allows users to query the system by entering sentences.

 - Input: Reads user input, removes punctuation, standardizes the words.

 - Derivation generation: Attempts to parse the input to get a statement or a question.

 - Evaluation: If only one derivation is found, evaluates its Python semantics and prints the result.

 - Ambiguity handling: If multiple derivations are found, evaluates and prints each possible interpretation alongside its lambda calculus expression.

The function recursively processes new inputs, so we can contiue interacting with the system. If no valid derivation of a sentence exists, the function displays an error message.

## Questions
Other than declarative sentences (Conor is hungry answered with True and false ) the interface also answers questions:
```
> Who is hungry?
Conor, Dara, Ronan
> Which dog does Seamus fear?
Dara
> Does Brian swim?
yes
> Which mouse sleeps?
nobody
```

### New types

We added a new atomic type 'q' for a whole question, next to 's' for a statement
For questions about the object ("Who does Tara fear") we also use the atom 'sq': "does Tara fear" is a question with its object object missing, of type `sq / np`. 
We use `sq` instead of `s` on purpose: if "does Tara fear" had type `s / np`, then "Does Tara fear Conor" would also be derivable as a statement, and every such question would come out as ambiguous.


### Additions in animals.elx

- `Who : q / (np \ s)` takes a verb phrase such as "is hungry" or "fears a dog" (type `np \ s`) and returns every animal it is true for. `Who : q / (sq / np)` does the same for the object ("Who does Tara fear?").
- `Which : (q / (np \ s)) / n` and `Which : (q / (sq / np)) / n` work like `Who`, but only keep the animals of a given noun ("Which dog chases Conor?", "Which dog does Seamus fear?").
- `Is : (q / adj) / np` asks a yes/no question about an adjective ("Is Conor hungry?").
- `Does : (q / (np \ s)) / np` asks a yes/no question about a verb ("Does Seamus sleep?"), and `Does : ((sq / np) / (np \ (s / np))) / np` builds "does Tara fear" for object questions; its meaning `lambda x : lambda v : v(x)` applies the verb to the subject and leaves the object open.
- The base forms `Sleep`, `Swim`, `Chase` and `Fear`, used after "does" ("Does Seamus sleep?"). They have the same meanings as `Sleeps`, `Swims`, `Chases` and `Fears`.
- `Swims`, which was missing from the lexicon even though `aniworld.py` has a `swim` set.

Word order still matters, as in the rest of the Lambek calculus: "sleeps Conor" is not a well-formed sentence, because `Sleeps : np \ s` needs its `np` on the left. 
To ask whether Conor sleeps, the question is "Does Conor sleep?".



### Additions in aniworld.py

The meanings of the question words use two helper functions at the end of `aniworld.py`:

- `names` joins a list of names with commas, or gives `nobody` for an empty list;
- `yes_no` turns a boolean into `yes` or `no`.

### PySupport.hs: running Python with -E

We start Python with `python3 -i -E` instead of `python3 -i`. The `-E` option makes Python ignore
environment variables such as `PYTHONSTARTUP`. In the VS Code terminal, the Python extension sets
`PYTHONSTARTUP` to a script that prints `Ctrl click to launch VS Code Native REPL` when Python
starts. Since `runPythonCode` reads exactly one line of output for each sentence, this extra line
shifted every answer by one: each sentence got the answer of the previous one.

(i used the help of claude to identify and fix this problem)
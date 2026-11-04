# Natural-Language-Interface-based-on-Lambek-calculus

## Lambek.hs - descriptions of the functions

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
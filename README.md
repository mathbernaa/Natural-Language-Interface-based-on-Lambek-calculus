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
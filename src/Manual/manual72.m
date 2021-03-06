.H 2 "An example of rule building"
In the chapter ``Rules'', we gave a sample program fragment which
used a rule function called
.B "allzero."
Verification of this piece of a program required some rules.
As a concrete example, we make a simple program out of our program fragment.
.DP

     1  program example6;
     2  {
     3          Program fragment to demonstrate rule usage
     4  }
     5  type tabix = 1..100;
     6  type tab = array [tabix] of integer;
     7  rule function allzero(a: tab; i,j: tabix): boolean; begin end;
     8  var table1: tab;
     9      i,j: tabix;
    10  begin
    11      for i := 1 to 100 do begin
    12          table1[i] := 0;
    13          assert(allzero(table1,1,i-1));
    14          state(allzero(table1,1,i));
    15          end;
    16      assert(allzero(table1,1,100));
    17      j := 25;                        { some arbitrary value }
    18      assert(table1[j] = 0);          { table1[j] must be 0 }
    19  end.

.DE
We will make an attempt at verifying the program, knowing that the attempt
will be unsuccessful, since the Verifier has no idea what
.B "allzero"
means.
.DP

    % pasver example6.pf

.DE
.P
Of course, we get diagnostic messages.
.DP

    Pass 1:
    Pass 2:
    Pass 3:

    Verifying example6
    Could not prove {example6.pf:18} table1[(j - 1) + 1] = 0
    (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} FOR loop exit

    Could not prove {example6.pf:14} allzero(table1,1,i)
    (STATE assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:15} Back to top of FOR loop

    Could not prove {example6.pf:14} allzero(table1,1,i)
    (STATE assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} Enter FOR loop

    Could not prove {example6.pf:13} allzero(table1,1,i - 1)
    (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:15} Back to top of FOR loop

    Could not prove {example6.pf:13} allzero(table1,1,i - 1)
    (ASSERT assertion)
    for path:
        {example6.pf:11} Start of "example6"
        {example6.pf:11} Enter FOR loop

    5 errors detected

.DE
We obviously need rules about
.B "allzero."
In the previous chapters, we figured out what rules we needed.
So let us build them.
.P
We begin by invoking the rule builder
.DS

    % rulebuilder

.DE
which responds with its signon message and a prompt.
.DP

    Pascal-F Rule Builder of Wed Feb 26 19:58:22 1986
    [load /u/jbn/ver/cpc6/verifier.lisp]
    Default Pascal-F knowledge base loaded.
    ->
.DE
In this session, we will define the function
.B "allzero,"
which is a predicate for testing whether an array is composed entirely of
zero elements between two subscript bounds.  The definition is a recursive
function;
.B "allzero"
is true vacuously if J is less than I, otherwise we recurse, checking each
element, until J is less than I.
.DP

    -> (defn allzero
          (a i j)
          (if (lessp j i)
              t
              (and (allzero a (add1 i) j)
                   (equal (selecta! a i) 0))))

    WARNING:  The recursion in allzero is unjustified.


    Warning:  The admissibility of allzero has not been established.
    We will assume that there exists a function satisfying this
    definition.  An induction principle for this function has also
    been assumed, corresponding to the obvious subgoal induction
    for the function.  These assumptions may render the theory
    inconsistent.

    Note that (or (falsep (allzero a i j)) (truep (allzero a i j)))
    is a theorem.

    ************** F  A  I  L  E  D **************


    [14.183333 0.4166669999999992 ]
    nil

.DE
This is no good.  We must not accept this definition or our theory might
be unsound.  Although the prover has (grudgingly) stored the definition,
we want to delete it and try again.  So we use the
.B undo-back-through
command to delete the definition of
.B allzero.
.DP

    -> (undo-back-through 'allzero)
    (defn allzero (a i j) (if (lessp j i) t (and (allzero a
    (add1 i) j) (equal (selecta! a i) 0))))

.DE
Actually, there is nothing wrong with our definition of
.B allzero.
It is just that the theorem prover isn't smart enough to
figure out that the recursion terminates.  There are two ways to deal with
this problem; one is to rewrite the definition so that the theorem prover
can figure this out by itself, and the other is to provide a hint.  The
first approach could be applied by rewriting
.B allzero
so that it recursed by subtracting 1 from
.I j
on each iteration rather than adding 1 to
.I i.
The theorem prover has no trouble understanding that subtracting 1
repeatedly with a test for
.B lessp
in the right place must lead to termination.
.P
But for purposes of illustration we're going to bull our way through with
a hint.  As mentioned in the Command Summary section for
.B defn,
a hint for a
.B defn
is a lot like the Pascal-F
.B MEASURE
statement.  We need an expression which gets smaller with each recursion.
The expression
.I "(difference (add1 j) i)"
will do the job.  We need the
.B add1
because
.B difference
returns a natural number; a negative value is not possible.  We thus must
bias the value of
.I j
to avoid trouble for the case where
.I j
is one less than
.I i.
.P
Our hint will have the form
.DP

    (lessp (difference (add1 j) i))

.DE
indicating that we want
.I "(difference (add1 j) i)"
used as the recursion measure and
.B lessp,
as usual,
used as the well-founded relation.
.DP

    -> (defn allzero
          (a i j)
          (if (lessp j i) t
              (and (allzero a (add1 i) j)
                   (equal (selecta! a i) 0)))
          ((lessp (difference (add1 j) i))))

         Linear arithmetic establishes that the measure (difference
    (add1 j) i) decreases according to the well-founded relation
    lessp in each recursive call.  Hence, allzero is accepted under
    the principle of definition.  Observe that:
          (or (falsep (allzero a i j))
              (truep (allzero a i j)))
    is a theorem.

    [ 3.2 0.25 ]
    allzero

.DE
It succeeds; the definition is valid.  It has now been proven that the
recursive definition cannot loop infinitely.
The theorem prover also
notes that
.B "allzero"
is Boolean-valued, which it may find useful later.
.P
We ask the Rule Builder to print the definition of
.B "allzero"
to illustrate the ppe command.
.DP

    -> (ppe 'allzero)

.DE
and the definition is printed in suitably indented form, with the
hint included.
.DP

    (defn allzero
          (a i j)
          (if (lessp j i)
              t
              (and (allzero a (add1 i) j)
                   (equal (selecta! a i) 0)))
          ((lessp (difference (add1 j) i))))
    nil

.DE
Incidentally,
we could have defined
.B "allzero"
so that it recursed downward, and the prover would still be able to prove
every lemma proved in this session.  In many ways, this would have been
an easier approach; we would not have needed the hint in the
.B defn
command that defined
.B allzero.
.P
Let us now test out our new definition.
We have defined a function and can now run it on some test data.
The r command is used to run
.B "allzero"
on an array in which element 2 is 0 and element 3 is 0.
(Remember that
.B "(storea! A I V)"
is equal to the array
.B "A"
except that
element
.B "I"
has been replaced by the value
.B "V\c"
)
The form
.B "(empty.array)"
is simply the array of no elements.
.DP

    -> (r (allzero (storea! (storea! (empty.array) 2 0) 3 0) 2 3))

.DE
The system responds with
.DP

    t

.DE
which is what we want.
Let us try an array which is not all zero.
.DP

    -> (r (allzero (storea! (storea! (empty.array) 2 1) 3 1) 2 3))

.DE
.DP

    f

.DE
Another test case; an array with one zero element; is it all zero
from 2 to 2?
.DP

    -> (r (allzero (storea! (storea! (empty.array) 2 0) 3 1) 2 2))

.DE
.DP

    t

.DE
It is.  Finally, we check out the case where the upper bound of the
.B "allzero"
is less than the lower bound.
.DP

    -> (r (allzero (storea! (storea! (empty.array) 2 1) 3 1) 3 2))

.DE
.DP

    t

.DE
This, also, seems to work.
.P
With our definition in good shape, we can now try to prove some
theorems about it.  Our first lemma will be that if the lower bound
exceeds the upper bound in the
.B "allzero"
call, then
.B "allzero"
is vacuously true.
.DP

    -> (prove-lemma allzero-void-rule
                 (rewrite)
                 (implies (and (arrayp! a)
                               (numberp i)
                               (numberp j)
                               (lessp j i))
                          (allzero a i j)))

.DE
Note that the name of the lemma,
.B "allzero-void-rule,"
ends in
.B "-rule"
which will later make this rule available to the Verifier.
The theorem prover now proceeds with the proof, which, given the
definition, ought to be trivial.
.DP
    This conjecture simplifies, opening up allzero, to:

          t.

    Q.E.D.

    [ 7.683333000000001 0.06666699999999916 ]
    allzero-void-rule

.DE
It is trivial; the proof succeeds in 7.6 seconds (this is on a Sun II)
and the event
.B "allzero-void-rule"
is stored.
.P
We also need a rule to handle the case where both bounds of
.B "allzero"
are equal.  This, too, should be trivial.
We type in our lemma
.DP

    -> (prove-lemma allzero-single-rule
                 (rewrite)
                 (implies (and (arrayp! a)
                               (numberp i)
                               (numberp j)
                               (equal i j))
                          (allzero a i j)))

.DE
and the theorem prover goes to work.
.DP

    This formula simplifies, using linear arithmetic, rewriting
    with allzero-void-rule and x-not-less-than-x, and expanding
    allzero, to:

          (implies (and (arrayp! a) (numberp j))
                   (equal (selecta! a j) 0)),

    which we will name *1.


         We will appeal to induction.  The recursive terms in the
    conjecture suggest two inductions.  However, they merge into
    one likely candidate induction.  We will induct according to
    the following scheme:
          (and (implies (and (array-recognizer a)
                             (equal a (empty-array)))
                        (p a j))
               (implies (and (array-recognizer a)
                             (not (equal a (empty-array)))
                             (or (not (numberp
                                        (array-elt-subscript a)))
                                 (equal (array-elt-value a)
                                        (undefined))))
                        (p a j))
               (implies (and (array-recognizer a)
                             (not (equal a (empty-array)))
                             (not (or (not (numberp
                                       (array-elt-subscript a)))
                                      (equal (array-elt-value a)
                                             (undefined))))
                             (equal (array-prev a) (empty-array)))
                        (p a j))
               (implies (and (array-recognizer a)
                             (not (equal a (empty-array)))
                             (not (or (not (numberp
                                       (array-elt-subscript a)))
                                      (equal (array-elt-value a)
                                             (undefined))))
                             (not (equal (array-prev a)
                                         (empty-array)))
                             (p (array-prev a) j))
                        (p a j))
               (implies (not (array-recognizer a))
                        (p a j))).
    Linear arithmetic and the lemma array-prev-lessp can be used
    to show that the measure (count a) decreases according to
    the well-founded relation lessp in each induction step of the
    scheme.  The above induction scheme generates six new goals:

    Case 6. (implies (and (array-recognizer a)
                          (equal a (empty-array))
                          (arrayp! a)
                          (numberp j))
                     (equal (selecta! a j) 0)),

      which simplifies, unfolding array-recognizer, arrayp!,
      equal, array-prev, array-elt-value, array-elt-subscript,
      and selecta!, to the formula:

            (not (numberp j)).

      Eliminate the irrelevant term.  This produces:

          f.

    Need we go on?

    ************** F  A  I  L  E  D **************

.DE
The theorem prover stops, after about a minute of work, and reports
failure.
What went wrong?  We can display the failed theorems in this session by
typing
.DP

    -> (pp failed-thms)

.DE
to which the theorem prover replies
.DP

    (setq failed-thms
          '((implies (and (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (equal i j))
                     (allzero a i j))
            (defn allzero
                  (a i j)
                  (if (lessp j i)
                      t
                      (and (allzero a (add1 i) j)
                           (equal (selecta! a i) 0)))
                  nil)))
t

.DE
We get to see our previous failure with the definition of
.B allzero
as well as our latest problem.
The problem is obvious; we aren't testing anything for zero in the
hypotheses of the theorem, so we can't possibly expect it to prove
.I allzero
true in the conclusion.  We are missing a hypothesis.  Let us try
again.
.DP

    -> (prove-lemma allzero-single-rule
                 (rewrite)
                 (implies (and (arrayp! a)
                               (numberp i)
                               (numberp j)
                               (equal i j)
                               (equal (selecta! a i) 0))
                          (allzero a i j)))

.DE
We have added the hypothesis
.I "(equal! (selecta! a i) 0)"
and the theorem prover is now able to prove this quite easily.
.DP

    This conjecture simplifies, using linear arithmetic, rewriting
    with allzero-void-rule and x-not-less-than-x, and unfolding the
    functions equal and allzero, to:

          t.

    Q.E.D.


    [ 3.2 0.1333330000000008 ]
    allzero-single-rule

.DE
Much better.  Again, a trivial proof.
.P
Now we get to a hard but crucial lemma.  When a program is iterating
through an array, clearing each element to zero, we will need to be
able to show that clearing each additional element extends the
.B "allzero"
property of the array.  This will require an inductive proof.
.DP

    -> (prove-lemma allzero-extend-upward-rule
                 (rewrite)
                 (implies (and (arrayp! a)
                               (numberp i)
                               (numberp j)
                               (allzero a i j)
                               (equal (selecta! a (add1 j)) 0))
                          (allzero a i (add1 j))))

.DE
Turning the problem over to the theorem prover...
.DP

         Call the conjecture *1.


         Let us appeal to the induction principle.  The recursive
    terms in the conjecture suggest four inductions.  They merge
    into two likely candidate inductions.  However, only one is
    unflawed.  We will induct according to the following scheme:
          (and (implies (lessp j i) (p a i j))
               (implies (and (leq i j) (p a (add1 i) j))
                        (p a i j))).
    Linear arithmetic informs us that the measure
    (difference (add1 j) i) decreases according to the well-founded
    relation lessp in each induction step of the scheme.  The above
    induction scheme generates three new formulas:

    Case 3. (implies (and (lessp j i)
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (allzero a i j)
                          (equal (selecta! a (add1 j)) 0))
                     (allzero a i (add1 j))),

      which simplifies, appealing to the lemmas allzero-void-rule
      and sub1-add1, and unfolding allzero and lessp, to four new
      formulas:

      Case 3.4.
              (implies (and (lessp j i)
                            (arrayp! a)
                            (numberp i)
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (leq (sub1 i) j))
                       (allzero a (add1 i) (add1 j))),

        which again simplifies, using linear arithmetic, to:

              (implies (and (lessp j (plus 1 j))
                            (arrayp! a)
                            (numberp (plus 1 j))
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (leq (sub1 (plus 1 j)) j))
                       (allzero a
                                (add1 (plus 1 j))
                                (add1 j))).

        But this again simplifies, using linear arithmetic,
        rewriting with plus-1, sub1-add1, allzero-void-rule,
        and x-not-less-than-x, and unfolding the definitions of
        lessp, plus, numberp, add1, and sub1, to:

              t.

      Case 3.3.
              (implies (and (lessp j i)
                            (arrayp! a)
                            (numberp i)
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (leq (sub1 i) j))
                       (equal (selecta! a i) 0)).

        This again simplifies, using linear arithmetic, to:

              (implies (and (lessp j (plus 1 j))
                            (arrayp! a)
                            (numberp (plus 1 j))
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (leq (sub1 (plus 1 j)) j))
                       (equal (selecta! a (plus 1 j)) 0)).

        But this again simplifies, applying the lemmas plus-1,
        sub1-add1, and x-not-less-than-x, and unfolding the
        functions lessp, plus, numberp, add1, sub1, and equal, to:

              t.

      Case 3.2.
              (implies (and (lessp j i)
                            (arrayp! a)
                            (numberp i)
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (equal i 0))
                       (allzero a (add1 i) (add1 j))),

        which again simplifies, using linear arithmetic, to:

              t.

      Case 3.1.
              (implies (and (lessp j i)
                            (arrayp! a)
                            (numberp i)
                            (numberp j)
                            (equal (selecta! a (add1 j)) 0)
                            (equal i 0))
                       (equal (selecta! a i) 0)),

        which again simplifies, using linear arithmetic, to:

              t.

    Case 2. (implies (and (leq i j)
                          (not (allzero a (add1 i) j))
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (allzero a i j)
                          (equal (selecta! a (add1 j)) 0))
                     (allzero a i (add1 j))),

      which simplifies, opening up allzero, to:

            t.

    Case 1. (implies (and (leq i j)
                          (allzero a (add1 i) (add1 j))
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (allzero a i j)
                          (equal (selecta! a (add1 j)) 0))
                     (allzero a i (add1 j))),

      which simplifies, applying sub1-add1, and opening up the
      definitions of allzero, lessp, and equal, to:

            t.


         That finishes the proof of *1.  Q.E.D.


    [ 29.84999999999998 1.966667000000014 ]

.DE
In 30 seconds, an inductive proof, produced without manual intervention.
This is Boyer and Moore's great accomplishment.
It took them seven years to write the program that does this.
Note that our earlier lemma
.B "allzero-void-rule"
was used in the proof; we are teaching the prover more and more facts
about
.B "allzero."
.P
Now a seemingly simple but non-trivial property; storing into the
array outside the bounds of
.B "allzero"
does not affect the
.B "allzero"
property.
.DP

    -> (prove-lemma allzero-unchanged-1-rule
                 (rewrite)
                 (implies (and (numberp i)
                               (numberp j)
                               (arrayp! a)
                               (allzero a i j)
                               (numberp x)
                               (or (lessp x i) (lessp j x)))
                          (allzero (storea! a x v) i j)))

.DE
The prover takes over...
.DP

    This conjecture simplifies, opening up the function or, to
    two new goals:

    Case 2. (implies (and (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp x i))
                     (allzero (storea! a x v) i j)),

      which we will name *1.

    Case 1. (implies (and (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp j x))
                     (allzero (storea! a x v) i j)),

      which we would usually push and work on later by induction.
      But if we must use induction to prove the input conjecture,
      we prefer to induct on the original formulation of the
      problem.  Thus we will disregard all that we have previously
      done, give the name *1 to the original input, and work on it.


         So now let us consider:

    (and (implies (and (numberp i)
                       (numberp j)
                       (arrayp! a)
                       (allzero a i j)
                       (numberp x)
                       (lessp j x))
                  (allzero (storea! a x v) i j))
         (implies (and (numberp i)
                       (numberp j)
                       (arrayp! a)
                       (allzero a i j)
                       (numberp x)
                       (lessp x i))
                  (allzero (storea! a x v) i j))),

    which we named *1 above.  We will appeal to induction.  The
    recursive terms in the conjecture suggest 12 inductions.
    They merge into three likely candidate inductions.  However,
    only one is unflawed.  We will induct according to the following
    scheme:
          (and (implies (lessp j i) (p a x v i j))
               (implies (and (leq i j) (p a x v (add1 i) j))
                        (p a x v i j))).
    Linear arithmetic informs us that the measure (difference
    (add1 j) i) decreases according to the well-founded relation
    lessp in each induction step of the scheme.  The above induction
    scheme produces the following seven new goals:

    Case 7. (implies (and (lessp j i)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp j x))
                     (allzero (storea! a x v) i j)).

      This simplifies, applying the lemmas allzero-void-rule and
      store-is-proper, to:

            t.

    Case 6. (implies (and (leq i j)
                          (not (allzero a (add1 i) j))
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp j x))
                     (allzero (storea! a x v) i j)).

      This simplifies, unfolding the definition of allzero, to:

            t.

    Case 5. (implies (and (leq i j)
                          (allzero (storea! a x v) (add1 i) j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp j x))
                     (allzero (storea! a x v) i j)).

      This simplifies, rewriting with select-of-store, and unfolding
      the function allzero, to:

            (implies (and (leq i j)
                          (allzero (storea! a x v) (add1 i) j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a (add1 i) j)
                          (equal (selecta! a i) 0)
                          (numberp x)
                          (lessp j x)
                          (equal x i))
                     (equal v 0)).

      This again simplifies, trivially, to:

            t.

    Case 4. (implies (and (lessp j i)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp x i))
                     (allzero (storea! a x v) i j)).

      This simplifies, applying allzero-void-rule and
      store-is-proper, to:

            t.

    Case 3. (implies (and (leq i j)
                          (leq x j)
                          (leq (add1 i) x)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp x i))
                     (allzero (storea! a x v) i j)),

      which simplifies, using linear arithmetic, to:

            t.

    Case 2. (implies (and (leq i j)
                          (not (allzero a (add1 i) j))
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp x i))
                     (allzero (storea! a x v) i j)),

      which simplifies, unfolding the definition of allzero, to:

            t.

    Case 1. (implies (and (leq i j)
                          (allzero (storea! a x v) (add1 i) j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a i j)
                          (numberp x)
                          (lessp x i))
                     (allzero (storea! a x v) i j)),

      which simplifies, rewriting with the lemma select-of-store,
      and opening up the function allzero, to:

            (implies (and (leq i j)
                          (allzero (storea! a x v) (add1 i) j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (allzero a (add1 i) j)
                          (equal (selecta! a i) 0)
                          (numberp x)
                          (lessp x i)
                          (equal x i))
                     (equal v 0)).

      However this again simplifies, using linear arithmetic, to:

            t.


         That finishes the proof of *1.  Q.E.D.


    [ 79.36666600000002 2.65000099999999 ]
    allzero-unchanged-1-rule

.DE
An unexpectedly difficult proof; the prover went down a blind alley, backed
up, started over, began induction, performed a case analysis, and found
a proof.
.P
For our next rule, we prove that storing zero into an array does not
cause the
.B "allzero"
predicate to become false.
.DP

    -> (prove-lemma allzero-unchanged-2-rule
                 (rewrite)
                 (implies (and (allzero a i j)
                               (arrayp! a)
                               (numberp i)
                               (numberp j)
                               (numberp x))
                          (allzero (storea! a x 0) i j)))

.DE
The prover replies:
.DP

         Call the conjecture *1.

         We will appeal to induction.  Four inductions are suggested
    by terms in the conjecture.  They merge into two likely candidate
    inductions.  However, only one is unflawed.  We will induct
    according to the following scheme:
          (and (implies (lessp j i) (p a x i j))
               (implies (and (leq i j) (p a x (add1 i) j))
                        (p a x i j))).
    Linear arithmetic informs us that the measure
    (difference (add1 j) i) decreases according to the well-founded
    relation lessp in each induction step of the scheme.  The above
    induction scheme produces the following three new goals:

    Case 3. (implies (and (lessp j i)
                          (allzero a i j)
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (numberp x))
                     (allzero (storea! a x 0) i j)).

      This simplifies, rewriting with allzero-void-rule and
      store-is-proper, to:

            t.

    Case 2. (implies (and (leq i j)
                          (not (allzero a (add1 i) j))
                          (allzero a i j)
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (numberp x))
                     (allzero (storea! a x 0) i j)),

      which simplifies, opening up allzero, to:

            t.

    Case 1. (implies (and (leq i j)
                          (allzero (storea! a x 0) (add1 i) j)
                          (allzero a i j)
                          (arrayp! a)
                          (numberp i)
                          (numberp j)
                          (numberp x))
                     (allzero (storea! a x 0) i j)),

      which simplifies, applying select-of-store, and opening up
      the functions allzero and equal, to:

            t.


         That finishes the proof of *1.  Q.E.D.


    [ 20.23333099999997 1.10000200000001 ]
    allzero-unchanged-2-rule

.DE
That one wasn't too hard.
.P
Finally, the rule that lets us get some payoff from using
.B "allzero"
in a program verification; we show that if
.B "allzero"
is true for A from I to J, then for any element X between I and J,
then A[X] = 0.
.DP

    -> (prove-lemma allzero-select-rule
                 (rewrite)
                 (implies (and (allzero a i j)
                               (numberp i)
                               (numberp j)
                               (arrayp! a)
                               (numberp x)
                               (leq x j)
                               (leq i x))
                          (equal (selecta! a x) 0)))

.DE
Over to the prover.
.DP

    WARNING:  Note that allzero-select-rule contains the free
    variables j and i which will be chosen by instantiating
    the hypothesis (allzero a i j).

.DE
Here the prover grumbles at us; our rule is not well chosen according to
its built-in ideas as to what an efficient rewrite lemma is.  Rules of
this type may slow down the prover in later proofs.
In this case, though,
there is no better way to state this rule.
The theorem prover proceeds; this was only a WARNING.
There is no risk to soundness here.
.DP

         Name the conjecture *1.


         Let us appeal to the induction principle.  There are seven
         plausible inductions.  They merge into three likely candidate
         inductions.  However, only one is unflawed.  We will induct
         according to the following scheme:
          (and (implies (lessp j i) (p a x i j))
               (implies (and (leq i j) (p a x (add1 i) j))
                        (p a x i j))).
    Linear arithmetic establishes that the measure
    (difference (add1 j) i) decreases according to the well-founded
    relation lessp in each induction step of the scheme.  The above
    induction scheme generates three new formulas:

    Case 3. (implies (and (lessp j i)
                          (allzero a i j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (numberp x)
                          (leq x j)
                          (leq i x))
                     (equal (selecta! a x) 0)),

      which simplifies, using linear arithmetic, to:

            t.

    Case 2. (implies (and (leq i j)
                          (not (allzero a (add1 i) j))
                          (allzero a i j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (numberp x)
                          (leq x j)
                          (leq i x))
                     (equal (selecta! a x) 0)),

      which simplifies, unfolding allzero, to:

            t.

    Case 1. (implies (and (leq i j)
                          (lessp x (add1 i))
                          (allzero a i j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (numberp x)
                          (leq x j)
                          (leq i x))
                     (equal (selecta! a x) 0)),

      which simplifies, using linear arithmetic, to:

            (implies (and (leq i j)
                          (lessp i (add1 i))
                          (allzero a i j)
                          (numberp i)
                          (numberp j)
                          (arrayp! a)
                          (numberp i)
                          (leq i j)
                          (leq i i))
                     (equal (selecta! a i) 0)).

      But this again simplifies, applying sub1-add1, and opening
      up lessp, numberp, equal, and allzero, to:

            (implies (and (equal i 0)
                          (allzero a 0 j)
                          (numberp j)
                          (arrayp! a))
                     (equal (selecta! a 0) 0)),

      which again simplifies, opening up the definitions of
      add1, lessp, equal, and allzero, to:

            t.


         That finishes the proof of *1.  Q.E.D.


    [ 15.0 1.266665999999987 ]
    allzero-select-rule

.DE
Success.  We now have a set of rules which will allow us to use
.B "allzero"
in a verification and to use it in most of the reasonable ways to use
such a predicate.  Note that this approach will work for any
predicate based on properties of individual array elements.
.B "Allzero"
is a simple example.
.P
We are done proving;
it is time to make a library file for use with the
Verifier (or for later use with
.B note-lib
in case we need some more lemmas
for our verification).
.DP

    -> (make-lib 'allzero)
    (%$unopenedport %$unopenedport)

.DE
.P
The files
.I "allzero.lib"
and
.I "allzero.lisp"
have now been created in the current directory.
Together these constitute our new knowledge base.
We are now ready to leave the Rule Builder.
.DP

    -> (exit)

.DE
This returns us to the UNIX shell.
At this point, we can put our new rules in the
working directory created by the Verifier for the program
.B "example6.pf"
by using the
.B "putrules"
utility program, which extracts all the needed information from a
Rule Builder database and puts it into a much more compact file which
the Verifier can use.
.DP

    % putrules allzero.lib example6_d

.DE
Putrules runs and prints some messages.  This is just a format translation;
nothing profound is going on here.
.DP

    Processing database allzero.lib
    Installing new database in example6_d

.DE
We can now rerun our verification.
.DP

    % pasver example6.pf

.DE
and the verifier prints
.DP

    Pass 1:
    Pass 2:
    Pass 3:

    Verifying example6
    No errors detected

.DE
so our verification is a success.

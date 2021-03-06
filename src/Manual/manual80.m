.H 1 "The formal theory of the Rule Builder"
The theory built into the Rule Builder is the Boyer-Moore theory of 
the natural numbers, plus the definitions and lemmas given in this
chapter.  The notation is that of
.B "A Computational Logic."
Note that everything here has been proven by the Boyer-Moore prover.
.H 2 "The theory"
We begin by defining the notion of Boolean value.
.DS
     Definition.
     (booleanp! X)
        =
     (or (equal X (true))
         (equal X (false)))
.DE
The next step is to add
a large batch of carefully chosen facts about the
natural numbers.
.DS 
     Theorem.  equal-lessp:
     (equal (equal (lessp X Y) Z)
            (if (lessp X Y)
                (equal t Z)
                (equal f Z)))
.DE
.DS 
     Theorem.  associativity-of-plus:
     (equal (plus (plus X Y) Z)
            (plus X (plus Y Z)))
.DE
.DS 
     Theorem.  equal-times-0:
     (equal (equal (times X Y) 0)
            (or (zerop X) (zerop Y)))
.DE
.DS 
     Theorem.  commutativity2-of-plus:
     (equal (plus X (plus Y Z))
            (plus Y (plus X Z)))
.DE
.DS 
     Theorem.  commutativity-of-times:
     (equal (times X Y) (times Y X))
.DE
.DS 
     Theorem.  distributivity-of-times-over-plus:
     (equal (times X (plus Y Z))
            (plus (times X Y) (times X Z)))
.DE
.DS 
     Theorem.  plus-0:
     (equal (plus X 0) (fix X))
.DE
.DS
     Theorem.  plus-1:
     (implies (numberp X)
              (equal (plus 1 X) (add1 X)))
.DE
.DS
     Theorem.  x-not-less-than-x:
     (equal (lessp X X) f)
.DE
.DS 
     Theorem.  times-0:
     (equal (times X 0) 0)
.DE
.DS 
     Theorem.  plus-non-numberp:
     (implies (not (numberp Y))
              (equal (plus X Y) (fix X)))
.DE
.DS 
     Theorem.  times-non-numberp:
     (implies (not (numberp Y))
              (equal (times X Y) 0))
.DE
.DS 
     Theorem.  associativity-of-times:
     (equal (times (times X Y) Z)
            (times X (times Y Z)))
.DE
.DS 
     Theorem.  commutativity2-of-times:
     (equal (times X (times Y Z))
            (times Y (times X Z)))
.DE
.DS 
     Theorem.  plus-add1:
     (equal (plus X (add1 Y))
            (if (numberp Y)
                (add1 (plus X Y))
                (add1 X)))
.DE
.DS 
     Theorem.  times-add1:
     (equal (times X (add1 Y))
            (if (numberp Y)
                (plus X (times X Y))
                (fix X)))
.DE
.DS 
     Theorem.  commutativity-of-plus:
     (equal (plus X Y) (plus Y X))
.DE
.DS 
     Theorem.  plus-equal-0:
     (equal (equal (plus A B) 0)
            (and (zerop A) (zerop B)))
.DE
.DS 
     Theorem.  plus-cancellation:
     (equal (equal (plus A B) (plus A C))
            (equal (fix B) (fix C)))
.DE
.DS 
     Theorem.  plus-right-id2:
     (implies (not (numberp Y))
              (equal (plus X Y) (fix X)))
.DE
.DS 
     Theorem.  monotonicity-of-plus-1:
     (implies (and (numberp A)
                   (numberp B)
                   (numberp C))
              (equal (lessp (plus A B) (plus A C))
                     (lessp B C)))
.DE
.DS 
     Theorem.  difference-x-x:
     (equal (difference X X) 0)
.DE
.DS 
     Theorem.  difference-plus-1:
     (equal (difference (plus X Y) X)
            (fix Y))
.DE
.DS 
     Theorem.  difference-plus-2:
     (equal (difference (plus Y X) X)
            (fix Y))
.DE
.DS 
     Theorem.  equal-difference-0:
     (equal (equal 0 (difference X Y))
            (not (lessp Y X)))
.DE
.DS 
     Theorem.  zero-difference:
     (implies (lessp A B)
              (equal (difference A B) 0))
.DE
.DS 
     Theorem.  plus-difference3:
     (equal (difference (plus X Y) (plus X Z))
            (difference Y Z))
.DE
.DS 
     Theorem.  monotonicity-of-difference-1:
     (implies (and (numberp V)
                   (numberp Y)
                   (numberp Z)
                   (not (lessp Z V))
                   (not (lessp Y V)))
              (equal (lessp (difference Y V)
                            (difference Z V))
                     (lessp Y Z)))
.DE
.DS 
     Theorem.  monotonicity-of-difference-2:
     (implies (and (numberp V)
                   (numberp Y)
                   (numberp Z)
                   (lessp Z V)
                   (lessp Y V))
              (equal (lessp (difference V Z)
                            (difference V Y))
                     (lessp Y Z)))
.DE
.DS 
     Theorem.  monotonicity-of-difference-3:
     (implies (and (numberp W)
                   (numberp V)
                   (numberp X)
                   (not (lessp X W))
                   (not (lessp X V)))
              (equal (lessp (difference X V)
                            (difference X W))
                     (lessp W V)))
.DE
.DS 
     Theorem.  times-zero:
     (equal (times X 0) 0)
.DE
.DS 
     Theorem.  distributivity-of-times-over-difference:
     (equal (times X (difference Y Z))
            (difference (times X Y) (times X Z)))
.DE
.DS 
     Theorem.  monotonicity-of-times-1:
     (implies (and (numberp X)
                   (numberp Y)
                   (numberp Z)
                   (not (zerop X)))
              (equal (not (lessp (times X Y) (times X Z)))
                     (not (lessp Y Z))))
.DE
.DS 
     Theorem.  monotonicity-of-times-3:
     (implies (and (numberp A)
                   (numberp B)
                   (numberp C)
                   (not (equal C 0)))
              (equal (lessp (times C A) (times C B))
                     (lessp A B)))
.DE
.DS 
     Theorem.  monotonicity-of-times-by-twos:
     (implies (and (lessp X Y) (lessp Z W))
              (lessp (times X Z) (times Y W)))
.DE
.DS 
     Theorem.  remainder-x-x:
     (equal (remainder X X) 0)
.DE
.DS 
     Theorem.  remainder-quotient:
     (equal (plus (remainder X Y)
                  (times Y (quotient X Y)))
            (fix X))
.DE
.DS 
     Theorem.  remainder-quotient-elim:
     (implies (and (not (zerop Y)) (numberp X))
              (equal (plus (remainder X Y)
                           (times Y (quotient X Y)))
                     X))
.DE
.DS 
     Theorem.  remainder-non-numeric:
     (implies (not (numberp X))
              (equal (remainder Y X) (fix Y)))
.DE
.DS 
     Theorem.  remainder-wrt-1:
     (equal (remainder Y 1) 0)
.DE
.DS 
     Theorem.  quotient-times:
     (equal (quotient (times Y X) Y)
            (if (zerop Y) 0 (fix X)))
.DE
.DS 
     Theorem.  monotonicity-of-times:
     (implies (and (numberp X)
                   (numberp Y)
                   (numberp Z)
                   (not (lessp Y Z)))
              (equal (lessp (times X Y) (times X Z))
                     f))
.DE
We now add an object called undefined which will be needed
in the definition of arrays.
This has nothing to do with the Verifier's proofs of definedness;
it is just a default object introduced to make 
.B "selecta!"
a total function.
.DS 
      Shell Definition.
     Add the shell undefined-object of zero arguments with
     bottom object undefined,
     recognizer undefinedp,
     accessors,
     and default values.
.DE
The definition of arrays is constructive.  An array is actually
represented as an ordered list of subscript-value pairs.
.DS 
       Shell Definition.
     Add the shell array-shell of three arguments with
     bottom object empty-array,
     recognizer array-recognizer,
     accessors array-elt-value, array-elt-subscript, and array-prev,
     type restrictions (none-of), (one-of numberp), and:
           (one-of array-recognizer)
     and default values undefined, zero, and empty.array.
.DE
The predicate 
.B "arrayp!"
is true only if an array is a valid ordered list of pairs, properly
ordered in increasing order of subscript.
Note that something is an array only if the subscripts in the list
are in ascending order and no value part is UNDEFINED.  
.DS 
     Definition.
     (arrayp! A)
        =
     (if
        (array-recognizer A)
        (if (equal A (empty-array))
            t
            (if (or (not (numberp (array-elt-subscript A)))
                    (equal (array-elt-value A)
                           (undefined)))
                f
                (if (equal (array-prev A) (empty-array))
                    t
                    (and (lessp (array-elt-subscript (array-prev A))
                                (array-elt-subscript A))
                         (arrayp! (array-prev A))))))
        f)
.DE
.B "selecta!"
is the array subscripting function, which searches the list of pairs.
.DS 
     Definition.
     (selecta! A I)
        =
     (if (equal (array-elt-subscript A) I)
         (array-elt-value A)
         (if (equal (array-prev A) (empty-array))
             (undefined)
             (selecta! (array-prev A) I)))
.DE
.B storea!
is quite complex, since it is actually a routine for inserting into an
ordered list.  Our check on the validity of this is that we are able to
prove all the standard theorems about
.B selecta!
and 
.B storea!,
which are axioms in the Oppen system.
.DS 
     Definition.
     (storea! A I V)
        =
     (if (and (arrayp! A) (numberp I))
         (if (equal A (empty-array))
             (if (equal V (undefined))
                 A
                 (array-shell V I (empty-array)))
             (if (equal (array-elt-subscript A) I)
                 (if (equal V (undefined))
                     (array-prev A)
                     (array-shell V I (array-prev A)))
                 (if (lessp (array-elt-subscript A) I)
                     (if (equal V (undefined))
                         A
                         (array-shell V I A))
                     (array-shell (array-elt-value A)
                                  (array-elt-subscript A)
                                  (storea! (array-prev A) I V)))))
         (empty-array))
.DE
The result of
.B storea!
is shown to be a valid array.
.DS 
     Theorem.  store-is-proper:
     (equal (arrayp! (storea! A I V)) t)
.DE
We prove the classic lemmas about
.B "selecta!"
and
.B "storea!\c"
.
This not only shows the validity of our definition of
.B "storea!\c"
, but
gives the Rule Builder a set of rules which comprise a decision procedure
for our array theory.
.DS 
     Theorem.  select-of-store-1:
     (implies (and (arrayp! A) (numberp I))
              (equal (selecta! (storea! A I V) I)
                     V))
.DE
.DS 
     Theorem.  store-of-select:
     (implies (and (arrayp! A) (numberp I))
              (equal (storea! A I (selecta! A I))
                     A))
.DE
.DS 
     Theorem.  select-of-store-2:
     (implies (and (arrayp! A)
                   (numberp I)
                   (numberp J)
                   (not (equal I J)))
              (equal (selecta! (storea! A I V) J)
                     (selecta! A J)))
.DE
.DS 
     Theorem.  select-of-store:
     (implies (and (arrayp! A)
                   (numberp I)
                   (numberp J))
              (equal (selecta! (storea! A I V) J)
                     (if (equal I J) V (selecta! A J))))
.DE
.DS 
     Theorem.  store-of-store-1:
     (implies (and (arrayp! A) (numberp I))
              (equal (storea! (storea! A I V) I W)
                     (storea! A I W)))
.DE
.B storer!
is the record store function.  The Rule Builder does not
know about Verifier record structures, but the definition as an undefined
function allows the appearance of
.B storer!
in rules.  Of course, the only thing known about it in the 
Rule Builder is that if the arguments to
.B storer!
are the same, the result is the same.
The Verifier proper has built-in knowledge about 
.B "storer!"
and
.B "selectr!\n"
, but that knowledge is type-dependent and cannot be used here.
.DS 
     Undefined Function.
     (storer! A B C)
.DE
.DS 
     Undefined Function.
     (selectr! r I)
.DE
.B "alltrue!"
is true of an object if and only if all its components have the Boolean
value 
.B "TRUE."
The Verifier has built-in knowledge about 
.B "alltrue!"
and, as with the record operators, that knowledge is type-dependent.
.DS 
     Undefined Function.
     (alltrue! r)
.DE
Integers are built up by defining a Boyer-Moore shell such that
negative numbers are a shell whose negative-guts field contains
the natural number for the absolute value.  This creates a problem
in that there is such a thing as negative zero.  This definition of
.B integerp!
disallows negative zero, and all our operations on the integers
never produce negative zero.
.DS 
     Definition.
     (integerp! X)
        =
     (if (numberp X)
         t
         (if (negativep X)
             (if (zerop (negative-guts X)) f t)
             f))
.DE
This turns negative zero into positive zero.
.DS 
     Definition.
     (znormalize X)
        =
     (if (negativep X)
         (if (equal (negative-guts X) 0) 0 X)
         X)
.DE
This is a conversion from a natural number to a negative number which
avoids minus zero.
.DS 
     Definition.
     (zmonus X)
        =
     (znormalize (minus X))
.DE
Unary negation.
.DS 
     Definition.
     (negi! X)
        =
     (if (integerp! X)
         (if (negativep X)
             (negative-guts X)
             (zmonus X))
         0)
.DE
Integer addition is defined by cases.  Proofs about integer arithmetic thus
generate extensive case analysis, and due to a limitation of the Boyer-Moore
prover it does not help to provide lemmas about nonrecursive definitions.
Therefore there are no lemmas in this knowledge base about the integer
arithmetic functions.  It is quite possible to prove rules about 
.B addi!
and its friends, and it is not usually difficult, but such proofs run slowly.
.DS 
     Definition.
     (addi! X Y)
        =
     (if (negativep X)
         (if (negativep Y)
             (zmonus (plus (negative-guts X)
                           (negative-guts Y)))
             (if (lessp Y (negative-guts X))
                 (zmonus (difference (negative-guts X) Y))
                 (difference Y (negative-guts X))))
         (if (negativep Y)
             (if (lessp X (negative-guts Y))
                 (zmonus (difference (negative-guts Y) X))
                 (difference X (negative-guts Y)))
             (plus X Y)))
.DE
.DS 
     Definition.
     (subi! X Y)
        =
     (addi! X (negi! Y))
.DE
.DS 
     Definition.
     (muli! X Y)
        =
     (if (negativep X)
         (if (negativep Y)
             (times (negative-guts X)
                    (negative-guts Y))
             (zmonus (times (negative-guts X) Y)))
         (if (negativep Y)
             (zmonus (times X (negative-guts Y)))
             (times X Y)))
.DE
.DS 
     Definition.
     (divi! X Y)
        =
     (if (negativep X)
         (if (negativep Y)
             (quotient (negative-guts X)
                       (negative-guts Y))
             (zmonus (quotient (negative-guts X) Y)))
         (if (negativep Y)
             (zmonus (quotient X (negative-guts Y)))
             (quotient X Y)))
.DE
The integer relational operators are defined by cases.
.DS 
     Definition.
     (lti! X Y)
        =
     (if (negativep X)
         (if (negativep Y)
             (lessp (negative-guts Y)
                    (negative-guts X))
             (not (and (equal (negative-guts X) 0)
                       (zerop Y))))
         (if (negativep Y) f (lessp X Y)))
.DE
.DS 
     Definition.
     (gti! X Y)
        =
     (lti! Y X)
.DE
.DS 
     Definition.
     (gei! X Y)
        =
     (not (lti! X Y))
.DE
.DS 
     Definition.
     (lei! X Y)
        =
     (not (lti! Y X))
.DE
.B "zabs"
is not actually used in rule building, but has been used in producing
soundness proofs for the definitions of integer arithmetic.
.DS 
     Definition.
     (zabs X)
        =
     (if (negativep X) (negative-guts X) X)
.DE
.DS 
     Definition.
     (sign-mult X Y)
        =
     (if (equal X 1)
         Y
         (if (equal Y 1) -1 1))
.DE
.DS 
     Definition.
     (positivep X)
        =
     (if (numberp X)
         (if (not (zerop X)) t f)
         f)
.DE
.DS 
     Definition.
     (sign X)
        =
     (if (numberp X)
         1
         (if (negativep X) -1 0))
.DE
.DS 
     Definition.
     (switch s X)
        =
     (if (equal s 1) X (negi! X))
.DE
.DS 
     Definition.
     (negative-and-non-zerop X)
        =
     (if (negativep X)
         (if (not (zerop (negative-guts X)))
             t f)
         f)
.DE
.DS 
     Definition.
     (diff-plus-1 X Y)
        =
     (difference (add1 Y) X)
.DE
The 
.B arraytrue!
function is used in showing definedness.
.B arraytrue!
of
.B A
is true from
.B I
to
.B J
if and only if every element of
.B A
within the range
.B I
to
.B J
is equal to true.
The Verifier will crank out 
.B arraytrue!
forms when the user writes
.DS
        defined(A,I,J)
.DE
or
.DS
        defined(A)
.DE
where
.B A
is an array.
.DS 
     Definition.
     (arraytrue! A I J)
        =
     (if (lessp J I)
         t
         (and (equal (alltrue! (selecta! A I)) t)
              (arraytrue! A (add1 I) J)))
.DE
We have all the obvious rules about
.B arraytrue!.
.DS 
     Theorem.  arraytrue-void-rule:
     (implies (lessp J I)
              (arraytrue! A I J))
.DE
.DS 
     Theorem.  arraytrue-single-rule:
     (equal (equal (arraytrue! A I I) t)
            (equal (alltrue! (selecta! A I)) t))
.DE
.DS 
     Theorem.  arraytrue-extend-upward-rule:
     (implies (and (equal (arraytrue! A I J) t)
                   (equal (alltrue! (selecta! A (add1 J)))
                          t))
              (equal (arraytrue! A I (add1 J)) t))
.DE
.DS 
     Theorem.  arraytrue-unchanged-rule:
     (implies (and (numberp X)
                   (numberp I)
                   (numberp J)
                   (arrayp! A)
                   (equal (arraytrue! A I J) t)
                   (or (lessp X I) (lessp J X)))
              (equal (arraytrue! (storea! A X V) I J)
                     t))
.DE
.DS 
     Theorem.  arraytrue-unchanged-2-rule:
     (implies (and (numberp X)
                   (numberp I)
                   (numberp J)
                   (arrayp! A)
                   (equal (alltrue! V) t)
                   (equal (arraytrue! A I J) t))
              (equal (arraytrue! (storea! A X V) I J)
                     t))
.DE
.DS 
     Theorem.  arraytrue-select-rule:
     (implies (and (arraytrue! A I J)
                   (numberp I)
                   (numberp J)
                   (numberp X)
                   (not (lessp X I))
                   (not (lessp J X)))
              (alltrue! (selecta! A X)))
.DE
Finally, we have the array construction function.  This function is
used to construct constant arrays in which all elements are the same.
The only use for this function is to construct objects which represent
the definedness parts of arrays known to be defined.
When an entire array replacement appears in Pascal-f, the definedness
part of the array will be set equal to a value built with
.B arrayconstruct!
in the verification condition.
.DS 
     Definition.
     (arrayconstruct! V I J)
        =
     (if (lessp J I)
         (empty-array)
         (storea! (arrayconstruct! V (add1 I) J)
                  I V))
.DE
.DS 
     Theorem.  arrayconstruct-is-arrayp:
     (arrayp! (arrayconstruct! V I J))
.DE
.DS 
     Theorem.  arrayconstruct-select-rule:
     (implies (and (numberp I)
                   (numberp J)
                   (numberp X)
                   (not (lessp X I))
                   (not (lessp J X)))
              (equal (selecta! (arrayconstruct! V I J) X)
                     V))
.DE
.DS 
     Theorem.  arrayconstruct-implies-arraytrue-rule:
     (implies (and (numberp I)
                   (numberp J)
                   (equal (alltrue! V) t))
              (equal (arraytrue! (arrayconstruct! V I J)
                                 I J)
                     t))
.DE
.P
That is the built-in knowledge base.  It takes about two hours to prove.

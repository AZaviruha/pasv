#include "global.h"

procedure WriteParseId;
begin
  writeln('parse.p 1.25') end;

procedure PutRead;
(* Input: CurrentChar.
 * Output: CurrentChar, StringPool.
 * Effect: Put the current character into the string pool, and get
 *   a new character.
 *)
begin
  PutStringPool(CurrentChar);
  ReadChar end;

function ReadExpression;
var
  ParenCount: integer;    (* Number of unmatched parens read so far *)
  PostFixChar: char;      (* Two thirds of the postfix attached to variables *)
  UniverseChar: char;     (* The other third *)
  ExpressionStart,        (* Used to remember beginning of expression *) 
  VarStart: StringIndex;  (* Used to remember beginning of variable *)
  Done: boolean;          (* Used to stop a loop *)
begin
  if CurrentChar <> '(' then
    SyntaxError
  else begin
    ExpressionStart := NextString;
    ParenCount := 0;
    repeat
      (* Copy the expression into the string pool until
       * we find an interesting character
       *)
      while not (CurrentChar in [')','(','$',' ']) do PutRead;

      case CurrentChar of

      ' ': begin
        SkipToNonBlank(false);
        PutStringPool(' ') end;

      ')': begin
        ParenCount := ParenCount - 1;
        PutRead end;

      '$': begin
        (* Test if we have reached end-of-statement without
         * reading all the expression.
         *)
        if CurrentClass = Ordinary then
          PutRead end;

      '(': begin
        ParenCount := ParenCount + 1;
        PutRead (* the paren *);

        (* We have reached the beginning of a variable, keyword, or
	 * user function name.
         * The difference is that keywords end with an exclamation mark
	 * and variables end with a ')';
         * We must translate:
	 *
	 *      (var) to (var@@@)
	 *      (new! var) to (var@++)
	 *      (defined! var) to (var+@@)
	 *      (defined! new! var) to (var+++)
	 *	
	 * Function names are not translated.
	 *
	 * We translate other (invalid) forms as well, but this phenomenon
	 * should be considered to be a bug, not a feature.
         *)

        (* Save the location of the identifier we are about to put in
         * the string pool; we may have to change it.
         *)
        VarStart := NextString;

	(* Defaults *)
	PostFixChar := '@';
	UniverseChar := '@';

	(* This loop reads a sequence of new! and/or defined!, followed
	 * by one more word.  That word is transformed according to
	 * the word that preceded it.
	 *)
        repeat
	  SkipToNonBlank(false);

	  while not (CurrentChar in ['!',' ','$','(',')']) do PutRead;

	  if CurrentChar = '!' then begin
	    (* We must check to see if we have read 'new' or 'defined'.
	     * put in a fake string end so StringEqual will work
	     *)
	    PutStringEnd;

	    if StringEqual(VarStart, QuoteNew) then begin
	      (* Record the existence of new! and erase it from the
	       * string pool.
	       *)
	      PostFixChar := '+';
	      NextString := VarStart;
	      ReadChar; (* throw away the ! *)
	      Done := false end
	    else if StringEqual(VarStart, QuoteDefined) then begin
	      (* Record the existence of defined! and erase it from the
	       * string pool.
	       *)
	      UniverseChar := '+';
	      NextString := VarStart;
	      ReadChar; (* throw away the ! *)
	      Done := false end
	    else begin
	      (* The builtin is neither new! nor defined!.  It should not
	       * have been preceded by new! or defined!, but if it was
	       * we ignore it (the J-code checker will catch that error).
	       *)

	      (* Backspace over the fake string end *)
	      NextString := NextString - 2; 
	      PutRead; (* the ! *)
	      Done := true end end
	  else begin
	      while CurrentChar = ' ' do ReadChar;	(* ignore spaces *)
	      if CurrentChar = ')' then begin		(* 0 args->variable*)
	          (* We have read an identifier; embellish it with a postfix
	           * devermined by the words that preceded it.
	           *)
                  PutStringPool(UniverseChar);
                  PutStringPool(PostFixChar);
                  PutStringPool(PostFixChar);
	          Done := true;
	      end else begin			(* User function found *)
		  PutStringPool(' ');		(* no embellishment *)
		  Done := true;			(* end identifier forms *)
		  end;
	      end;
	until Done end
      end
      until (CurrentClass = EndStatement) or (ParenCount = 0);

    if ParenCount <> 0 then 
      SyntaxError 
    else begin
      SkipToNonBlank(false);
      ReadExpression := ExpressionStart;
      PutStringEnd end end end;

function ReadType;
var
  ParenCount: integer;           (* Number of unmatched parens read so far *)
  ExpressionStart: StringIndex;  (* Used to remember beginning of expression *) 
begin
  if CurrentChar <> '(' then
    SyntaxError
  else begin
    ExpressionStart := NextString;
    ParenCount := 0;
    repeat
      (* Copy the expression into the string pool until
       * we find an interesting character
       *)
      while not (CurrentChar in [')','(','$',' ']) do PutRead;

      case CurrentChar of

      ' ': begin
        SkipToNonBlank(false);
        PutStringPool(' ') end;

      ')': begin
        ParenCount := ParenCount - 1;
        PutRead end;

      '$': begin
        (* Test if we have reached end-of-statement without
         * reading all the expression.
         *)
        if CurrentClass = Ordinary then
          PutRead end;

      '(': begin
        ParenCount := ParenCount + 1;
        PutRead end
      end
    until (CurrentClass = EndStatement) or (ParenCount = 0);

    if ParenCount <> 0 then 
      SyntaxError
    else begin
      SkipToNonBlank(false);
      ReadType := ExpressionStart;
      PutStringEnd end end end;

function ReadString;
var State: (MandatorySlash, LookingForSlash,
              LookingForParen, FoundError, FoundEnd);
    StringStart: StringIndex; (* The beginning of the string *)

begin
  begin
    (* A string must begin with an open paren *)
    if CurrentChar <> '(' then
      SyntaxError
    else begin
      StringStart := NextString;
      State := MandatorySlash;
      ReadChar;

      (* Each iteration of the following loop reads the string
       * element that begins with CurrentChar.  The loop is a
       * finite state machine.
       *)
      repeat
        if CurrentClass = EndLine then begin
          (* Read a string break *)
          SkipToNonBlank(false);
          if CurrentChar <> '/' then
            State := FoundError
          else 
            (* String breaks do not change the state *)
            ReadChar end
        else if CurrentClass = EndStatement then
          State := FoundError
        else begin
          if (State = MandatorySlash) then begin
            if CurrentChar = '/' then begin
              State := LookingForSlash;
              ReadChar end
            else
              State := FoundError end
          else begin
            (* The first slash is not put into the string pool, but
             * all other characters, including the final /), are.
	     * Tabs in the input are put into the string.
	     *)
	    if CurrentClass = TabChar then
	      PutStringPool(chr(9))
	    else
              PutStringPool(CurrentChar);

            if (CurrentChar = '/') and (State = LookingForSlash) then
              State := LookingForParen
            else if State = LookingForParen then begin
              if CurrentChar = ')' then
                State := FoundEnd 
              else
                State := LookingForSlash end;
            ReadChar end end
      until (State = FoundError) or (State = FoundEnd);

      if State = FoundError then 
        SyntaxError 
      else begin
        ReadString := StringStart;
        SkipToNonBlank(false) end end end end;

function ReadLabel;

const MaxDigits = 4;

var   DigitCount: 0..MaxDigits;  (* number of digits read so far *)
      LabelValue: LabelInt;      (* value of head of read label  *)
begin
  begin
    if not (CurrentChar in ['1'..'9']) then 
      SyntaxError
    else begin
      LabelValue := 0;
      DigitCount := 0;
      repeat
        LabelValue := 10 * LabelValue + (ord(CurrentChar) - ord('0'));
        DigitCount := DigitCount + 1;
        ReadChar;
      until (DigitCount = MaxDigits) or not (CurrentChar in ['0'..'9']);

      if (DigitCount = MaxDigits) and (CurrentChar in ['0'..'9']) then 
        SyntaxError
      else begin
        ReadLabel := LabelValue;
        SkipToNonBlank(false) end end end end;

function ReadKeyword;
const
  WordLengthLimit = 9;  (* Greater than length of longest keyword *)
var
  SaveIndex: StringIndex;
  HashKey: integer;
  WordLength:  0..WordLengthLimit;
  HashTry: 0..KeywordTableSize;   (* Used to search hash table *)
  ReturnValue: Keyword;           (* Used to save the value of the function
                                   * in a place where it can be inspected
                                   *)

begin
  begin
    SaveIndex := NextString;
    HashKey := 0;
    WordLength := 0;

    (* Note that we stop reading characters if we read more than
     * the longest keyword.  In that case, the hashed search is
     * guaranteed to fail, and the scan will be stalled.
     *)

    while (CurrentChar <> ' ') and
      (CurrentChar <> '$') and
      (WordLength < WordLengthLimit) do begin

      PutStringPool(CurrentChar);
      WordLength := WordLength + 1;
      HashKey := HashKey + ord(CurrentChar);
      ReadChar end;

    PutStringEnd;
    SkipToNonBlank(false);

    (* Retrieve the index of the keyword using the same search
     * algorithm used to insert the word (see InitKeyTable).
     *)

    HashTry := HashKey mod KeywordTableSize;

    if StringEqual(SaveIndex, KeywordTable[HashTry].Spelling) then 
      ReturnValue := KeywordTable[HashTry].KeyCode
    else begin
      HashTry := (HashTry + ord(StringPool[SaveIndex])) mod KeywordTableSize;
      if StringEqual(SaveIndex, KeywordTable[HashTry].Spelling) then 
        ReturnValue := KeywordTable[HashTry].KeyCode
      else
        SyntaxError end;

    (* Throw away the keyword read in *)
    NextString := SaveIndex;

    ReadKeyword := ReturnValue end end;

function ReadIdentifier;
begin
  begin
    if CurrentChar in DelimiterSet then 
      SyntaxError
    else begin
      ReadIdentifier := NextString;
      repeat
        PutRead
      until CurrentChar in DelimiterSet;
      PutStringEnd;
      SkipToNonBlank(false) end end end;

function ReadVariableList;
var
  List, NewNode: PointerToVariableList;
  VariableName: StringIndex;
  VarPtr: PointerToVariable;
  SaveString: StringIndex;

begin
  if CurrentChar <> '(' then 
    SyntaxError
  else begin
    ReadChar;
    SkipToNonBlank(false);
    List := nil;
    while not (CurrentChar in [' ', ')', '$']) do begin
      (* read a variable *)
      VariableName := ReadIdentifier;

      if (CurrentChar = ':') then begin
	ReadChar; (* discard the colon *)  
	SkipToNonBlank(false);
	VarPtr := GetVariable(VariableName,Create);

	(* Only keep the type long enough to send it to the theorem prover *)
	SaveString := NextString;
	TPdeclare(VariableName, ReadType);
	NextString := SaveString end

      else begin
        VarPtr := GetVariable(VariableName, GetActual);

        (* Throw away the variable just read in *)
        NextString := VariableName end;

      (* Add the variable just read and its shadow to the constructed list *)
      new(NewNode);
      NewNode^.Head := VarPtr;
      NewNode^.Tail := List;
      List := NewNode;

      (* The shadow variable can be found by tracing the BucketMate link *)
      new(NewNode);
      NewNode^.Head := VarPtr^.BucketMate;
      NewNode^.Tail := List;
      List := NewNode end;

    ReadVariableList := List;

    (* If ReStackTop is non-nil, then add a copy of the constructed list
     * to the ModList on top of the stack.
     *)
    if ReStackTop <> nil then with ReStackTop^ do begin
      while List <> nil do begin
	new(NewNode);
	NewNode^.Head := List^.Head;
	NewNode^.Tail := ModList;
	ModList := NewNode;
	List := List^.Tail end end;
	
    if CurrentChar = ')' then
    begin
      ReadChar;
      SkipToNonBlank(false) end
    else
      SyntaxError end end;
    
procedure BuildAssign(Here, V, SE, N, D: StringIndex);
(* Input: Here, V, SE, N, D.
 * Output: through string pool.
 * Assumption:  SE is a string of the form (S* (V)), where S is
 *   a sequence of selecta! and selectr! operations.
 *
 * Effect: build the string representation of:
 *
 *	   (and! (equal! (V@++)
 *			 (assign! SE N))
 *		 (equal! (V+++)
 *			 (assign! (S* (V+@@)) D)))
 *
 *  and put the constructed string at Here, obliterating any
 *  strings that were at or beyond Here in the pool.
 *
 *  Because the components SE, N, and D have already been processed
 *  by ReadExpression to eliminate new! and defined! in favor of
 *  decorations on variables, we must perform that translation manually
 *  here.  As documented in ReadExpression, the translations are:
 *
 *                (V)  :=:  (V@@@)
 *           (new! V)  :=:  (V@++)
 *       (defined! V)  :=:  (V+@@)
 *  (defined! new! V)  :=:  (V+++)
 *)
var
  ObjectStart: StringIndex;  (* Start of created string *)
  J: StringIndex; 

begin
   ObjectStart := NextString;
   ShortAppend('(and! (equ/)');
   ShortAppend('al! (/)     ');
   StringAppend(V);
   ShortAppend('@++) (assi/)');
   ShortAppend('gn! /)      ');
   StringAppend(SE);
   StringAppend(N);
   ShortAppend(')) (equal!/)');
   ShortAppend(' (/)        ');
   StringAppend(V);
   ShortAppend('+++)(assig/)');
   ShortAppend('n! /)       ');

   (* Now we make a slightly altered copy of SE, which is of the form:
    *
    * (select (select ... (select (V@@@)) ...))
    *
    * where "select" denotes either "selecta!" or "selectr!".
    * The necessary change is to replace V@@@ by V+@@, which we
    * do by changing the first @ to +.
    *)

    J := NextString;
    StringAppend(SE);
    while StringPool[J] <> '@' do J := J + 1;
    StringPool[J] := '+';
    StringAppend(D);
    J := StringCreate(')))/)      ');  (* Throw away the result *)

    (* Now the generated string has been created.  Move it over
     * to Here.
     *)
    NextString := Here;
    StringCopy(ObjectStart) end;
    
procedure ReadUnit;

type StatementClass = (Start, Middle, Finis, Insert);
(* There are three classes of statements.
 * Start statements are the very first BREAK instruction,
 * the WHEN instruction, and the JOIN instruction.
 * Finis instructions are the BRANCH, SPLIT, and HANG instructions.
 * Insert instructions are REIN and REOUT.
 * All other instructions are Middle instructions.
 * The sequence of instructions must be of the form:
 *
 *    (Start Middle* End)*
 *
 * with Inserts inserted anywhere you like.
 *)

var
  NotUsed: PointerToVariable;
  ThisClass, LastClass: StatementClass;
  FirstInstruction: boolean;
  V: StringIndex;
  Done: Boolean;
  StatementStart: Keyword;
  OrderError: Boolean;
  NewNode, LastNode, J: PointerToJnode;
  SaveString: StringIndex;
  SelectExpr, NewVal, DefVal: StringIndex; (* Pieces of an ASSIGN *)
  E, VL, NoDupList:
   PointerToVariableList;       (* List manipulation variables used by REOUT *)
  ST: PointerToReStack;         (* Also used by REOUT *)
begin
  ReStackTop := nil;

  StatementStart := ReadKeyword;
  if StatementStart <> BeginK then begin
    writeln('missing BEGIN');
    Abort end;
  
  PrintUnitId;
  
  (* The following loop reads and processes all the
   * variable declarations.  It leaves unread the end of the BREAK
   * statement that terminates the declarations.
   *)
  EnvLength := 0;
  repeat
    V := ReadIdentifier;
    if (CurrentChar = ':') then begin
      ReadChar; (* discard the colon *)  
      SkipToNonBlank(false);
      NotUsed := GetVariable(V,Create);

      (* Only keep the type long enough to send it to the theorem prover *)
      SaveString := NextString;
      TPdeclare(V, ReadType);
      NextString := SaveString;

      ReadStatementEnd;
      if (CurrentClass = EndFile) then begin
	writeln('premature eof');
	Abort end;
      Done := false end
    else if StringEqual(V,QuoteBREAK) then begin
      Done := true end
    else 
      SyntaxError
  until Done;

  (* The following loop builds the level-0 J-graph *)
  
  RequireList := nil;
  SplitList := nil;
  JoinList := nil;
  BranchList := nil;
  OtherList := nil;

  LastClass := Finis;
  FirstInstruction := true;
  LastNode := nil;

  repeat
    if FirstInstruction then
      StatementStart := BreakK
    else
      StatementStart := ReadKeyword;

    case StatementStart of

    BranchK: begin
      new(NewNode, BranchN);
      ThisClass := Finis;
      with NewNode^ do begin
        Jtag := BranchN;
        SimLink := BranchList;
        BranchList := NewNode;
        PathName := ReadString;
        Visited := false;
        AddLabel(ReadLabel, NewNode) end end;
        
    BreakK: begin
      new(NewNode, BreakN);
      if FirstInstruction then begin
        StartNode := NewNode;
        ThisClass := Start;
        FirstInstruction := false end
      else
        ThisClass := Middle;

      with NewNode^ do begin
        PathStart := ReadString;
        Jtag := BreakN;
        SimLink := OtherList;
        OtherList := NewNode;
        Jtag := BreakN end end;

    EndK: begin
      ThisClass := Start;
      NewNode := nil end;

    EmptySlot: 
      assert(false);

    HangK: begin
      ThisClass := Finis;
      NewNode := nil end;

    JoinK: begin
      ThisClass := Start;
      new(NewNode, JoinN);
      with NewNode^ do begin
        Jtag := JoinN;
        SimLink := JoinList;
        JoinList := NewNode;
        TraverseCount := 0;
	Marked := false;
        AddLabel(ReadLabel, NewNode);
        DirectDominator := StartNode end end;
        
    NewK: begin
      ThisClass := Middle;
      new(NewNode, NewN);
      with NewNode^ do begin
        Jtag := NewN;
	ClusterMark := Singleton;
        SimLink := OtherList;
        OtherList := NewNode;
        NewDeadVars := ReadVariableList;
        NewLiveVars := nil;
        NewState := ReadExpression end end;

    ReinK: begin
      ThisClass := Insert;

      (* Allocate a new (empty) entry on the top of ReStack *)
      new(ST);
      with ST^ do begin
	ReNew := nil;
	ModList := nil;
	Pop := ReStackTop end;
      
      ReStackTop := ST end;

    RenewK: begin
      ThisClass := Middle;

      if ReStackTop = nil then begin
	writeln('Unenclosed RENEW');
	Abort end;

      if ReStackTop^.ReNew <> nil then begin
	writeln('Duplicate RENEW');
	Abort end;

      new(NewNode, RenewN);
      with NewNode^ do begin
        Jtag := RenewN;
	ClusterMark := Singleton;
        SimLink := OtherList;
        OtherList := NewNode;
        NewDeadVars := nil;
        NewLiveVars := nil;
        NewState := ReadExpression end;
	
      ReStackTop^.ReNew := NewNode end;

    ReoutK: begin
      ThisClass := Insert;

      (* Check that REIN -- RENEW -- REOUT are properly nested *)
      if ReStackTop = nil then begin
	writeln('Missing REIN');
	Abort end;

      if ReStackTop^.ReNew = nil then begin
	writeln('Missing RENEW');
	Abort end;

      (* Create NoDupList, by eliminating the duplicates of the
       * current ModList.Eliminate duplicates from the ModList.  On entry,
       * the OnList bits of all variables will be false.  As we first encounter
       * each variable, we make its bit true.  We must be careful to turn
       * the bits off again before leaving this region of code.
       *)
      VL := ReStackTop^.ModList;
      NoDupList := nil;
      while VL <> nil do begin

	(* Take E off the front of VL *)
	E := VL;
	VL := VL^.Tail;
	
	(* If we have seen him already, delete him. *)
	if E^.Head^.OnList then
	  dispose(E)

	else begin

	  (* Mark E as being on the list *)
	  E^.Head^.OnList := true;

	  (* Add E to NoDupList *)
          E^.Tail := NoDupList;
	  NoDupList := E end end;

      (* Plant NoDupList in the NEW instruction that was generated
       * by the matching RENEW.
       *)
      ReStackTop^.ReNew^.NewDeadVars := NoDupList;

      (* Pop the ReStack *)
      ST := ReStackTop;
      ReStackTop := ReStackTop^.Pop;
      dispose(ST);

      (* For every element of NoDupList, turn off its OnList bit,
       * and a copy of it into the ModList for the (now) current context,
       * if one exists.
       *)
      while NoDupList <> nil do begin
	NoDupList^.Head^.OnList := false;
	if ReStackTop <> nil then begin
	  new(E);
	  E^.Head := NoDupList^.Head;
	  E^.Tail := ReStackTop^.ModList;
	  ReStackTop^.ModList := E end;
	
	NoDupList := NoDupList^.Tail end end;

    AssignK: begin
      ThisClass := Middle;
      new(NewNode, NewN);
      with NewNode^ do begin
	(* ASSIGN statements are translated to NEW statements.
	 * The statement:
         *
	 *     ASSIGN (v) (select(select((v)...))) (defval) (newval) 
         *
	 * is translated to:
	 *
	 *     NEW (v)
         *	   (and! (equal! (new! v)
         *			 (assign! (select (select (v)...))
         *				  (newval))
         *		 (equal! (defined! new! v)
         *			 (assign! (select (select (defined! v...)))
         *      				  (defval)))))
	 *
	 *  The operator (assign! A E) is interpreted by the theorem prover
	 *  to mean the result of the "root" of A after executing A := E.
	 *  This is a "funny" operator, since its value is not, strictly
	 *  speaking, a function of its operands.
	 *)

        Jtag := NewN;
        SimLink := OtherList;
        OtherList := NewNode;
        NewDeadVars := ReadVariableList;
        NewLiveVars := nil;
	SelectExpr := ReadExpression;
	DefVal := ReadExpression;
	NewVal := ReadExpression;

	(* BuildAssign writes the "assign" expression in the space
	 * formerly occupied by SelectExpr, destroying SelectExpr,
	 * NewVal, and DefVal.
	 *)
        BuildAssign(SelectExpr, NewDeadVars^.Tail^.Head^.Name,
				SelectExpr, NewVal, DefVal);

	NewState := SelectExpr end end;

    ProclaimK: begin
      ThisClass := Middle;
      new(NewNode, ProclaimN);
      with NewNode^ do begin
        Jtag := ProclaimN;
        SimLink := OtherList;
        OtherList := NewNode;
        Proclamation := ReadExpression end end;

    RequireK: begin
      ThisClass := Middle;
      new(NewNode, RequireN);
      with NewNode^ do begin
        Jtag := RequireN;
        SimLink := RequireList;
        RequireList := NewNode;
        Requirement := ReadExpression;
        ErrMsg := ReadString end end;

    SplitK: begin
      ThisClass := Finis;
      new(NewNode, SplitN);
      with NewNode^ do begin
        Jtag := SplitN;
        SimLink := SplitList;
        SplitList := NewNode;
        AddLabel(ReadLabel, NewNode) end end;

    WhenK: begin
      ThisClass := Start;
      new(NewNode, WhenN);
      with NewNode^ do begin
        Jtag := WhenN;
        SimLink := OtherList;
        OtherList := NewNode;
        Constraint := ReadExpression;
        AddLabel(ReadLabel, NewNode) end end;

    end; (* of case statement *)

    (* With a few exceptions, the Next field points to the lexically next
     * instruction, and the Previous field points to the lexically previous
     * instruction.  The exceptions are the Next field of a SplitN or
     * BranchN, and the Previous field of WhenN or JoinN.  Since at this
     * time we do not know the right values for the exceptions, we put
     * the wrong values in and change them later.  (It is easier to put in
     * the wrong values than to test for the exceptions).
     *)
     
    (* Instructions of class Insert do not generate nodes.  None of the
     * order-checking or link-resolving machinery should be performed
     * for those instructions.
     *)
    if ThisClass <> Insert then begin
      (* NewNode or LastNode can be nil due to HANG instructions *)
      if NewNode <> nil then
	NewNode^.Previous := LastNode;

      if LastNode <> nil then
	LastNode^.Next := NewNode;

      LastNode := NewNode;

      (* Make sure the order restriction:
       *   (Start Middle* Finis)*
       * has been observed.
       *)
      case ThisClass of
      Start:         OrderError := (LastClass <> Finis);
      Middle, Finis: OrderError := LastClass = Finis;
      end;

      LastClass := ThisClass;

      if OrderError then begin
	writeln('instruction order');
	Abort end end;

    ReadStatementEnd;
  until (StatementStart = EndK) or (CurrentClass = EndFile);

  if StatementStart <> EndK then begin
    writeln('premature eof');
    Abort end;

  (* Make sure that all REINs have matching REOUTs. *)
  if ReStackTop <> nil then begin
    writeln('Missing REOUT');
    Abort end;

  (* Find all the nodes in the Label Table and use them to correct
   * the Next and Previous exceptions.
   *)
  DismantleLabelTable; 

  (* Now that the number of variables is known, allocate environments
   * in Split and Join nodes.
   *)
  J := SplitList;
  while J <> nil do begin
    J^.SplitEnv := AllocateEnv;
    J := J^.SimLink end;

  J := JoinList;
  while J <> nil do begin
    J^.JoinEnv := AllocateEnv;
    J := J^.SimLink end end;
  

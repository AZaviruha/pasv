
;
;	Debugging tools for rule handler
;
;
;	Test case processor
;
;	test tools
;
;	decl  --  declare and print declaration
;
(defun decl (item)
    (remprop (car item) 'vtype)		; cleanup
    (remprop (car item) 'dtype)		; cleanup
    (patom (car item)) (patom ":  ") (patom (cadr item)) (terpri)
    (vardecl (car item) (cadr item)))
;
;	testcase  --  set and save test case
;
(defun testcase (name result form)
    (set name form)			; save under specified name
    (setq testlist (append1 testlist (list name result form))) ; add to test list
	)
;
;	runtests  --  run all test cases
;
(defun runtests nil
    (simpinit)				; reinitialize
    (begin-decl)			; begin junit
    (mapcar 'decl testdecls)		; do all declarations
    (terpri)
    (mapcar 'dolemma testrules)		; do all rules
    (terpri)
    (mapcar 'runtest testlist) 		; try all tests
    (terpri)
    (end-decl) t)			; done
;
;	runtest  --  run a test case
;
(defun runtest (l)
    (prog (name expected form result)
	(setq name (car l))		; get test name
	(setq expected (cadr l))	; get expected result
	(setq form (caddr l))		; get test case itself.
	(patom "Test case ") (patom name) (patom ": expect ") 
	(patom (cond (expected "true.") (t "false.")))
	(terpri)
	(pform form)			; print form begin simplified
	(setq result (prove form))	; do the test
	(patom result)
	(cond ((not (equal expected result)) ; if fail
	       (patom " -- TEST CASE DID NOT PRODUCE EXPECTED RESULT") (terpri)
	       (break "Test failed."))
	      (t (patom " -- OK") (terpri)))
	(terpri)
	nil))
;
;	Dumping and tracing tools
;
;	dumpaything
;
(defun dumpanything (xx)
    (cond	((isenode xx) (patom (dumpenodeexpr xx)))
		((atom xx) (patom xx))
		(t (patom "(")
		   (mapcar 'dumpanything xx)
		   (patom ")")))
		(patom " ")
		nil)
;
;	dumpbind1  --  dump one pattern-var to expr-var binding
;
(defun dumpbind1 (bind)
	(patom "        ")
	(print (car bind))			; pattern var
	(patom "  <==>  ")			; marker
	(patom (dumpenodeexpr (cdr bind)))	; expression
	(terpri))
;
;	dumpbinds  --  dump all bindings for rule being applied
;
(defun dumpbinds (binds)
	(cond ((null binds) nil)		; if done, exit
	      (t (dumpbind1 (car binds))	; dump binding
		 (dumpbinds (cdr binds)))))	; recurse for rest
;
;	dumpelist  --  dump mixed list of enodes and atoms
;
(defun dumpelist (elist)
	(cond ((atom elist) (patom elist))
	      ((isenode elist) (patom (dumpenodeexpr elist)))
	      (t	(patom "(")
			(mapc 'dumpelist elist)
			(patom ")")))
	(patom " ")
	nil)
;
;	dumpapplyrule  --  dump bindings
;
(defun dumpapplyrule nil
	(patom "applyrule: ") 
	(patom (arg 3))
	(terpri)
	(dumpbinds (arg 2))
	(terpri)
	)
;
;	Demon dumping
;
(defun dumpfiredemon nil
    (patom "Firing ")
    (patom (arg 1))
    (terpri))
(defun dumppfire nil
    (patom "Pfire: ")
    (terpri)
    (patom "    Function: ");
    (patom (arg 1))
    (terpri)
    (patom "    Node: ")
    (patom (dumpenodeexpr (arg 2)))
    (terpri)
    (patom "    Bindings: ")
    (terpri)
    (dumpbinds (arg 3))
    (terpri))
;
;	dumppropagate
;
(defun dumppropagate nil
    (patom "Propagate: ")
    (dumpelist (arg 1))
    (terpri))
;
;	dumpemerge
;
(defun dumpemerge nil
    (patom "emerge: ")
    (cond ((eq (eroot (arg 1)) (eroot (arg 2))) (patom " (ALREADY EQUAL)")))
    (terpri)
    (patom "    ")
    (patom (dumpenodeexpr (arg 1)))
    (terpri)
    (patom "    ")
    (patom (dumpenodeexpr (arg 2)))
    (terpri)
    nil
	)
;
;	dumppushcontext
;
(defun dumppushcontext nil (patom "pushcontext") (terpri))
(defun dumppopcontext nil (patom "popcontext") (terpri))
;
;	dumpchangedatatype
;
(defun dumpchangedatatype nil
 	(patom "changedatatype: ")
	(patom (dumpenodeexpr (arg 1)))
	(patom " <== ")
	(patom (arg 3))
	(terpri)
	(and (edatatype (eroot (arg 1))) (not (equal (arg 3)
			 (commontype (edatatype (eroot (arg 1))) (arg 3))))
	     (break "Less-restrictive changedatatype"))
	nil
	)
;
;	dumpemerget
;
(defun dumpemerget nil
    (prog nil
	(and (equal (arg 2) (arg 3)) (return))
	(patom "emerget: ")
	(patom (dumpenodeexpr (arg 1)))
	(patom " <== ")
	(patom (arg 2))
	(patom "    ")
	(patom (arg 3))
	(terpri)
	))
;
;	dumppropagaterule
;
(defun dumppropagaterule nil
    (patom "propagaterule: ")
    (patom (arg 1))
    (terpri))
;
;	dumpseteheight
;
(defun dumpseteheight nil
  (prog nil
    (and (equal (eheight (arg 1)) (arg 2)) (return nil)) ; no dump if no change
    (patom "seteheight: ")
    (patom (dumpenodeexpr (arg 1)))
    (patom "     ")
    (patom (arg 2))
    (patom "  (was ")
    (patom (eheight (arg 1)))
    (patom ")") (terpri)))
;
;	dumpqueuetypewait
;
(defun dumpqueuetypewait nil
	(patom "queuetypewait: ")
	(patom (dumpenodeexpr (arg 1)))
	(patom " ")
	(patom (arg 2))
	(patom " ")
	(patom (arg 3))
	(terpri)
	)
;
;	dumpsimpinit  --  place to reset trace counters
;
(defun dumpsimpinit nil
   (setq casedepth 0)
	)
;
;	dumpsimpsave  --  entering a new case
;
(defun dumpsimpsave nil
   (patom "simpsave: ")
   (setq casedepth (add1 casedepth))
   (printdepth casedepth) (terpri))
(defun dumpsimprestore nil
   (patom "simprest: ")
   (setq casedepth (- casedepth 1))
   (printdepth casedepth) (terpri))
(defun printdepth (n)
   (cond ((> n 0)
	(patom "| ") (printdepth (- n 1)))))
;
;	dumpsubprovercall
;
(defun dumpsubprovercall nil
   (patom "subprovercall: ")
   (patom (arg 2))
   (patom "  ")
   (patom (arg 3))
   (patom "  #")
   (patom (enumber (arg 1)))
   (patom ": ")
   (patom (dumpenodeexpr (arg 1)))
   (terpri))
;
;	dumpnew-eassertz
;
;	Shows all terms going into Z box
;
(defun dumpnew-iassertz nil
       (patom "new-iassertz: ")
       (mapcar 'dumpzterm (arg 1))
       (terpri))
(defun dumpnew-eassertz nil
       (patom "new-eassertz: ")
       (mapcar 'dumpzterm (arg 1))
       (terpri))
(defun dumpzterm (x)
       (patom (caar x))		; constant multiplier
       (patom " * ")		; indicate multiplication
       (patom (dumpenodeexpr (cadr x)))	; term
       (terpri)
       (patom "              ")
	)
;
;	dumppropeq   --   terms coming out of Z box
;	
(defun dumppropeq nil
	(patom "propeq: ")
	(patom (dumpenodeexpr (arg 1)))
	(patom "   ")
	(patom (dumpenodeexpr (arg 2)))
	(terpri))
;
;	dumpenodeexpr  --  dump enode expression without looking
;			   at root information.
;
(defun dumpenodeexpr (node)
     (cond ((atom node) node)
	   ((isenode node) (dumpenodeexpr (esuccessors node)))
	   (t (concat "(" (concatlist (mapcar 'dumpenodeexpr node)) ")"))))
(defun concatlist (lst)
     (cond ((null lst) nil)
	   ((null (cdr lst)) (car lst))
	   (t (concat (car lst) " " (concatlist (cdr lst))))))
;
;	tracetellz
;
(defun dumptellz nil
    (patom "tellz: ")
    (patom (dumpenodeexpr (arg 2)))
    (terpri))
;
;	traceprepattern  --  dump pattern before and after processing
;
(defun dumpprepattern (fname fargs)
    (setq prepatterndepth (+ 1 prepatterndepth))
    (cond ((equal prepatterndepth 1)
    	(patom "prepattern: ")
    	(patom (dumpenodeexpr (car fargs)))
    	(terpri))
	(t nil)))
(defun dumpexitprepattern (fname fresult)
    (setq prepatterndepth (- prepatterndepth 1))
    (cond ((equal prepatterndepth 0)
    	(patom "Exiting prepattern: ")
    	(patom (dumpenodeexpr fresult))
    	(terpri))
	(t nil)))
;
;	These turn on tracing of the indicated function
;
(defun tracefiredemon nil (trace (firedemon if (dumpfiredemon))))
(defun tracepfire nil (trace (pfire if (dumppfire))))
(defun traceapplyrule nil (trace (applyrule if (dumpapplyrule))))
(defun tracecontext nil (trace (pushcontext if (dumppushcontext)))
			(trace (popcontext if (dumppopcontext))))
(defun tracepropagate nil (trace (propagate if (dumppropagate))))
(defun traceemerge nil (trace (emerge if (dumpemerge))))
(defun tracechangedatatype nil (trace (changedatatype if (dumpchangedatatype))))
(defun traceemerget nil (trace (emerget if (dumpemerget))))
(defun tracepropagaterule nil (trace (propagaterule if (dumppropagaterule))))
(defun traceseteheight nil (trace (seteheight if (dumpseteheight))))
(defun tracequeuetypewait nil (trace (queuetypewait if (dumpqueuetypewait))))
(defun tracesubprovercall nil (trace (subprovercall if (dumpsubprovercall))))
(defun tracenew-iassertz nil (trace (new-iassertz if (dumpnew-iassertz))))
(defun tracenew-eassertz nil (trace (new-eassertz if (dumpnew-eassertz))))
(defun tracepropeq nil (trace (propeq if (dumppropeq))))
(defun tracetellz nil (trace (tellz if (dumptellz))))
(defun traceze nil (tracenew-iassertz) (tracenew-eassertz) 
			(tracetellz) (tracepropeq))
(defun traceprepattern nil (setq prepatterndepth 0)
			   (trace (prepattern traceenter dumpprepattern
			                      traceexit dumpexitprepattern)))
(defun tracecasing nil 
	(trace (simpsave if (dumpsimpsave)))
	(trace (simprestore if (dumpsimprestore)))
	(trace (simpinit if (dumpsimpinit))))
(setq prinlevel 5 prinlength 5)		; avoid runaway printing

"@(#)dosimp.l	2.1"

;	Load-and-go simplifier
(load 'setup)
;;;	Execute the simplifier on expressions read from standard input
(def dosimp (lambda nil 
		    (print '> )
		    (do conj nil nil (not (setq conj (read)))  
			(setq thm (simp conj))
			(pp thm)
			(print '> )
			)
		    )
  )
  (dosimp)

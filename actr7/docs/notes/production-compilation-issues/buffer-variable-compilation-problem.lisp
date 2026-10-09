These are some of the case that lead to the version 4.1 update to production compilation.


(clear-all)


;; This is a problem

(define-model f1
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal (car (define-chunks-fct (list (list 'color (buffer-read 'goal))))))
  
  (p a
     =goal>
     state nil
     ==>
     =goal>
     state t)
  (p b
     =goal>
     state t
     =imaginal>
     color =goal
     
     ==>
     =goal>
     state =imaginal))

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       COLOR =GOAL0
 ==>
   =GOAL>
       STATE =IMAGINAL
)


;; Here it is without the hack to set imaginal, which avoids the color =goal issue
;; because it's set in first and tested in second, but then the instantiation of
;; =imaginal seems puzzling -- is that right?:

(define-model f2
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal 'busy)
  
  (p a
     =goal>
     state nil
     =imaginal>
     ==>
     =goal>
     state t
     =imaginal>
     color =goal)
  
  (p b
     =goal>
     state t
     =imaginal>
     color =goal
     
     ==>
     =imaginal>
     =goal>
     state =imaginal))


(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
 ==>
   =IMAGINAL>
       COLOR =GOAL
   =GOAL>
       STATE BUSY-0
   )



;;; what if there are three productions such that the goal setting happens
;;; prior to that.  Still has the renamed variable issue, but why isn't
;;; the imaginal buffer instantiated this time?  Is it because it was
;;; renamed above which lead to that?


(define-model f3
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal 'busy)
  
  (p a
     =goal>
     state nil
     =imaginal>
     ==>
     =goal>
     state 1
     =imaginal>
     color =goal)
  
  (p a1
     =goal>
     state 1
     ==>
     =goal>
     state t)
  
  
  (p b
     =goal>
     state t
     =imaginal>
     color =goal
     
     ==>
     =imaginal>
     =goal>
     state =imaginal))


(P PRODUCTION1
  "A1 & B"
   =GOAL>
       STATE 1
   =IMAGINAL>
       COLOR =GOAL1
 ==>
   =IMAGINAL>
   =GOAL>
       STATE =IMAGINAL
)


;;; Here's the test to see if that was why, and sure enough it seems
;;; to be the case since now it is instantiated


(define-model f4
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal 'busy)
  
  (p a
     =goal>
     state nil
     =imaginal>
     ==>
     =goal>
     state 1
     =imaginal>
     color =goal)
  
  (p a1
     =goal>
     state 1
     =imaginal>
     ==>
     =imaginal>
     =goal>
     state t)
  
  
  (p b
     =goal>
     state t
     =imaginal>
     color =goal
     
     ==>
     =imaginal>
     =goal>
     state =imaginal))


(P PRODUCTION1
  "A1 & B"
   =GOAL>
       STATE 1
   =IMAGINAL>
       COLOR =GOAL1
 ==>
   =IMAGINAL>
   =GOAL>
       STATE BUSY-0
)

;; How about this monstrocity! It's bad for multiple reasons, but only
;; the goal variable issue is really fixable.  The fact that the
;; imaginal-action request is how production b matches sort of saves
;; things since the composed production when fixed for =goal is
;; unlikely to match and get used...

(define-model f5
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal (car (define-chunks-fct (list (list 'color (buffer-read 'goal))))))
  
  (defun update-imaginal ()
    (schedule-event-now 'crazy :priority :min)
    )
  (defun crazy ()
    (mod-buffer-chunk 'imaginal (list 'color (buffer-read 'goal)))
    (set-imaginal-free))
  
  (p a
     =goal>
     state nil
     ==>
     +goal>
     state t
     +imaginal-action>
     isa generic-action
     action update-imaginal)
  
  (p b
     =goal>
     state t
     =imaginal>
     color =goal
     
     ==>
     =goal>
     state =imaginal))

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       COLOR =GOAL0
 ==>
   +IMAGINAL-ACTION>
       ACTION UPDATE-IMAGINAL
   +GOAL>
       STATE =IMAGINAL
)




;; this is a problem

(define-model f6
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal (car (define-chunks-fct (list (list 'color (buffer-read 'goal))))))
  
  (p a
     =goal>
     state nil
     ==>
     =goal>
     state t)
  (p b
     =goal>
     state t
     
     !safe-bind! =k (symbol-name =goal)
     ==>
     =goal>
     state =k))

#|Warning: No production defined for (PRODUCTION0 "A & B" =GOAL> STATE NIL !SAFE-BIND! =K (SYMBOL-NAME =GOAL0) ==> =GOAL> STATE =K). |#


;; Should the RHS bind be instantiated? Didn't think so and the 
;; example below suggests not so this is problematic

(define-model f7
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal (car (define-chunks-fct (list (list 'color (buffer-read 'goal))))))
  
  (p a
     =goal>
     state nil
     ==>
     =goal>
     state t)
  (p b
     =goal>
     state t
     
     ==>
     !safe-bind! =k (symbol-name =goal)
     =goal>
     state =k))

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
 ==>
   =GOAL>
       STATE =K.
   !SAFE-BIND! =K (SYMBOL-NAME FREE-0)
)


;; double check for rhs bind instantiation

 (define-model f7a
                  (sgp :esc t :epl t :pct t)
                (set-buffer-chunk 'goal 'green)
                
                (p a
                   =goal>
                   state nil
                   ==>
                   =goal>
                   state t
                   )
                (p b 
                   =goal>
                   state t
                   color =g
                   ==>
                   !safe-bind! =k (symbol-name =g)
                   =goal>
                   state =k))
                   

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
       COLOR =G
 ==>
   =GOAL>
       STATE =K
   !SAFE-BIND! =K (SYMBOL-NAME =G)
)

;; This generates a bad production, but should it even be allowed?
;; Doesn't seem like it, unless it instantiates since it's not 
;; referring to the same =goal as the first production which means the 
;; renaming is valid in this case...

(define-model f8
    (sgp :esc t :epl t :pct t)
  (set-buffer-chunk 'goal 'free)
  (set-buffer-chunk 'imaginal (car (define-chunks-fct (list (list 'color (buffer-read 'goal))))))
  
  (p a
     =goal>
     state nil
     
     ==>
     
     +goal>
     state t)
  
  (p b
     =goal>
     state t
     
      !safe-bind! =k (symbol-name =goal)
     ==>
     =goal>
     state =k))


#|Warning: No production defined for (PRODUCTION0 "A & B" =GOAL> STATE NIL !SAFE-BIND! =K (SYMBOL-NAME =GOAL0) ==> +GOAL> STATE =K). |#






#######################################################################

Possible fix -- don't consider buffer name variables that occur on the LHS to be basic-variables

(defun basic-variables (module p)
  (multiple-value-bind (value present) (gethash (production-name p) (compilation-module-basic-var-table module))
    (if present
        value
        (setf (gethash (production-name p) (compilation-module-basic-var-table module))
          (set-difference
           (remove-if (lambda (x)
                       (find x (compilation-module-drop-out-buffers module) :key 'cdr))
                      (production-variables p))
           (mapcar (lambda (x) (intern (concatenate 'string "=" (string x)))) (production-lhs-buffers p)))))))



Doesn't affect any of the test models!


Does that fix things for the models above:

F1 seems good:

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       COLOR =GOAL
 ==>
   =GOAL>
       STATE =IMAGINAL
   )

f2 seems good:

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
 ==>
   =IMAGINAL>
       COLOR =GOAL
   =GOAL>
       STATE =IMAGINAL
)



f3 seems good:

(P PRODUCTION1
  "A1 & B"
   =GOAL>
       STATE 1
   =IMAGINAL>
       COLOR =GOAL
 ==>
   =IMAGINAL>
   =GOAL>
       STATE =IMAGINAL
)


f4 seems good:

(P PRODUCTION1
  "A1 & B"
   =GOAL>
       STATE 1
   =IMAGINAL>
       COLOR =GOAL
 ==>
   =IMAGINAL>
   =GOAL>
       STATE =IMAGINAL
   )

f5 seems ok -- given that the composed production wouldn't
ever match since it's the imaginal action that sets things up
and there's no way for compilation to know that since it's
happening in code

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       COLOR =GOAL
 ==>
   +IMAGINAL-ACTION>
       ACTION UPDATE-IMAGINAL
   +GOAL>
       STATE =IMAGINAL
)


f6 looks good:

(P PRODUCTION0
  "A & B"
   !SAFE-BIND! =K (SYMBOL-NAME =GOAL)
   =GOAL>
       STATE NIL
 ==>
   =GOAL>
       STATE =K
)

f7 seems to work now:


(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
 ==>
   =GOAL>
       STATE =K
   !SAFE-BIND! =K (SYMBOL-NAME =GOAL)
   )

f7a doesn't get broken with this change:

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
       COLOR =G
 ==>
   =GOAL>
       STATE =K
   !SAFE-BIND! =K (SYMBOL-NAME =G)
   )


f8 however now produces this which isn't right
because it's now binding =k to the old goal instead
of the new goal:



(P PRODUCTION0
  "A & B"
   !SAFE-BIND! =K (SYMBOL-NAME =GOAL)
   =GOAL>
       STATE NIL
 ==>
   +GOAL>
       STATE =K
   )

I think that's a separate fix to basically just eliminate
a pair if p1 makes a request to a buffer and p2 uses LHS
buffer variables mentioning that buffer...

;;; These actually work after fixing an issue that was broken, but they
;;; do raise a question as to whether things should retain their
;;; dynamic nature instead of being instantiated.  

;;; If the pre-instantiate code only applied to the mapping of the
;;; variables then it should be able to still produce a variablized 
;;; production.  However, there may be a lot of unforseen issues with
;;; that so for now it hasn't been implemented.


(defun values-close (a) nil)


(define-model foo
                (sgp :esc t :epl t :pct t :trace-detail high)
              
                (chunk-type dummy parent target action self )
              
              (define-chunks action1 retrieve-action-parent value act)
              (add-dm (target value action1))
              
              (goal-focus free)
              (set-buffer-chunk 'retrieval (car (define-chunks (state act target value value 3 parent 10))))
  
  (p set-parent-goal-act
     =goal>
     state nil
     =retrieval>
     target =feature
     =feature =t-value
     parent =parent-goal
     ==>
     =goal>
     state t
     target =feature
     =feature =t-value
     )
  (P PRODUCTION22
   !SAFE-EVAL! (NOT (VALUES-CLOSE =TARGET-VALUE))
   =GOAL>
       =FEATURE =TARGET-VALUE
       STATE t
       TARGET =FEATURE
 ==>
     =goal>
     state 1))

(PRODUCTION0 
 "SET-PARENT-GOAL-ACT & PRODUCTION22" 
 =GOAL> 
   STATE NIL 
 =RETRIEVAL> 
   =FEATURE =T-VALUE 
   PARENT =PARENT-GOAL 
   TARGET =FEATURE 
 !SAFE-EVAL! (NOT (VALUES-CLOSE =TARGET-VALUE)) 
 ==> 
 =GOAL> 
   =FEATURE =T-VALUE 
   TARGET =FEATURE 
 STATE 1)




Worse

(define-model foo
                (sgp :esc t :epl t :pct t :trace-detail high)
              
                (chunk-type dummy parent target action self )
              
              (define-chunks action1 retrieve-action-parent value act)
              (add-dm (target value action1))
              
              (goal-focus free)
              (set-buffer-chunk 'retrieval (car (define-chunks (state act target value value 3 parent 10))))
  (set-buffer-chunk 'imaginal (car (Define-chunks (value 3))))
  
  (p set-parent-goal-act
     =goal>
     state nil
     =retrieval>
     target =feature
     =feature =t-value
     parent =parent-goal
     ==>
     =goal>
     state t
     target =feature
     =feature =t-value
     )
  (p production22
     =imaginal>
     =feature =target-value
   =goal>
       =feature =target-value
       state t
       target =feature
 ==>
     =goal>
     state 1))

(P PRODUCTION0
  "SET-PARENT-GOAL-ACT & PRODUCTION22"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       =FEATURE =TARGET-VALUE
   =RETRIEVAL>
       =FEATURE =T-VALUE
       PARENT =PARENT-GOAL
       TARGET =FEATURE
 ==>
   =GOAL>
       =FEATURE =T-VALUE
       TARGET =FEATURE
       STATE 1
)

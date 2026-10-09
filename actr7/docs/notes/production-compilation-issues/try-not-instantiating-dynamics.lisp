
;;; These are the issues associated with the version 5.0 changes to the production compilation module

(clear-all)
(define-model dont-instantiate-test
    (sgp :epl t :pct t)
  
  (chunk-type a slot value)
  (goal-focus free)
  (set-buffer-chunk 'imaginal (car (define-chunks (slot color value blue))))
  
  (p a
     =goal>
     state nil
     =imaginal>
     slot =x
     value =y
     ==>
     =imaginal>
     =goal>
     state t
     =x =y)
  
  (p b
     =goal>
     =s =v
     =imaginal>
     slot =s
     ==>
     !output! =v
     )
  )

#| The objective would be a production that looks like this:

(p a+b
   =goal>
   state nil
   =imaginal>
   slot =x
   value =y
   ==>
   !output! =y
   =goal>
   state t
   =x =y)


Instead of this which is what happens now:

(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       VALUE =Y
       SLOT COLOR
 ==>
   =GOAL>
       COLOR =Y
       STATE T
   !OUTPUT! =Y
)

|#


;; similarly, this 

(define-model dont-instantiate-test
    (sgp :epl t :pct t)
  
  (chunk-type a slot value)
  (goal-focus free)
  (set-buffer-chunk 'imaginal (car (define-chunks (slot color value blue))))
  
  (p a
     =goal>
     state nil
     =imaginal>
     slot =x
     value =y
     ==>
     =imaginal>
     =goal>
     state t
     color =y
     =y nil)
  
  (p b
     =goal>
     =s =v
     =imaginal>
     slot =s
     value =q
     ==>
     !output! =v
     )
  )


#| currently produces this which is wrong!


(P PRODUCTION0
  "A & B"
   =GOAL>
       STATE NIL
       =X =V
   =IMAGINAL>
       SLOT =X
       VALUE BLUE
 ==>
   =GOAL>
       BLUE NIL
       COLOR BLUE
       STATE T
   !OUTPUT! =V
   )

|#

;; This is a more involved example that was more like the
;; situation which started this investigation

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

#|
Produces this:

Production Compilation process started for PRODUCTION22
  Production SET-PARENT-GOAL-ACT and PRODUCTION22 are being composed.
  New production:

(P PRODUCTION0
  "SET-PARENT-GOAL-ACT & PRODUCTION22"
   =GOAL>
       STATE NIL
   =IMAGINAL>
       VALUE =T-VALUE
   =RETRIEVAL>
       VALUE =T-VALUE
       PARENT =PARENT-GOAL
       TARGET VALUE
 ==>
   =GOAL>
       VALUE =T-VALUE
       TARGET VALUE
       STATE 1
   )
|#
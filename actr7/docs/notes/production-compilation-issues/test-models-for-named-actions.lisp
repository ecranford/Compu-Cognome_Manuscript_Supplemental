
These were some example situations that lead to the addition of the :cia and :rir parameters with version 7.21.3


(DEFINE-MODEL F (SGP :ESC T :EPL T :PCT T) (GOAL-FOCUS-FCT (CAR (DEFINE-CHUNKS (VALUE RED))))
                            (P Z =GOAL> STATE NIL VALUE =X ==> =GOAL> STATE T) (P A =GOAL> STATE T VALUE =G ==> +GOAL> =G)
                            (P B =GOAL> STATE NIL ==> =GOAL> STATE 1))


(define-model f
                  (sgp :esc t :epl t :pct t)
                (add-dm (g value 3 color red))
                
                (goal-focus g)
                
                (p a
                   =goal>
                   value 3
                   ==>
                   +retrieval> =goal
                   *goal>
                   value 2
                   )
                (p b
                   =goal>
                   value 2
                   =retrieval>
                   color =r
                   ==>
                   +goal> =r)
                (p c
                   =goal>
                   color red
                   value nil
                   ==>
                   =goal>
                   value 3))



(define-model f
                  (sgp :esc t :epl t :pct t)
                (add-dm (g value 3 color red))
                
                (goal-focus g)
                
                (p a
                   =goal>
                   value 3
                   ==>
                   +retrieval> =goal
                   *goal>
                   value 2
                   )
                
                (p b
                   =goal>
                   value 2
                   =retrieval>
                   
                   ==>
                   +goal> =retrieval))






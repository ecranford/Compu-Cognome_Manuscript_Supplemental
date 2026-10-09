This example run shows a bug with the variable binding in duplicate LHS safe-binds not being 
applied to the RHS safe-eval and output actions when the duplicate is removed.

Has been fixed as of r3105


CG-USER(27): (clear-all)
NIL
CG-USER(28):  (define-model x
                  (sgp :epl t :pct t) (goal-focus free) (set-buffer-chunk 'imaginal (car (define-chunks (slot1 color slot2 color))))
                (p a
    =goal>
      state nil
    =imaginal>
      slot1 =s
    !safe-bind! =v (car (list 1))
   ==>
    =imaginal>
    =goal>
      =s =v)

  (p b
    =goal>
      =s =y
    =imaginal>
      slot2 =s
   ==>
     =imaginal>
    !output! =y
    =goal>)

)
#|Warning: Extending chunks with slot named SLOT1 because of chunk definition (SLOT1 COLOR SLOT2 COLOR) |#
#|Warning: Extending chunks with slot named SLOT2 because of chunk definition (SLOT1 COLOR SLOT2 COLOR) |#
#|Warning: Creating chunk COLOR with no slots |#
#|Warning: Productions test the STATE slot in the GOAL buffer which is not requested or modified in any productions. |#
X
CG-USER(29): (run 1)
     0.000   GOAL                   SET-BUFFER-CHUNK GOAL FREE NIL
     0.000   PROCEDURAL             CONFLICT-RESOLUTION
     0.050   PROCEDURAL             PRODUCTION-FIRED A
Production Compilation process started for A
  No previous production to compose with.
  Setting previous production to A.
     0.050   PROCEDURAL             CONFLICT-RESOLUTION
     0.100   PROCEDURAL             PRODUCTION-FIRED B
1
Production Compilation process started for B
  Production A and B are being composed.
  New production:

(P PRODUCTION0
  "A & B"
   !SAFE-BIND! =V (CAR (LIST 1))
   =GOAL>
       STATE NIL
   =IMAGINAL>
       SLOT1 COLOR
       SLOT2 COLOR
 ==>
   =IMAGINAL>
   =GOAL>
       COLOR =V
   !OUTPUT! =V
)
Parameters for production PRODUCTION0:
 :u   0.000
 :at  0.050
  Setting previous production to B.
     0.100   PROCEDURAL             CONFLICT-RESOLUTION
     0.150   PROCEDURAL             PRODUCTION-FIRED PRODUCTION0
1
Production Compilation process started for PRODUCTION0
  Production B and PRODUCTION0 are being composed.
  New production:

(P PRODUCTION1
  "B & PRODUCTION0"
   !SAFE-BIND! =V (CAR (LIST 1))
   =GOAL>
       COLOR =Y
       STATE NIL
   =IMAGINAL>
       SLOT1 COLOR
       SLOT2 COLOR
 ==>
   =IMAGINAL>
   =GOAL>
       COLOR =V
   !OUTPUT! =Y
   !OUTPUT! =V
)
Parameters for production PRODUCTION1:
 :u   0.000
 :at  0.050
  Setting previous production to PRODUCTION0.
     0.150   PROCEDURAL             CONFLICT-RESOLUTION
     0.200   PROCEDURAL             PRODUCTION-FIRED PRODUCTION1
1
1
Production Compilation process started for PRODUCTION1
  Production PRODUCTION0 and PRODUCTION1 are being composed.
#|Warning: No production defined for (PRODUCTION2 "PRODUCTION0 & PRODUCTION1" =GOAL> STATE NIL =IMAGINAL> SLOT1 COLOR SLOT2 COLOR !SAFE-BIND! =V0 (CAR (LIST 1)) ==> =IMAGINAL> =GOAL> COLOR =V0 !OUTPUT! =V !OUTPUT! =V0 !OUTPUT! =V0). |#
#|Warning: Variable =V, on the RHS, is not bound. |#
#|Warning: --- end of warnings for undefined production PRODUCTION2 --- |#
  Setting previous production to PRODUCTION1.
     0.200   PROCEDURAL             CONFLICT-RESOLUTION
     0.250   PROCEDURAL             PRODUCTION-FIRED PRODUCTION1
1
1
Production Compilation process started for PRODUCTION1
  Production PRODUCTION1 and PRODUCTION1 are being composed.
#|Warning: No production defined for (PRODUCTION3 "PRODUCTION1 & PRODUCTION1" =GOAL> COLOR =Y STATE NIL =IMAGINAL> SLOT1 COLOR SLOT2 COLOR !SAFE-BIND! =V1 (CAR (LIST 1)) ==> =IMAGINAL> =GOAL> COLOR =V1 !OUTPUT! =V !OUTPUT! =Y !OUTPUT! =V1 !OUTPUT! =V1). |#
#|Warning: Variable =V, on the RHS, is not bound. |#
#|Warning: --- end of warnings for undefined production PRODUCTION3 --- |#
  Setting previous production to PRODUCTION1.
     0.250   PROCEDURAL             CONFLICT-RESOLUTION
     0.300   PROCEDURAL             PRODUCTION-FIRED PRODUCTION1
1
1
Production Compilation process started for PRODUCTION1
  Production PRODUCTION1 and PRODUCTION1 are being composed.
#|Warning: No production defined for (PRODUCTION4 "PRODUCTION1 & PRODUCTION1" =GOAL> COLOR =Y STATE NIL =IMAGINAL> SLOT1 COLOR SLOT2 COLOR !SAFE-BIND! =V2 (CAR (LIST 1)) ==> =IMAGINAL> =GOAL> COLOR =V2 !OUTPUT! =V !OUTPUT! =Y !OUTPUT! =V2 !OUTPUT! =V2). |#
#|Warning: Variable =V, on the RHS, is not bound. |#
#|Warning: --- end of warnings for undefined production PRODUCTION4 --- |#
  Setting previous production to PRODUCTION1.
     0.300   PROCEDURAL             CONFLICT-RESOLUTION
     0.350   PROCEDURAL             PRODUCTION-FIRED PRODUCTION1
1
1

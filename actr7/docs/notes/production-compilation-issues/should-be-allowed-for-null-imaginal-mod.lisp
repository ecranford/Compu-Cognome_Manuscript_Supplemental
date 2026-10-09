
This example shows an oversight with respect to strict harvesting because
the null imaginal modification is only necessary for the next production
to fire which strict harvests the result.  That modification could be
dropped and have the same effect as the original two.

That change was made with r3104


CG-USER(25):  (define-model x
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
    !output! =y
    =goal>)

)
#|Warning: Extending chunks with slot named SLOT1 because of chunk definition (SLOT1 COLOR SLOT2 COLOR) |#
#|Warning: Extending chunks with slot named SLOT2 because of chunk definition (SLOT1 COLOR SLOT2 COLOR) |#
#|Warning: Creating chunk COLOR with no slots |#
#|Warning: Productions test the STATE slot in the GOAL buffer which is not requested or modified in any productions. |#
X
CG-USER(26): (run 1)
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
  Buffer IMAGINAL prevents composition of these productions
   because strict harvesting is enabled for the buffer and either the first production cleared the buffer or the combined production would leave the buffer with a chunk while the original pair would have left it empty.
  Production A and B cannot be composed.
  Setting previous production to B.
     0.100   PROCEDURAL             CLEAR-BUFFER IMAGINAL
     0.100   PROCEDURAL             CONFLICT-RESOLUTION
     0.100   ------                 Stopped because no events left to process
0.1
19
NIL
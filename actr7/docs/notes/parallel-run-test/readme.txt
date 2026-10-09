These files were changed to allow events to be run in separate
threads when possible (same time and priority and not flagged
as unsafe e.g. conflict-resolution).  There are two versions
in the scheduling code: one which just starts a new thread
each time (bad idea but easy test) and one which uses the
worker approach from the dispatcher.

The tutorial models showed that usually there's somewhere 
between 15 and 30 percent of the actions which have such
overlap, mostly from productions: LHS testing notifications
and RHS actions.  The thought was that by letting those
happen in parallel it would gain back some of the performance
loss from the dispatcher. 

However, it didn't work out for the primary test model
which was the tutorial unit 4 zbrodoff task.  It turns
out that running those events sequentially is faster
than doing so in parallel.  For the new thread approach
that was expected since thread creation is costly, but
even the condition variable notification for the worker
threads took longer.  Basically, the issue is that most
of the actions which can occur in parallel are so simple
that it's not worth the effort to actually do so.  Here
is some timing info from tests of the approaches:

This is before anything is updated:

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 391.234375 sec (00:06:31.234375) user, 19.343750 sec system
; cpu time (gc)     25.109375 sec user, 0.015625 sec system
; cpu time (total)  416.343750 sec (00:06:56.343750) user, 19.359375 sec system
; cpu time (thread) 337.781250 sec (00:05:37.781250) user, 7.406250 sec system
; real time  433.323000 sec (00:07:13.323000) (100.5%)
; space allocation:
;  412,699,827 cons cells, 2,410,909,720 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)


This is with the scheduling changes to group things
into sets that could be run in parallel, but still
running them sequentially:

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 391.953125 sec (00:06:31.953125) user, 21.890625 sec system
; cpu time (gc)     25.281250 sec user, 0.015625 sec system
; cpu time (total)  417.234375 sec (00:06:57.234375) user, 21.906250 sec system
; cpu time (thread) 338.046875 sec (00:05:38.46875) user, 8.750000 sec system
; real time  435.548000 sec (00:07:15.548000) (100.8%)
; space allocation:
;  420,611,088 cons cells, 2,714,310,336 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)


This is with the new thread approach (even worse than expected):

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 1732.500000 sec (00:28:52.500000) user, 1192.687500 sec (00:19:52.687500) system
; cpu time (gc)     66.906250 sec (00:01:06.906250) user, 0.343750 sec system
; cpu time (total)  1799.406250 sec (00:29:59.406250) user, 1193.031250 sec (00:19:53.31250) system
; cpu time (thread) 957.812500 sec (00:15:57.812500) user, 304.218750 sec (00:05:04.218750) system
; real time  1450.276000 sec (00:24:10.276000) (206.3%)
; space allocation:
;  826,437,503 cons cells, 456,781,056 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)


This is with the worker notifications:

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 607.703125 sec (00:10:07.703125) user, 126.875000 sec (00:02:06.875000) system
; cpu time (gc)     25.609375 sec user, 0.015625 sec system
; cpu time (total)  633.312500 sec (00:10:33.312500) user, 126.890625 sec (00:02:06.890625) system
; cpu time (thread) 396.703125 sec (00:06:36.703125) user, 39.312500 sec system
; real time  546.991000 sec (00:09:06.991000) (139.0%)
; space allocation:
;  430,953,773 cons cells, 2,892,430,776 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)


Given that, these changes weren't committed to the
main code, but I wanted to keep them around in case
I want to revisit these ideas in the future.
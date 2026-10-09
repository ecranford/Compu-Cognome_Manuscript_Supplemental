This is code changes which were made in an attempt to improve
the performance of accessing chunks.  The approach was to
store the chunk struct in the symbol-plist of the name for
faster access and just use the hash-table in the model as
an existence test (the first step was just the plist but
tests determined the hashtable was an improvement).  This
uses one lock for both the chunks and the table (because
testing found that two locks basically negated the benefits).

However, while this seemed to have a significant effect
on the perf-test models (roughly 10% faster for those 
that involved chunks) the performance on a real model,
zbrodoff from the tutorial, showed some improvement in
ACL but actually a decrease in performance in CCL which
presumably reflects differences in how the symbol-plist
mechanisms are implemented.  

Therefore, the change isn't going to be made to the system,
but the code is being kept here for reference incase I
want to come back to something like that in the future
in an attempt to improve performance.


----------------------------------------------------------------

9/7/2018 r2679

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 399.390625 sec (00:06:39.390625) user, 20.859375 sec system
; cpu time (gc)     25.640625 sec user, 0.000000 sec system
; cpu time (total)  425.031250 sec (00:07:05.31250) user, 20.859375 sec system
; cpu time (thread) 344.156250 sec (00:05:44.156250) user, 8.000000 sec system
; real time  445.018000 sec (00:07:25.18000) (100.2%)
; space allocation:
;  412,700,323 cons cells, 2,410,962,432 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)


;;; switching chunks to using the symbol-plist instead of a 
;;; hash-table didn't help (eventhough it does improve the perf-tests)

CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 437.875000 sec (00:07:17.875000) user, 21.015625 sec system
; cpu time (gc)     43.750000 sec user, 0.031250 sec system
; cpu time (total)  481.625000 sec (00:08:01.625000) user, 21.046875 sec system
; cpu time (thread) 386.187500 sec (00:06:26.187500) user, 8.375000 sec system
; real time  498.813000 sec (00:08:18.813000) (100.8%)
; space allocation:
;  1,737,358,549 cons cells, 2,420,568,480 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)

;; Here's the combo -- a hash-table in the model for existence
;; and the symbol-plist for 'getting' the chunk with a single
;; global lock for both accesses i.e. multiple models would have
;; to block but not really an issue in general since the events
;; aren't threaded...


CG-USER(1): (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
; cpu time (non-gc) 381.328125 sec (00:06:21.328125) user, 20.687500 sec system
; cpu time (gc)     32.078125 sec user, 0.000000 sec system
; cpu time (total)  413.406250 sec (00:06:53.406250) user, 20.687500 sec system
; cpu time (thread) 326.093750 sec (00:05:26.93750) user, 8.546875 sec system
; real time  430.674000 sec (00:07:10.674000) (100.8%)
; space allocation:
;  420,534,577 cons cells, 2,412,105,096 other bytes, 0 static bytes
; Page Faults: major: 0 (gc: 0), minor: 0 (gc: 0)
NIL



;;; here's ccl with the base 2679

? (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
(ZBRODOFF-COMPARE 100)
took 399,408,000 microseconds (399.408000 seconds) to run.
      30,748,375 microseconds ( 30.748375 seconds, 7.70%) of which was spent in GC.
During that period, and with 8 available CPU cores,
     371,812,500 microseconds (371.812500 seconds) were spent in user mode
      21,578,125 microseconds ( 21.578125 seconds) were spent in system mode
 27,312,344,656 bytes of memory allocated.
NIL

here it is with the plist change


? (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
(ZBRODOFF-COMPARE 100)
took 530,440,000 microseconds (530.440000 seconds) to run.
      73,372,845 microseconds ( 73.372850 seconds, 13.83%) of which was spent in GC.
During that period, and with 8 available CPU cores,
     492,125,000 microseconds (492.125000 seconds) were spent in user mode
      25,843,750 microseconds ( 25.843750 seconds) were spent in system mode
117,108,484,208 bytes of memory allocated.

;; here's the combo change

? (time (zbrodoff-compare 100))
CORRELATION:  0.978
MEAN DEVIATION:  0.153

              2 (64)      3 (64)      4 (64)
Block  1  1.953 (64)  2.175 (64)  2.659 (64)
Block  2  1.362 (64)  1.402 (64)  1.543 (64)
Block  3  1.357 (64)  1.183 (64)  1.225 (64)
(ZBRODOFF-COMPARE 100)
took 410,157,000 microseconds (410.157000 seconds) to run.
      35,764,240 microseconds ( 35.764240 seconds, 8.72%) of which was spent in GC.
During that period, and with 8 available CPU cores,
     383,781,250 microseconds (383.781250 seconds) were spent in user mode
      20,546,875 microseconds ( 20.546875 seconds) were spent in system mode
 27,410,584,512 bytes of memory allocated.
NIL
?
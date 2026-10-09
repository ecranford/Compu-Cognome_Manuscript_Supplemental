;;; model to perform n-back condition of the Human Connectome Project working memory task


(clear-all)

(define-model nBack-HCP_WM
    
    ;;;HERE NEED TO ADD AN sgp-fct to set any parameters that will change between runs
    (sgp-fct (list
              :iu      *iu* 
	      
              :fpbmc   *fpbmc*
              :fpmc    *fpmc* 
              
              :utbmc   *utbmc*
              :utmc    *utmc*
              :ut0     *ut0*
	      
              :hour    *hour*            
              :dat     *dat*
              :fp-dec  *fp-dec*
              
              :egs     *egs* ;SCJ added because we expected EGS to be a possible mechanism of fatigue action
	      
	      ;;parameters for declarative mechanisms  ::: DO WE NEED TO CHANGE ALL OF THESE??? :::
	      :fdc     *fdc*
	      :fdbmc   *fdbmc*
	      :fd-dec  *fd-dec*

	      :blc     1.0           ;; default: 0
	      :rt      0.0           ;; default: 0
	      ;;:min-bl  -0.5          ;; default: nil
	      :mp      *mp*
	      :md      *md*
	      :bll     *bll*
	      ;;:tmp     nil
	      :mas     nil;*mas*
	      :ans     *ans*
	      :ga      0;*ga*
	      :imaginal-activation 0;*ia*
	      :lf      *lf*
	      :ol      nil
	      :ul      nil;t           ;; default: nil ;;need to test that this works with fatigue module
	      :alpha   0.2         ;; default: 0.2
              ))
  ;;(sgp-fct (list :ppm (* (car (no-output (sgp :iu))) 2)))
  
  (sgp :v                        nil
       :trace-detail 		 high
       :style-warnings           nil
       :model-warnings           nil
       ;;:blt                      t
       ;;:auto-attend  		 t
       :show-focus               t
       ;;:mp           		 1
       :er                       t  ;;pvt uses this to ensure the model operates non-deterministically
       :esc		   	 t
       :randomize-time           t  ;;pvt uses this to enable randomization to the amount of time it takes for a module to process. default = 3, which adds +/- 1/3*time to total time
       :vpft                     t  ;;pvt uses this to randomize the production firing time
       :record-ticks             t
       :time-master-start-increment 1.0
       :time-mult                1.0
       ;;:bll			 0.5
       ;;:mas			 1.0
       ;;:ans                      0.2
       ;;:ga			 1.0
       ;;:imaginal-activation      1.0
       :nsji			 nil
       ;;:nsji		     t
       ;;:sji-hook                 linear-activation-spread
       ;;:retrieved-chunk-hook     record-retrieved-chunk
       :sim-hook                 linear-similarity
       ;;:enable-inhibition        nil
       ;;:inhibition-decay         0.75
       ;;:inhibition-scale         5
       ;;:rt                       -3.0
       ;;:lf		   	 1.5
       ;;:ol			   nil
       ;;:imaginal-delay	   0.2
       ;;:declarative-num-finsts   3
       ;;:visual-onset-span	   0.25
       :UNSTUFF-VISUAL-LOCATION nil  ;;;pvt uses this so that if a lapse occurs between a stimulus presentation and encoding it then then it will be maintained and not lost. But need to ensure that the visual-location is explicitly cleared between trials so that the new stimulus replaces the old one in case the model lapses for an entire trial or more.
       )
  
;;; declare chunk-types for:
;;; a chunk to represent the task goal 
;;; chunks to represent cues and stimuli
;;; a chunk to represent "the self" - for the interrupt-long-retrieval production
  (chunk-type parse-item state stage nback seen position target trial)
  (chunk-type item kind item position block trial)
  (chunk-type self identity)
  (chunk-type number value prev next)

;;; declare stimulus and cue chunk-types for visicon-update in the device
  (chunk-type (stimulus
               (:include visual-object))
              item kind block trial)
  (chunk-type (cue (:include stimulus))
              nback)
  (chunk-type stimulus-window one two three)

;;; declare blank chunk-type for ITI
  (chunk-type (blank (:include visual-object))
	      test)

;;; number chunks
  #|
(add-dm
 (n0 isa number value 0 prev -1 next 1)
 (n1 isa number value 1 prev 0 next 2)
 (n2 isa number value 2 prev 1 next 3)
 (n3 isa number value 3 prev 2 next 4))

 ;;; set number chunk reference-counts to arbitrarily high value to make them available
(sdp n0 :reference-count 10000)
(sdp n1 :reference-count 10000)
(sdp n2 :reference-count 10000)
(sdp n3 :reference-count 10000)
|#
  
;;;PARSING;;;
  
  (p find-nb-cue
     =goal>
       ISA              parse-item
       state            start
     ?visual>
       state            free
       buffer           empty
     ?temporal>
       state            free
     ;;?visual-location>
     ;;  buffer           empty
   ==>
     +visual-location>
       :attended        nil
       screen-y         highest    ;;added this to ensure it is the nback cue we are looking for
       ;;kind             cue
       ;;- kind		nil
     +temporal>
       ISA              time
       ticks            0
     =goal>
       state		attend-cue
   )

  (p attend-nb-cue-info
     =goal>
       ISA              parse-item
       state            attend-cue
     =visual-location>
       > screen-y       206        ;;added this to ensure it is the nback cue we are looking for
       ;;kind             cue
     ?visual>
       state            free
       buffer           empty
   ==>
     +visual>
       cmd         move-attention
       screen-pos  =visual-location
     =goal>
       state            parse-cue
   )
  
  (P parse-nb-cue-info
     =goal>
       ISA              parse-item
       state		parse-cue
     =visual>
       value		=nback
       ;;item		nil
     ;;!bind! =nback-num (read-from-string =nback)
     ;;!bind! =pos (1- =nback)
   ==>
     =visual>
     =goal>
       state		wait
       nback		=nback ;;=nback-num
       seen             "0"
       ;;target           nil
       ;;position         =pos ;;set initial start point
   )

  (P wait-after-nb-cue
     =goal>
       ISA		parse-item
       state		wait
     ?visual>
       buffer		full
       state            free
     =visual>
       ;;kind		cue
   ==>
     +visual>           ISA clear
     -imaginal>
     -retrieval>
     =goal>
       state		parse
   )

  ;;do we need this production anymore if we don't have categories
  ;;updated to just parse first stim and go immediately to initializing update window
  #|(P parse-first-stim-presence
     =goal>
       ISA              parse-item
       state		parse
       see
     ?visual>
       scene-change     t
     =visual>
       - item		nil
       item             =item
     ?imaginal>
       buffer           empty
     ?retrieval>
       buffer		empty
       - state		busy
   ==>
     !eval! (collect-imaginal-slots)
     !eval! (collect-retrieval-slots)
     =visual>
       position         0
     +imaginal>
       ISA              item
       item             =item
       position         0
     =goal>
       state	        update
       
   )|#

  ;;this can fire at same time as parse-first-stim-presence to try to retrieve something
  ;;NEED THIS TO JUST ATTEND LETTER AND ADD IT TO VISUAL BUFFER AND PROBABLY ANOTHER PRODUCTION TO UPDATE IMAGINAL BUFFER AND SET GOAL TO COMPARE ONCE A TARGET HAS BEEN SET AND/OR UPDATING HAS FINISHED
  (p find-stim
     =goal>
       ISA              parse-item
       state            parse
     ?visual>
       state            free
       buffer           empty
     =visual-location>
       > screen-y       206          ;;only fires if we are currently NOT at the stimulus location
       ;;- kind           stimulus
   ==>
     +visual-location>
       ;;:attended        new
       screen-y         lowest        ;;finds item highest on screen (which is the stimulus)
       ;;kind             stimulus
       ;;- kind		nil 
     =goal>
       state		parse
   )

  (p attend-stim
     =goal>
       ISA              parse-item
       state            parse
     ?visual>
       state            free
       buffer           empty
     =visual-location>
       < screen-y         356       ;;item must be the highest on the screen (which is the stimulus)
       ;;:attended        new
       ;;kind             stimulus
   ==>
     +visual>
       cmd         move-attention
       screen-pos  =visual-location
     =goal>
   ) ;;(spp (attend-stim :at 0.486))  ;;used for testing

  (p missed-stim
     =goal>
       ISA              parse-item
       state            parse
       nback            =nback
     ?visual>
       state            error
       buffer           failure
     =temporal>
       ticks            =tick
     ?imaginal>
       state		free
       ;;buffer           empty
     ;;!bind! =next-seen (min =nback (1+ =seen))
   ==>
     -retrieval>  ;;clear retrieval to free buffer after parsing (mostly for after breaking rehearsals on new stim)
     -imaginal>
     +visual>
       cmd              clear
     +imaginal>
       ISA              item
       item             "none"
       block            =nback ;;=block
       trial            =tick  ;;=trial
       position         0
     =goal>
       state	        compare
       trial            =tick
     ;;  seen             =next-seen
   )
  
  (P parse-stim-presence
     =goal>
       ISA              parse-item
       ;;- lastitem	nothing
       state		parse
       ;;seen             =seen
       nback            =nback
     ;;?visual>
     ;;  scene-change     t   ;;;;should probably let this fire even after scene-change has expired, to allow for delayed processing of stim
     =visual>
       - value          nil
       value            =item
       ;;- item		nil
       ;;item             =item
       ;;- value          "blank"
       ;;block            =block
       ;;trial            =trial
     =temporal>
       ticks            =tick
     ?imaginal>
       state		free
       ;;buffer           empty
     ;;!bind! =next-seen (min =nback (1+ =seen))
   ==>
     -retrieval>  ;;clear retrieval to free buffer after parsing (mostly for after breaking rehearsals on new stim)
     -imaginal>
     ;;=visual>
     +visual>
       cmd              clear
     ;;  position         0
     ;;-visual>
     +vocal>
       cmd              subvocalize
       string           =item
     +imaginal>
       ISA              item
       item             =item
       block            =nback ;;=block
       trial            =tick  ;;=trial
       position         0
     =goal>
       state	        compare
       trial            =tick
     ;;  seen             =next-seen
   )

  #|
  (P encode-stim
     =goal>
       ISA              parse-item
       state            parse
     =visual>
       - item		nil
       item             =item
       block            =block
       trial            =trial
     =imaginal>
       item             =item
       block            =block
       trial            =trial
   ==>
     =visual>
     -imaginal>
     =goal>
       state            compare
  )
  |#
#|
  (P update-seen
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =seen
       < seen           =nback
     ?retrieval>
       state            free
       buffer           empty
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     +retrieval>
       ISA              number
       value            =seen
     =goal>
       state            initialize
   )
  |#
 #| 
  (P initialize-list
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =seen
       < seen           =nback
     ?visual>
       buffer           empty
     ;;=visual>
     ;;  item             nil
     ;;  value            "blank"
     ?imaginal>
       buffer           full
     =imaginal>
       - item           nil ;;  =item
       - block          nil ;;  =block
       - trial          nil ;;  =trial
     ;;=retrieval>
     ;;  ISA              number
     ;;  value            =seen
     ;;  next             =next
     !bind! =pos (- =nback =seen)
     !bind! =next (1+ =seen)
     ;;!bind! =block (session-block *task*)
     ;;!bind! =trial (bt-index *task*)
   ==>
     ;;=visual>
     =imaginal>
       position         =pos
     =goal>
       state            parse ;;initialize
       seen             =next
   )

  (P initialize-target
     =goal>
       ISA              parse-item
       state            parse ;;initialize
       target           nil
       seen             1
     =imaginal>
       item             =item
   ==>
     =imaginal>
     =goal>
       target           =item
   )
  |#
  
  (P update-seen-no-compare
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =seen
       - seen           =nback
     ?imaginal>
       buffer           full
     !bind! =next (write-to-string (1+ (read-from-string =seen)))
   ==>
     =goal>
       state            update
       seen             =next
   )

  ;;Probably don't want to break stim retrieval on iti because they can still respond during the ITI
  ;;want to collect-no-response after ITI right when interrupted with new letter stim
  ;;(P break-nback-stim-retrieval-on-iti
  ;;   =goal>
  ;;     stage		interact
  ;;   ?retrieval>
  ;;     state		busy
  ;;   ?visual>
  ;;     state		busy
  ;;     scene-change     t
  ;;   =visual>
  ;;     - item		nil
  ;; ==>
  ;;   !eval! (collect-no-response)
  ;;   =visual>
  ;;   +retrieval>
  ;;     :rt-value	10
  ;;     :mp-value	nil
  ;;     ISA		self
  ;;     identity	        other
  ;;   =goal>
  ;;     count		nil
  ;;     stage		interact
  ;;     state		parse
  ;;)

;;;RESPONSE;;;

  ;;May need to remove this production....don't want the model pressing a button when there is no stimulus
  ;;Removed and collapsed with production to parse initial stimulus
  ;;(P respond-for-no-stimulus-window
  ;;   =goal>
  ;;     ISA		parse-item
  ;;     state		compare
  ;;   ;;?manual>
  ;;   ;;  state		free
  ;;   ?retrieval>
  ;;     buffer		empty
  ;;     - state		busy
  ;; ==>
  ;;   !eval! (collect-imaginal-slots)
  ;;   !eval! (collect-retrieval-slots)
  ;;   ;;+manual>
  ;;   ;;  ISA		motor-command
  ;;   ;;  cmd		punch
  ;;   ;;  hand		right
  ;;   ;;  finger		index
  ;;   =goal>
  ;;     state		initialize-update  
  ;; )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  #|
  ;;;compare visual stimulus to target
  ;;;need to change this to only respond to matches, and also need to handle non-responses
  (P compare-vis-stimulus-to-target-match
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =visual>
       item		=item
     ?imaginal>
       buffer           full
     ;;?retrieval>
     ;;  - state		busy
     ?manual>
       state		free
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     =visual>
     ;;-imaginal>
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
   )
  (spp (compare-vis-stimulus-to-target-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-vis-stimulus-to-target-mismatch
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =visual>
       - item		=item
     ?imaginal>
       buffer           full
     ;;?manual>
     ;;  state		free
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     =visual>
     ;;-imaginal>
     ;;+manual>
     ;;  ISA		motor-command
     ;;  cmd		punch
     ;;  hand		right
     ;;  finger		index
     =goal>
       state		update
   )
  (spp (compare-vis-stimulus-to-target-mismatch :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  ;;;compare imaginal stimulus to target
  (P compare-imaginal-stimulus-to-target-match
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =imaginal>
       item		=item
     ?imaginal>
       buffer           full
     ;;?retrieval>
     ;;  - state		busy
     ?manual>
       state		free
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =imaginal>
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
   )
  (spp (compare-imaginal-stimulus-to-target-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-imaginal-stimulus-to-target-mismatch
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =imaginal>
       - item		=item
     ?imaginal>
       buffer           full
     ;;?manual>
     ;;  state		free
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     ;;+manual>
     ;;  ISA		motor-command
     ;;  cmd		punch
     ;;  hand		right
     ;;  finger		index
     =imaginal>
     =goal>
       state		update
   )
  (spp (compare-imaginal-stimulus-to-target-mismatch :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  ;;If no visual info anymore (i.e., during blank screen), and no item in imaginal buffer, need to retrieve the last seen item, then compare
  (P retrieve-last-seen  ;;; THIS ONE MAY END UP RETRIEVING THE MOST COMMONLY SEEN LETTER DUE TO MERGING INSTEAD OF THE LAST SEEEN LETTER
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
     ?visual>
       buffer           empty
     ;;=visual>
     ;;  value		"blank"
     ?imaginal>
       buffer           empty      ;;;May want to check that the buffer is not requested or state is free, just to wait for it to finish processing if it is doing so...i.e., only run this production if we somehow failed to encode the chunk from the visual buffer to the imaginal and the visual buffer has been cleared.
       state            free
     ?retrieval>
       state            free
   ==>
     +retrieval>
       - value          nil
       - value          text        ;;;MAKE SURE TO RETRIEVE A VISUAL OBJECT, NOT A LOCATION
       kind             nil
       ;;kind             stimulus
     =goal>
     )

  (P compare-retrieved-stimulus-to-target-match
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =retrieval>
       value		=item
       ;;kind             stimulus
       ;;- kind           nil
       ;;position         nil
     ?manual>
       state		free
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     @retrieval> ;; do not harvest retrieved visual chunk
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
   )
  (spp (compare-retrieved-stimulus-to-target-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-retrieved-stimulus-to-target-mismatch
     =goal>
       ISA		parse-item
       state		compare
       - target         nil
       target           =item
       nback            =nback
       seen             =nback
     =retrieval>
       value		=item
       ;;- item		=item
       ;;kind             stimulus
       ;;- kind           nil
       ;;position         nil
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     @retrieval> ;; do not harvest retrieved visual chunk
     =goal>
       state		update
   )
  (spp (compare-retrieved-stimulus-to-target-mismatch :reward 5)) ;;reward of 5 means it should max out at about u=3
  
;;;IF NO TARGET AT COMPARE STEP NEED TO FIRST RETRIEVE THE TARGET
  (P retrieve-target-for-compare
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       target           nil
     ?retrieval>
       state            free
       buffer           empty
       ;;- state          error
   ==>
     +retrieval>
       position         =nback
       block            =nback
     =goal>
     )

  (P encode-target-for-compare
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       target           nil
     =retrieval>
       ;;position         =nback
       item             =item
   ==>
     =goal>
       target           =item
   )

  (P fail-retrieve-target-for-compare
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       ;;target           nil       ;;;probably just want to let this fire when a retrieval failure occurs during compare for anything, e.g., also for tyring to retrieve the last seen item
     ?retrieval>
       buffer           failure
   ==>
     =goal>
       state            update
   ) ;;;Do we want a negative reward here so that it learns to do strategies that do not result in retrieval failures?

  ;;;AFTER RETRIEVAL FAILURE, COULD POSSIBLY RESPOND RANDOMLY INSTEAD OF NOT RESPOND?
  |#
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 #| 
;;;BLENDING RETRIEVAL OF TARGET
  (P blend-retrieve-item
     =goal>
     ISA              parse-item
     state            compare
     nback            =nback
     seen             =nback
     ;;=imaginal>
     ;;item             =item
     ;;block            =nback ;;=block
     ;;trial            =tick  ;;=trial
     ;;position         0
     ?blending>
     buffer           empty
     state            free
     !bind! =nback-num (read-from-string =nback)
     ==>
     +blending>
     block            =nback
     position         =nback-num
     - trial          nil
     :ignore-slots (trial)
     ;;=imaginal>
     =goal>
     )

  ;;;compare imaginal stimulus to blending
  (P compare-imaginal-stimulus-to-blending-match
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
     =blending>
       item             =item
     =imaginal>
       item		=item
     ?imaginal>
       buffer           full
     ;;?retrieval>
     ;;  - state		busy
     ?manual>
       state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =imaginal>
     =blending>
       position         =pos
     -blending>
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
   )
  (spp (compare-imaginal-stimulus-to-blending-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-imaginal-stimulus-to-blending-mismatch
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
     =blending>
       item             =item
     =imaginal>
       - item		=item
     ?imaginal>
       buffer           full
     ;;?manual>
     ;;  state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =blending>
       position         =pos
     -blending>
     ;;+manual>
     ;;  ISA		motor-command
     ;;  cmd		punch
     ;;  hand		right
     ;;  finger		index
     =imaginal>
     =goal>
       state		update
   )
  (spp (compare-imaginal-stimulus-to-blending-mismatch :reward 5)) ;;reward of 5 means it should max out at about u=3

  (P fail-blending-target-for-compare
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       ;;target           nil       ;;;probably just want to let this fire when a retrieval failure occurs during compare for anything, e.g., also for tyring to retrieve the last seen item
     ?blending>
       buffer           failure
   ==>
     =goal>
       state            update
   ) ;;;Do we want a negative reward here so that it learns to do strategies that do not result in retrieval failures?
|#

;;;RETRIEVE TARGET
  
  (P retrieve-item
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =nback
       position         nil
       target           nil
     ;;=imaginal>
       ;;item             =item
       ;;block            =nback ;;=block
       ;;trial            =tick  ;;=trial
       ;;position         0
     ?retrieval>
       buffer           empty
       state            free
     !bind! =nback-num (read-from-string =nback)
     !bind! =next-pos (1- (read-from-string =nback))
   ==>
     +retrieval>
       block            =nback
       position         =nback-num
     ;;=imaginal>
     =goal>
       position         =next-pos
  )

  (P retrieve-next-item-set-target
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =nback
       > position       0
       position         =pos
       target           nil
     ;;=imaginal>
       ;;item             =item
       ;;block            =nback ;;=block
       ;;trial            =tick  ;;=trial
       ;;position         0
     =retrieval>
       item             =item
     !bind! =next-pos (1- =pos)
   ==>
     @retrieval>
     +retrieval>
       block            =nback
       position         =pos
     ;;=imaginal>
     =goal>
       target           =item
       position         =next-pos
   )

  (P retrieve-next-item-target-set
     =goal>
       ISA              parse-item
       state            compare
       nback            =nback
       seen             =nback
       > position       0
       position         =pos
       - target         nil
     ;;=imaginal>
       ;;item             =item
       ;;block            =nback ;;=block
       ;;trial            =tick  ;;=trial
       ;;position         0
     ?retrieval>
       buffer           full
     !bind! =next-pos (1- =pos)
   ==>
     @retrieval>
     +retrieval>
       block            =nback
       position         =pos
     ;;=imaginal>
     =goal>
       position         =next-pos
   )

  
;;;compare imaginal stimulus to retrieval
  (P compare-imaginal-stimulus-to-retrieval-match
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       trial            =trial
       target           nil
       position         0
     =retrieval>
       item             =item
     =imaginal>
       item		=item
     ?imaginal>
       buffer           full
     ;;?retrieval>
     ;;  - state		busy
     ?manual>
       state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =imaginal>
     =retrieval>
       position         =pos
       trial            =trial
     -retrieval>
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
       position         nil
       target           nil
   )
  ;;(spp (compare-imaginal-stimulus-to-retrieval-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-imaginal-stimulus-to-retrieval-mismatch
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       trial            =trial
       target           nil
       position         0
     =retrieval>
       item             =item
     =imaginal>
       - item		=item
     ?imaginal>
       buffer           full
     ;;?manual>
     ;;  state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =retrieval>
       position         =pos
       trial            =trial
     -retrieval>
     ;;+manual>
     ;;  ISA		motor-command
     ;;  cmd		punch
     ;;  hand		right
     ;;  finger		index
     =imaginal>
     =goal>
       state		update
       position         nil
       target           nil
   )
  ;;(spp (compare-imaginal-stimulus-to-retrieval-mismatch :reward 5)) ;;reward of 5 means it should max out at about u=3

  (P compare-imaginal-stimulus-to-target-match
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       trial            =trial
       - target         nil
       target           =item
       position         0
     =imaginal>
       item		=item
     ?imaginal>
       buffer           full
     =retrieval>
       - item           nil
     ;;?retrieval>
     ;;  - state		busy
     ?manual>
       state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =imaginal>
     =retrieval>
       item             =item 
       position         =pos
       block            =nback
       trial            =trial
     -retrieval>
     +manual>
       ISA		motor-command
       cmd		punch
       hand		left
       finger		index
     =goal>
       state		update
       position         nil
       target            nil
   )
  ;;(spp (compare-imaginal-stimulus-to-retrieval-match :reward 5)) ;;reward of 5 means it should max out at about u=3
  
  (P compare-imaginal-stimulus-to-target-mismatch
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       trial            =trial
       - target         nil
       target           =item
       position         0
     =imaginal>
       - item		=item
     ?imaginal>
       buffer           full
     =retrieval>
       - item           nil
     ;;?manual>
     ;;  state		free
     !bind! =pos (1+ (read-from-string =nback))
   ==>
     ;;!eval! (collect-imaginal-slots)
     ;;!eval! (collect-retrieval-slots)
     ;;-imaginal>
     =retrieval>
       item             =item 
       position         =pos
       block            =nback
       trial            =trial
     -retrieval>
     ;;+manual>
     ;;  ISA		motor-command
     ;;  cmd		punch
     ;;  hand		right
     ;;  finger		index
     =imaginal>
     =goal>
       state		update
       position         nil
       target           nil
   )
  
  (P fail-retrieval-target-for-compare
     =goal>
       ISA		parse-item
       state		compare
       nback            =nback
       seen             =nback
       ;;target           nil       ;;;probably just want to let this fire when a retrieval failure occurs during compare for anything, e.g., also for tyring to retrieve the last seen item
     ?retrieval>
       buffer           failure
   ==>
     =goal>
       state            update
       position         nil
       target           nil
   ) ;;;Do we want a negative reward here so that it learns to do strategies that do not result in retrieval failures?


  ;;;;IF ITEM IS "NONE", then we should guess sometimes??
  
;;;UPDATE (NEW);;;

  (P initialize-update ;;;need to start this as soon as we've made a response decision, no need to wait (also allow to start at start of new trial;;; but at least wait for imaginal buffer to have something in it
     =goal>
       ISA		parse-item
       state	        update
       ;;nback		=nback
       seen             =seen ;;=nback   ;;;trying to remove initialize-update procedures and just update stuff here, start with seen item
       position         nil ;;< 0
     ;;=visual>
     ;;  value            "blank"
     ?imaginal>                          
       buffer           full
     ;;?retrieval>                       ;;;don't worry about checking retrieval buffer, in case something got lodged in there somehow
     ;;  buffer           empty
     ;;  state		free
     ?manual>
       state            free
     ?vocal>
       state            free
     ;;!bind! =start-pos (1- =nback)
     !bind! =pos (read-from-string =seen)
   ==>
     -imaginal>          ;;;if a chunk is in the imaginal buffer, harvest it (should be the chunk from visual buffer); must be done in order to retrieve item for update 
     @retrieval>         ;;;if something is in the retrieval buffer just remove it, do not harvest
     =goal>
       position         =pos ;;=seen
       ;;target           nil
     )
  
  (P retrieve-item-update
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       ;;seen             =seen
       position         =pos
       > position       0
     ?retrieval>
       buffer           empty
       state		free
     ?imaginal>
     ;;  buffer           empty
       state            free
     ?vocal>
       state            free
     !bind! =next-pos   (1- =pos)
     ;;!bind! =block (1- =nback)
   ==>
     ;;-imaginal>  ;;don't harvest any chunks here, just wait for imaginal to harvest itself; that way just retrieved item doesn't interfere with next
     +retrieval>
       position		=next-pos
       block            =nback
       ;;- trial          nil  ;; maybe, if using blending, want to make sure we only retrieve from items that have a trial (timestamp) slot ;;could even consider matching on this value to partially match to current time ...either currrent time or could keep track of a trial timestamp in goal buffer.
       ;;:recently-retrieved nil
     =goal>
       ;;position         =next-pos
     )
#|
  (P retrieve-first-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       position         =pos
       >= position       0
       target           nil
     ?retrieval>
       buffer           empty
       state		free
     ?imaginal>
       buffer           empty
       state            free
     ;;!bind! =block (1- =nback)
   ==>
     -imaginal>
     +retrieval>
       position		=pos
       block            =nback
     =goal>
       target           nil
     );;;Need to handle retrieval failure...
  |#

  (P update-item-and-subvocalize
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       ;;seen             =nback
       position         =pos
       trial            =trial
     =retrieval>
       - item           nil
       item             =item
       ;;- position       =nback
       ;;position         =pos
       ;;block            =block
       ;;trial            =trial
     ?imaginal>
       state            free
       ;;buffer           empty
     ?vocal>
       state            free
     !bind! =next-pos (1- =pos)
     ;;!bind! =update-pos (1+ =pos)
     ;;!bind! =block (1- =nback)
   ==>
     !eval! (collect-retrieved-item =pos)
     ;;@retrieval>  ;;may want to @ this to prevent things from getting out of control ;;;MAY WANT TO TURN THIS BACK ON TO REHEARSE ITEMS, SHOULD BE FINE NOW THAT THEY ARE UNIQUE CHUNKS;;;ACTUALLY PROBABLY IMPORTANT SO OLD POSITIONS DON'T GET REINFORCED;;;IN ESSENCE WE ARE UPDATING A CURRENT CHUNK NOT A PAST CHUNK
     =retrieval>                   ;; Mulling - add an extra reference by modifying the retrieval buffer before harvesting so that it matches imaginal chunk
       position         =pos
       block            =nback
       trial            =trial
     -retrieval>
     +vocal>
       cmd              subvocalize
       string           =item
     +imaginal>
       item             =item
       position         =pos
       block            =nback ;;;PROBABLY DON'T WANT TO MAKE THIS THE BLOCK OF THE RETRIEVED ITEM, BUT THE ACTUAL BLOCK?
       trial            =trial
     =goal>
       position         =next-pos
   )

  (P fail-retrieve-item
     =goal>
       ISA		parse-item
       state	        update
       ;;nback		=nback
       ;;seen             =nback
       position         =pos
       ;;target           =target
     ?retrieval>
       buffer           failure
     !bind! =next-pos (1- =pos)
     ;;!bind! =targ (if =target =target 'none)
   ==>
     -retrieval>
     =goal>
       ;;target           =targ ;;nil?
       position         =next-pos
     )
#|
  (P update-new-target
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       target           nil
     =imaginal>
       item             =item
       position         =nback
   ==>
     =imaginal>
     =goal>
       target           =item
     )
|#
#|
  (P retrieve-next-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       position         =pos
       > position       0
       - target         nil
     ;;=imaginal>
     ;;  - position       =pos
     ;;  - position       nil
     ?retrieval>
       buffer           empty
       state		free
     !bind! =next-pos   (1- =pos)
     !bind! =block (1- =nback)
   ==>
     -imaginal>
     +retrieval>
       position		=next-pos
       block            =block
     =goal>
       position         =next-pos
     ) ;;;Need to handle retrieval failure...
|#
  (P end-update
     =goal>
       ISA		parse-item
       state	        update
       ;;nback		=nback
       ;;seen             =nback
       position         =pos
       position         0
       ;;- target         nil
     =imaginal>
       - position       =pos
       - position       nil
     ?retrieval>
       buffer           empty
       state		free
     ;;!bind! =next-pos   (1- =pos)
   ==>
     -imaginal> ;;just let imaginal buffer harvest itself later;; wasn't working, too active, harvest now.
     =goal>
       state            parse
       position         nil ;;=next-pos
     )


  ;;;COULD START REHEARSAL LOOPS HERE AFTER OR AS A RESULT OF ENDING THE UPDATE
  ;;;COULD INVOLVE A WAIT PRODUCTION SO IT IS NOT JUST CONSTANT REHEARSAL LOOPS
  ;;;NEED TO CONSIDER WHETHER IT REINFORCES CHUNKS .... PROBABLY SHOULD, I THINK IT'S FINE ... YES, DO
  ;;;DEFINITELY NEED TO REHEARSE ITEMS IF WE DON'T TAG A TARGET
#|
;;;REHEARSAL;;;
  ;;want to rehearse if done updating and have time for rehearsal, i.e., no item in window
  ;;should be an optional process though and more necessary if we don't have tag a target during the update...may require utility learning
  (P wait-to-rehearse
     =goal>
       ISA		parse-item
       state	        parse
       - seen           "0"
       ;;> seen           0
       position         nil
       ;;< position       0
     ?retrieval>
       buffer           empty
       state		free
     ?imaginal>
       buffer           empty
       state            free
     ?visual>
       buffer           empty
       state            free
     ?visual-location>
       buffer           empty
     ?vocal>
       state            free
   ==>
     =goal>
   )
  
  (P initialize-rehearsal
     =goal>
       ISA		parse-item
       state	        parse
       seen             =seen
       - seen           "0"
       ;;> seen           0
       position         nil
       ;;< position       0
     ?retrieval>
       buffer           empty
       state		free
     ?imaginal>
       buffer           empty
       state            free
     ?visual>
       buffer           empty
       state            free
     ?visual-location>
       buffer           empty
     ?vocal>
       state            free
     !bind! =pos (read-from-string =seen)
   ==>
     =goal>
       state            rehearse
       position         =pos ;;=seen
   )


  (P retrieve-item-rehearsal
     =goal>
       ISA              parse-item
       state            rehearse
       nback            =nback
       position         =pos
       > position       0
     ?retrieval>
       state		free
       buffer           empty
     ?imaginal>
       buffer           empty
       state            free
     ?visual>
       buffer           empty
     ?visual-location>
       buffer           empty
     ?vocal>
       state            free
     !bind! =next-pos (1- =pos)
   ==>
     +retrieval>
       position         =pos
       block            =nback
       - trial          nil
     =goal>
       position         =next-pos
   )

  (P subvocalize-item-rehearsal
     =goal>
       ISA              parse-item
       state            rehearse
       ;;nback            =nback
       ;;position         =pos
       ;;> position       0
     =retrieval>
       item             =item
     ?imaginal>
       buffer           empty
       state            free
     ?visual>
       buffer           empty
     ?visual-location>
       buffer           empty
     ?vocal>
       state            free
   ==>
     -retrieval>
     +vocal>
       cmd              subvocalize
       string           =item
     =goal>
   )

  (P fail-retrieve-item-rehearsal
     =goal>
       ISA		parse-item
       state	        rehearse
     ?retrieval>
       buffer           failure
   ==>
     -retrieval>
     =goal>
   )
  
  (P reset-rehearsal
     =goal>
       ISA              parse-item
       state            rehearse
       position         =pos
       position         0
     ?retrieval>
       state		free
       buffer           empty
     ?imaginal>
       buffer           empty
       state            free
     ?visual>
       buffer           empty
     ?visual-location>
       buffer           empty
     ;;?vocal>
     ;;  state            free
     ;;!bind! =next-pos (1- =pos)
   ==>
     -retrieval>
     =goal>
       state            parse
       position         nil ;;=next-pos
   )
|#

  
 #| 
;;;UPDATE;;;
  
  (P retrieve-first-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       > nback          1
       > position       0
       position         =pos
     ?retrieval>
       buffer           empty
       state		free
   ==>
     +retrieval>
       position		=pos		
     =goal>
     )

  (P update-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       position         =pos
     =retrieval>
       - item           nil
       item             =item
       - position       =nback
       position         =pos
     ?imaginal>
       state            free
       buffer           empty
     !bind! =update-pos (1+ =pos)
     !bind! =next-pos   (1- =pos)
   ==>
     -retrieval>
     +imaginal>
       item             =item
       position         =update-pos
     =goal>
       position         =next-pos
     )

  (P set-new-target
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
     =imaginal>
       item             =item
       position         =nback
   ==>
     =imaginal>
     =goal>
       target           =item
     )

  (P retrieve-next-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       position         =pos
     =imaginal>
       - position       =pos
       - position       nil
     ?retrieval>
       buffer           empty
       state		free
   ==>
     -imaginal>
     +retrieval>
       position		=pos	
     =goal>
     )

  (P retrieve-last-seen-item
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       position         0
     ?imaginal>
       buffer           full
     !bind! =start-pos (1- =nback)
   ==>
     -imaginal>
     +retrieval>
       kind             stimulus
     =goal>
       position         =start-pos
   )
  
  (P update-last-seen-item
     =goal>
       ISA		parse-item
       state	        update
       > position       0
     =retrieval>
       kind             stimulus
       item             =item
     ;;!bind! =block (session-block *task*)
     ;;!bind! =trial (bt-index *task*)
   ==>
     =retrieval>
       position         1
       ;;block            =block
       ;;trial            =trial
     =goal>
       state            parse
    )
  
  (P retrieve-last-seen-item-one-back
     =goal>
       ISA		parse-item
       state	        update
       nback		=nback
       seen             =nback
       nback            1
       position         0
     =visual>
       value            "blank"
     ?imaginal>
       buffer           empty
     ?retrieval>
       buffer           empty
       state		free
   ==>
     +retrieval>
       ;;position         0
       kind             stimulus		
     =goal>
     )

  (P update-last-seen-item-one-back
     =goal>
       ISA		parse-item
       state	        update
       position         0
     =retrieval>
       kind             stimulus
       item             =item
       block            =block
       trial            =trial
     ;;!bind! =block (session-block *task*)
     ;;!bind! =trial (bt-index *task*)
   ==>
     @retrieval> ;; do not strengthen visual stimuli
     +imaginal>
       item             =item
       position         1
       block            =block
       trial            =trial
     =goal>
       target           =item
       state            parse
    )



|#

    
;;;REHEARSAL;;;
;;;;Need to change this I think. It only rehearses the items once before stopping. should just continue rehearsing no?
  
#|
  (P rehearse-first-in-list
     =goal>
       state            rehearse
       nback            =nback
       seen             =seen
       - seen           =nback
     ?retrieval>
       buffer           empty
       state            free
     ==>
     +retrieval>
       :recently-retrieved nil
       position         =seen
     =goal>
     )

  (P rehearse-nback
     =goal>
       state            rehearse
       nback            =nback
       seen             =nback
     ?retrieval>
       buffer           empty
       state            free
     ==>
     +retrieval>
       :recently-retrieved nil
       position         =nback
     =goal>
     )

  (P rehearse-next
     =goal>
       state            rehearse
     =retrieval>
       position         =pos
       > position       1
     !bind! =next-pos  (1- =pos)
   ==>
     +retrieval>
       :recently-retrieved nil
       position         =next-pos
     =goal>
   )

  (P reset-rehearse
     =goal>
       state            rehearse
     =retrieval>
       position         =pos
       position         1
     !bind! =next-pos  (1- =pos)
   ==>
     -retrieval>
     =goal>
     )

  (P wait-to-rehearse
     =goal>
       state            rehearse
     ?retrieval>
       buffer           empty
       state            free
     ==>
     =goal>
     )
    
  |#


  ;;break retrievals on new stim (NOT SURE I WANT TO DO THIS...WANT TO LET UPDATING AND RETRIEVAL OF TARGET CONTINUE IF IT BLEEDS INTO NEXT TRIAL OR HASN'T EVEN STARTED YET)
  
  (P break-rehearsal-to-parse-stim
     =goal>
       state            rehearse
       ;;- state          parse
       ;;- state          update
       ;;- state          compare
     ;;?retrieval>
     ;;  state		busy
     ?visual>
       ;;state            busy
       scene-change     t
       buffer           empty  ;;???
     ;;=visual>
     ;;  value            "blank"
       ;;- item           nil
       ;;kind             stimulus
   ==>
     ;;!eval! (collect-no-response) ;;collecting no response at end of trial if no response was made
     ;=visual>
     ;;-retrieval>
     +retrieval>
       :rt-value		10
       :mp-value		nil
       ;;ISA				self
       identity		other
     =goal>
       position         nil
       ;;stage		interact
       state		parse
     )

  (P break-update-to-parse-stim
     =goal>
       ISA		parse-item
       state	        update
       ;;nback		=nback
       ;;seen             =nback
       - position         nil
       - position         0
       ;;- target         nil
     ?retrieval>
       buffer           empty
       state		free
     ;;!bind! =next-pos   (1- =pos)
     ?visual>
       ;;state            busy
       scene-change     t
       buffer           empty  ;;???
     ?visual-location>
       buffer           full
     ;;=visual>
     ;;  value            "blank"
       ;;- item           nil
       ;;kind             stimulus
   ==>
     ;;!eval! (collect-no-response) ;;collecting no response at end of trial if no response was made
     ;=visual>
     ;;-retrieval>
     +retrieval>
       :rt-value		10
       :mp-value		nil
       ;;ISA				self
       identity		other
     ;;-imaginal> ;;just let imaginal buffer harvest itself	
     =goal>
       state            parse
       position         nil ;;=next-pos
   )

  (P break-compare-to-parse-stim
     =goal>
       ISA		parse-item
       state	        compare
     ;;?imaginal>
     ;;  buffer           empty
     ;;  state		free
     ;;!bind! =next-pos   (1- =pos)
     ?visual>
       ;;state            busy
       scene-change     t
       buffer           empty  ;;???
     ?visual-location>
       buffer           full
     ;;=visual>
     ;;  value            "blank"
       ;;- item           nil
       ;;kind             stimulus
   ==>
     ;;!eval! (collect-no-response) ;;collecting no response at end of trial if no response was made
     ;=visual>
     ;;-retrieval>
     +retrieval>
       :rt-value		10
       :mp-value		nil
       ;;ISA				self
       identity		other
     ;;-imaginal> ;;just let imaginal buffer harvest itself	
     =goal>
       state            parse
       position         nil ;;=next-pos
   )
  
  (P break-to-parse-stim-on-retr-fail
     =goal>
       - state          parse
     ?retrieval>
       buffer           failure
     ?visual>
       ;;state            busy
       scene-change     t
       buffer           empty  ;;???
     ?visual-location>
       buffer           full
     ;;=visual>
     ;;  value            "blank"
       ;;- item           nil
       ;;kind             stimulus
   ==>
     ;;!eval! (collect-no-response) ;;collecting no response at end of trial if no response was made
     ;=visual>
     ;;-retrieval>
     +retrieval>
       :rt-value		10
       :mp-value		nil
       ;;ISA				self
       identity		other
     ;;-imaginal> ;;just let imaginal buffer harvest itself	
     =goal>
       state            parse
       position         nil ;;=next-pos
   )

  ;;;;MAY NEED A "RESET BUTTON" TO START OVER IF WE CAN'T RETRIEVE THE TARGET AND/OR UPDATE THE CORRECT ITEMS...MAYBE WOULD SET THE 'SEEN' SLOT IN GOAL BUFFER BACK TO 0
  
;;;ACT-R COMMANDS;;;
  
  ;;(spp no-nback-to-retrieve :at 0.3)
  
  (add-act-r-command "collect-response" 'collect-response)
  (monitor-act-r-command "output-key" "collect-response")
  
  ) ;end model declaration































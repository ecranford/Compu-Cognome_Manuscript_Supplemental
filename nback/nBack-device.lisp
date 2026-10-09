;;; device developed by Patrick Rice 2020
;;;
;;; this device interfaces with ACT-R and presents a version the Human Connectome Project (HCP) working memory (WM) task
;;;
;;; the text strings of the cue/stimuli images are presented on the window for simplicity
;;;
;;; HCP N-back task: - 8 blocks, 10 trials each. half of blocks are 0-back, other half are 2-back; four 15s fixation blocks. The first fix block occurs after the second block, and fix blocks occur every two blocks (so, the run ends with a fix block)
;;;        - 2.5s cue at start of block (either 0-back exemplar or 2-back cue)
;;;	   - in each block, 2 trials are targets, 2-3 trials are non-target lures (repeated items in the wrong n-back position,either 1-back or 3-back; or in the case of 0-back, repeated non-target stimuli)
;;;	   - on each trial, stimulus presented for 2 seconds, then 500ms ITI
;;;	   - A full block is 27.5 seconds; a full session is (8*27.5)+(4*15) = 280 seconds ~ 4.7 mins
;;;
;;; only zero-back blocks are included in this version of the device
;;;
;;; CHANGELOG:
;;; 06/17/2024 -- Drew Cranford -- updated model to accept relative pathnames instead of absolute
;;; 06/17/2024 -- Drew Cranford -- updated device to open an experiment window
;;; 09/09/2024 -- Drew Cranford -- adapted device and model to integrate fatigue module

;;; ------------------------------------------------------------------
;;; N-BACK TASK PARAMETERS
;;; ------------------------------------------------------------------

;;load ACT-R
(load "../actr7/load-single-threaded-act-r.lisp")
(ssp-fct (list :high-performance t))
;;(load "../actr7/load-act-r.lisp")


;;load socket server package and initialize host and port parameters
(ql:quickload '(:usocket-server :cl-json :alexandria :vom))
;;(ql:quickload '(:cl-json :vom))
(vom:config t :debug)

(defparameter +host+ "127.0.0.1")
(defparameter +port+ 9891)
;;(defparameter +port+ 9894)
;;(defparameter +port+ 9897)
(defparameter *tcp* nil)
(defparameter *tcp-data* '())
(defparameter *local* t)

;;; data file names
(defparameter *local-data-path* "./data/nback_model_data.csv")

;;; path to model
(defparameter *pathtomodel* *load-truename*)

;;; flag for ending the task
(defparameter *task-over* nil)

;;; task procedure id (default to 'ops2)
(defparameter *study* 'ops2)
(defparameter *numTotalTrials* 80)
(defparameter *numTargets* 20)

;;; timing of presentation
(defparameter +stimTime+ 0.5)
(defparameter +itiTime+ 2.0) ;;2.5 (seems to be a bug in the G^2 software so that the itiTIme is 2.0 after trial 1)
(defparameter *ses-break* 10)

;;; window to present on
(defparameter *window* nil)

;;; task visual elements
(defparameter *cue* nil)
(defparameter *stimulus* nil)
(defparameter *vis-features* nil)

;;; parameters to track whether response has occurred
(defparameter *numTrials* 0)
(defparameter *numResponses* 0)
(defparameter *response* nil)

;;; list to store responses
(defparameter *responses* '())

;;; list to store response times
(defparameter *respTimes* '())
(defparameter *start-time* nil)

;;; list to store model chunk retrievals
(defparameter *retrievedChunks* '())

;;; list to store model imaginal buffer chunk on response
(defparameter *imaginalChunks* '())

;;; list to store model retrieval buffer chunk on response
(defparameter *retrievalChunks* '())

;;; list to store model retrieved item info
(defparameter *retrievedItems* '())


;;parameters for study

(defparameter *dat* 0.05)
(defparameter *iu* 2.6)
(defparameter *ut0* 2.2)
(defparameter *fpbmc* .02)
(defparameter *fpmc* 0)
(defparameter *utbmc* .01)
(defparameter *utmc* 0)
(defparameter *hour* 8)
(defparameter *fp-dec* 0.98)
(defparameter *egs* 0.25)
(defparameter *fdbmc* -0.02681)
(defparameter *fdc* 0.95743)
(defparameter *fd-dec* 0.98)


;;;OTHER PARAMETERS IN N-BACK

(defparameter *mp* 1.0) ;;nil
(defparameter *md* -1.0)
(defparameter *bll* 0.5)
(defparameter *mas* 1.0)
(defparameter *ans* 0.25)
(defparameter *ga* 1.0)
(defparameter *ia* 1.0)
(defparameter *lf* 1.0)

;;; ------------------------------------------------------------------
;;; N-BACK TASK OBJECT
;;; ------------------------------------------------------------------

(defparameter *task* nil)

(defclass nback-task ()
  ((task-session   :accessor task-session ;;;tracks what session we are in
		   :initform nil)
   (session-block  :accessor session-block ;;;tracks what block we are in
		   :initform nil)
   (bt-index       :accessor bt-index ;;;indexes what trial in the block we're on
		   :initform nil)
   (trial-phase    :accessor trial-phase ;;;represents what phase of the current trial that we're on
		   :initform nil))
  (:documentation  "A manager for the N-Back task")
  )

(defmethod init ((task nback-task))
  (setf (task-session task) 0)
  (setf (session-block task) 0)
  (setf (bt-index task) 0)
  (setf (trial-phase task) 'stimulus)
  )

;;; ------------------------------------------------------------------
;;; N-BACK TASK DATA STRUCTURES
;;; ------------------------------------------------------------------

;;; for ops-II each participant performed one session, with two blocks: 1-back then 2-back
;;; the order of presented stimuli was randomized across participants, within session.
(defparameter *task-stimuli* nil)

(defun create-ops2-stim (ntrials ntargets)
  (let (stim
	(letters '(X G H K P Q S W)))
    ;;select six letters to choose from
    (let ((one-back '())
	  (one-back-targets (append '(nil) (alexandria:shuffle (append (make-list (- ntrials ntargets)) (make-list ntargets :initial-element 1)))))
	  (two-back '())
	  (two-back-targets (append '(nil nil) (alexandria:shuffle (append (make-list (- ntrials ntargets)) (make-list ntargets :initial-element 1)))))
	  (letter-set '()))
      ;;create list of n letters with m targets randomly dispersed
      ;;create 1-back list
      (push 1 one-back)
      (setf letter-set (subseq (alexandria:shuffle letters) 0 6))
      (dolist (i one-back-targets)
	(if i
	    (push (nth 0 one-back) one-back)
	    (let ((non-target nil))
	      (loop while (let ((letter (nth (random (length letter-set)) letter-set)))
			    (setf non-target letter)
			    (equal (nth 0 one-back) letter)))
	      (push non-target one-back))))
      ;;create 2-back list
      (push 2 two-back)
      (setf letter-set (subseq (alexandria:shuffle letters) 0 6))
      (dolist (i two-back-targets)
	(if i
	    (push (nth 1 two-back) two-back)
	    (let ((non-target nil))
	      (loop while (let ((letter (nth (random (length letter-set)) letter-set)))
			    (setf non-target letter)
			    (equal (nth 1 two-back) letter)))
	      (push non-target two-back))))
      (push (reverse two-back) stim)
      (push (reverse one-back) stim)
      )
    (list stim))	
  )

(defun create-1back-stim (ntrials ntargets)
  (let (stim
	(letters '(X G H K P Q S W)))
    ;;select six letters to choose from
    (let ((one-back '())
	  (one-back-targets (append '(nil) (alexandria:shuffle (append (make-list (- ntrials ntargets)) (make-list ntargets :initial-element 1)))))
	  (letter-set '()))
      ;;create list of n letters with m targets randomly dispersed
      ;;create 1-back list
      (push 1 one-back)
      (setf letter-set (subseq (alexandria:shuffle letters) 0 6))
      (dolist (i one-back-targets)
	(if i
	    (push (nth 0 one-back) one-back)
	    (let ((non-target nil))
	      (loop while (let ((letter (nth (random (length letter-set)) letter-set)))
			    (setf non-target letter)
			    (equal (nth 0 one-back) letter)))
	      (push non-target one-back))))
      (push (reverse one-back) stim)
      )
    (list stim))	
  )

(defun create-2back-stim (ntrials ntargets)
  (let (stim
	(letters '(X G H K P Q S W)))
    ;;select six letters to choose from
    (let ((two-back '())
	  (two-back-targets (append '(nil nil) (alexandria:shuffle (append (make-list (- ntrials ntargets)) (make-list ntargets :initial-element 1)))))
	  (letter-set '()))
      ;;create list of n letters with m targets randomly dispersed
      ;;create 2-back list
      (push 2 two-back)
      (setf letter-set (subseq (alexandria:shuffle letters) 0 6))
      (dolist (i two-back-targets)
	(if i
	    (push (nth 1 two-back) two-back)
	    (let ((non-target nil))
	      (loop while (let ((letter (nth (random (length letter-set)) letter-set)))
			    (setf non-target letter)
			    (equal (nth 1 two-back) letter)))
	      (push non-target two-back))))
      (push (reverse two-back) stim)
      )
    (list stim))	
  )


;;; ------------------------------------------------------------------
;;; BASE-LEVEL INHIBITION
;;; ------------------------------------------------------------------
;;(require-extra "base-level-inhibition")

;;; ------------------------------------------------------------------
;;; BLENDING
;;; ------------------------------------------------------------------
;;(require-extra "blending")

;;; similarity function
(defun linear-similarity (x y)
  (let ((nback (nth 0 (nth (session-block *task*) (nth (task-session *task*) *task-stimuli*)))))
    (cond ((equal x y) 0.0) ;;if equal then maximally similar
	  ((and (integerp x) (integerp y)) ;;if integers then linear similarity
	   ;;if less than or equal to 1+nback then scale based on current nback level (or max of x and y)
	   ;;if greater than 1+nback then scale based on number of trials (or max of x and y) -- could be higher based on temporal module
	   (if (and (<= x (1+ nback)) (<= y (1+ nback)))
	       (if (or (= x 0) (= y 0))
		   (* *md* 2) ;;anything compared to 0 is special case very dissimilar
		   (* -1 *md* (1- (exp (* -1 2 (abs (- x y))))))) ;;exponential dissimilarity
	       ;;(- (sqrt (/ (abs (- x y)) (max nback (max x y))))) ;;Is this value, 10.0, correct? (0 to -1)
	       (/ (- (abs (- x y))) (max (+ nback *numTotalTrials*) (max x y)))))
	  ;;Phonologicial similarity computed via nltk cmudict (edit_distance) for letter set (X G H K P Q S W)
          ((or (and (equal x "X") (equal y "K")) (and (equal x "K") (equal y "X"))) -0.6666667)
	  ((or (and (equal x "X") (equal y "S")) (and (equal x "S") (equal y "X"))) -0.3333333)
	  ((or (and (equal x "G") (equal y "P")) (and (equal x "P") (equal y "G"))) -0.5)
	  ((or (and (equal x "K") (equal y "Q")) (and (equal x "Q") (equal y "K"))) -0.6666667)
          (t (no-output (first (sgp :md))))))) ;;otherwise maximilly different


;;; ------------------------------------------------------------------
;;; UTILITY FUNCTIONS
;;; ------------------------------------------------------------------


;;; This fuction collects the values of the the slots named 'one',
;;; 'two', and 'three' from the chunk currently in the imaginal buffer.
;;; If the chunk has no slots or there is no chunk, '(nil nil nil) is
;;; returned.
;;;

(defun read-imaginal-slots (&optional (slots '(one two three)))
  "Reads the contents of the imaginal buffer and returns them as a list"
  (let ((nwindow (first (no-output (buffer-chunk-fct '(imaginal))))))
    (if nwindow
        (mapcar #'(lambda (x)
                    (chunk-slot-value-fct nwindow x))
                slots)
        '(nil nil nil))))

(defun collect-imaginal-slots ()
  (push (read-imaginal-slots) *imaginalChunks*)
  )

(defun read-retrieval-slots (&optional (slots '(item)))
  "Reads the contents of the imaginal buffer and returns them as a list"
  (let ((nwindow (first (no-output (buffer-chunk-fct '(retrieval))))))
    (if nwindow
        (mapcar #'(lambda (x)
                    (chunk-slot-value-fct nwindow x))
                slots)
        '(nil))))

(defun collect-retrieval-slots ()
  (push (read-retrieval-slots) *retrievalChunks*)
  )

(defun collect-retrieved-item (cur-pos)
  (let ((tNum (bt-index *task*))
	(blkNum (session-block *task*)))
    (multiple-value-bind (item block trial position)
	(no-output (values (chunk-slot-value-fct (first (buffer-chunk-fct '(retrieval))) 'item)
			   (chunk-slot-value-fct (first (buffer-chunk-fct '(retrieval))) 'block)
			   (chunk-slot-value-fct (first (buffer-chunk-fct '(retrieval))) 'trial)
			   (chunk-slot-value-fct (first (buffer-chunk-fct '(retrieval))) 'position)))
      ;;add retrieved item to list; if trial already exists, append list, else create new trial
      (if (assoc tNum (cdr (assoc blkNum *retrievedItems*)))
	  (setf (cdr (assoc tNum (cdr (assoc blkNum *retrievedItems*)))) (acons cur-pos `((ITEM . ,item) (BLOCK . ,block) (TRIAL . ,trial) (POSITION . ,position))
							   (cdr (assoc tNum (cdr (assoc blkNum *retrievedItems*))))))
	  (setf (cdr (assoc blkNum *retrievedItems*)) (acons tNum `((,cur-pos . ((ITEM . ,item) (BLOCK . ,block) (TRIAL . ,trial) (POSITION . ,position))))
					(cdr (assoc blkNum *retrievedItems*)))))))
  )
	  

;;; retrieved-chunk-hook function
;;; has to handle retrieved chunks and fails
(defparameter chunk nil)
(defmethod record-retrieved-chunk (chunk)
  "Adds the value of the kind slot of the chunk input argument to the list *retrievedChunks*"
  (if (chunk-p-fct chunk)
      (push chunk *retrievedChunks*) ;;; pushes the name of the retrieved chunk to the list
      (push "failedRetrieval" *retrievedChunks*)
      )
  )


;;;flat and linear :sji-hook equations
;;; provided by Andrea Stocco, 12/3/2020; thanks Andrea!
;;; updated by Andrea Stocco 12/4/2020 to return 0 for non-chunk slot values
(defun flat-activation-spread (source target)
  "Returns 1 if S == T or if S %in% T; 0 otherwise"
  (if (and (chunk-p-fct source)
	   (chunk-p-fct target))
      (if (or (eq-chunks-fct source target)
	      (member source (mapcar #'(lambda (x)
					 (chunk-slot-value-fct target x))
				     (chunk-filled-slots-list-fct target))
		      :test #'eq-chunks-fct))
	  1
	  0)
      0))

(defun linear-activation-spread (source target)
  "Returns 1 if S == T, of 1 X every S %in% T; 0 otherwise"
  (if (and (chunk-p-fct source)
	   (chunk-p-fct target))
      
      (if (eq-chunks-fct source target)
	  1
	  (let ((target-values (mapcar #'(lambda (x)
					   (chunk-slot-value-fct target x))
				       (chunk-filled-slots-list-fct target))))
	    (reduce #'+ (mapcar #'(lambda (x)
				    (if (eq-chunks-fct source x)
					1
					0))
				target-values))))
      0))

;;; function to end the task when it's over
(defun task-over (time)
  (or *task-over* (> time 1000000000))
  )

;;; function to record model responses
;;(defun collect-response (model key)
;;	(declare (ignore model))
;;	(push (mp-time) *respTimes*)
;;	(push (format nil "~a" key) *responses*)
;;	(incf *numResponses*)
;;)

;;;; function to record when a model fails to respond
;;(defun collect-no-response ()
;;	(push nil *respTimes*)
;;	(push nil *responses*)
;;	(incf *numResponses*)
;;)

(defun collect-response (model key)
  (declare (ignore model))
  (push (- (mp-time) *start-time*) *respTimes*)
  (push (format nil "~a" key) *responses*)
  (incf *numResponses*)
  ;;(format t ";;; response detected~%")
  (setf *response* t)
  ;;(trigger-reward 5) ;;trigger a reward upon response
  )

;;;; function to record when a model fails to respond
(defun collect-no-response ()
  (push nil *respTimes*)
  (push nil *responses*)
  (push nil *retrievalChunks*)
  (incf *numResponses*)
  ;;(format t ";;; no response detected~%")
  )

;;; function to combine cue timing, response timing, and response identity lists into a single list
(defun combine-lists (resp respTime retrievedChunks)
  (let ((combinedList '()))
    (loop for i in resp
	  for j in respTime
	  for k in retrievedChunks
	  do (push (list i j k) combinedList))
    (nreverse combinedList)
    )
  )

;;; function to write model responses and response times to file
(defun writeData (data fName)
  (with-open-file (out fName :direction :output :external-format :ascii)
    (dolist (segment data)
      (format out "~{~a~^, ~}~%" segment)))
  )

(defun write-data-to-file (data filename)
  "Write a list to a file"
  (with-open-file (str filename :direction :output
				:if-exists :append
				:if-does-not-exist nil)
    (format str "~{~a~^,~}~%" data)))
    

;;; visicon update function  ;;;Depricated, only use the AGI commands in the (display-taskScreen) function
(defun update-visicon (sesNum blkNum tNum tPhase)
  
  ;; updates the ACT-R visicon with the block's cue, the trial's stimulus, the trial's ITI, or one of the fixation periods
  ;; task-stimuli is a list of list of lists; a list of the two sessions, which are each lists of the session's 8 blocks, which are each lists of the block's 1 cue + 10 trials
  ;; sesNum indexes the session
  ;; blkNum indexes the block
  ;; tNum indexes the trial
  ;; tPhase determines whether we are presenting a stimulus (either cue or trial stim)
  ;; the time that the screen is presented for is handled by the schedule-event-relative call in the 'next' method below
  
  ;; remove everything before we put something new on - there are no "evolving" features in the task
  ;;(delete-all-visicon-features)
  ;;(delete-visicon-features (first features))
  
  ;; puts a cue into the visicon
  (when (equal tNum 0)
    (let ((nback (nth tNum (nth blkNum (nth sesNum *task-stimuli*)))))    
      (add-visicon-features `(isa (visual-location cue)
				  screen-x 305 ;;300
				  screen-y 356 ;;200
				  nback (nil ,nback)
				  item (nil nil)
                                  kind (cue cue)
                                  ))))
  
  ;; puts a stimulus into the visicon
  (when (and (> tNum 0)
	     (equal tPhase 'stimulus)
	     )
    (let ((stim (nth tNum (nth blkNum (nth sesNum *task-stimuli*))))
	  (nback (nth 0 (nth blkNum (nth sesNum *task-stimuli*)))))
      (add-visicon-features `(isa (visual-location stimulus)
				  screen-x 305 ;;300
				  screen-y 206 ;;200
				  item (nil ,stim)
                                  kind (stimulus stimulus)
				  block (nil ,blkNum)
				  trial (nil ,tNum)
				  )
			    `(isa (visual-location cue)
				  screen-x 305 ;;300
				  screen-y 356 ;;200
				  nback (nil ,nback)
				  item (nil nil)
                                  kind (cue cue)
                                  ))))
  
  ;; presents a "blank" screen during the ITI (cue remains but don't worry about adding that to visicon)
  (when (equal tPhase 'ITI)
    (add-visicon-features '(isa (visual-location blank)
			    screen-x 300
			    screen-y 200
			    width 200
			    height 200
			    value "blank"
			    )))
  )

;;; task display function
(defun display-taskScreen (sesNum blkNum tNum tPhase)
  
  ;; displays the block's cue, the trial's stimulus, the trial's ITI, or one of the fixation periods
  ;; task-stimuli is a list of list of lists; a list of the two sessions, which are each lists of the session's 8 blocks, which are each lists of the block's 1 cue + 10 trials
  ;; sesNum indexes the session
  ;; blkNum indexes the block
  ;; tNum indexes the trial
  ;; tPhase determines whether we are presenting a stimulus (either cue or trial stim)
  ;; the time that the screen is presented for is handled by the schedule-event-relative call in the 'next' method below
  
  ;; for ITIs, the stim is cleared but the nback cue remains
  ;;(clear-exp-window *window*)
  ;;(clear-buffer 'visual-location)
  
  ;; displays the block's cue
  (when (equal tNum 0)
    (let ((nback (nth tNum (nth blkNum (nth sesNum *task-stimuli*)))))
      (clear-exp-window *window*)
      (setf *cue* (add-text-to-exp-window  *window* (write-to-string nback) :x 300 :y 350 :color 'black))
      ;;(delete-visicon-features *cue*)
      )
    )
  
  ;; displays the trial's stimulus
  (when (and (> tNum 0)
	     (equal tPhase 'stimulus)
	     )
    (let (;;(nback (nth 0 (nth blkNum (nth sesNum *task-stimuli*))))
	  (stim (nth tNum (nth blkNum (nth sesNum *task-stimuli*)))))
      ;;(setf *cue* (add-text-to-exp-window  *window* (write-to-string nback) :x 300 :y 350 :color 'black))
      (setf *stimulus* (add-text-to-exp-window  *window* (string stim) :x 300 :y 200 :color 'black))
      )
    (setf *start-time* (mp-time))
    )
  
  ;; clear the trial's stimulus during the ITI
  (when (and (> tNum 0)
	     (equal tPhase 'ITI)
	     )
    (remove-items-from-exp-window *window* *stimulus*)
    ;;;may want to schedule these clears after a few hundred ms to simulate decay from visuo-spatial sketchpad
    ;;(let ((time-delta (/ (+ 900 (act-r-random 200)) 1000)))
    ;;  (schedule-clear-buffer 'visual-location time-delta :module 'vision)
    ;;  (schedule-clear-buffer 'visual time-delta :module 'vision)     
    ;;  )
    
    (schedule-event-after-change 'clear-buffer :params '(visual-location))
    ;;(clear-buffer 'visual-location)
    (schedule-event-after-change 'clear-buffer :params '(visual))
    ;;(clear-buffer 'visual)
    ;;(schedule-event-after-change 'clear :params `(,(get-module :vision)) :details "CLEAR VISION MODULE")
    ;;(clear (get-module :vision)) ;; what is this doing that clearing visual and visual-location buffers is not doing? a: necessary to clear attention, it seems
    
    ;;(let ((nback (nth 0 (nth blkNum (nth sesNum *task-stimuli*)))))
    ;;  (add-text-to-exp-window *window* (write-to-string nback) :x 300 :y 350 :color 'black)
    ;;  )
    )
  
  )

;;; updating functions

;;; function to update the session value
(defun update-ses (task session blkNum tNum tPhase)
  
  ;; when the ITI period after the last trial of the last block of the session has been presented:
  ;; - increase the task-session of the task by 1
  (when (and (equal blkNum (1- (length (nth session *task-stimuli*)))) ;; blkNum = total number of blocks - 1 (2-1=1)
	     (equal tNum (1- (length (nth blkNum (nth session *task-stimuli*))))) ;;tnum = last trial of block - 1 (83-1=82)
	     (equal tPhase 'ITI))
    (setf (task-session task) (1+ session))
    )
  
  ;; when end of last session:
  ;; - set the 'task-over' flag to true
  (when (equal (task-session task) (length *task-stimuli*)) ;; current-session = number of total sessions
    (setf *task-over* t)
    )
  )

;;; function to update the block value
(defun update-blk (task session blkNum tNum tPhase)
  
  ;; when the block is over:
  ;; - increment the block number
  (when (and (equal tNum (1- (length (nth blkNum (nth session *task-stimuli*))))) ;;tnum = last trial of block - 1 (83-1=82)
	     (equal tPhase 'ITI))
    (setf (session-block task) (1+ blkNum))
    ;;;may want to full clear exp window here ;;now do it below in runTask function
    )
  
  ;; when the the last block of the session has been presented:
  ;; - set the block number back to 0
  (when (equal (session-block task) (length (nth session *task-stimuli*))) ;; current-block = number of total blocks in the session
    (setf (session-block task) 0)
    )
  )

;;; function to update the trial number and trial phase values
(defun update-tNumPhase (task session blkNum tNum tPhase)
  
  ;; after the cue has been presented:
  ;; - increment the trial number (no ITI for the cue)
  (when (and (equal tNum 0)
	     (equal tPhase 'stimulus)
	     )
    (setf (bt-index task) (1+ tNum))
    )

  ;; after a trial's stimulus has been presented:
  ;; set the trial-phase of the task to 'ITI'
  (when (and (> tNum 0)
	     (equal tPhase 'stimulus)
	     ;;(not *response*)
	     )
    (setf (trial-phase task) 'ITI)
    )
  
  ;; [when an response has been made or] after ITI has been presented:
  ;; - set the trial-phase of the task to 'stimulus'
  ;; - increment the trial number
  (when (equal tPhase 'ITI) ;;(or *response* (equal tPhase 'ITI))
    (setf (trial-phase task) 'stimulus)
    (setf (bt-index task) (1+ tNum))
    ;;if no response was made, then (collect-no-response)
    (if (not *response*)
	(collect-no-response))
    )
  
  ;; when transitioning between blocks:
  ;; - set the bt-index of the task to 0 (indexes the cue of a block of trials)
  (when (equal (bt-index task) (length (nth blkNum (nth session *task-stimuli*))))
    (setf (bt-index task) 0)
    )

  ;;might need to handle cases when the participant responds before during the stimulus vs during the ITI
  ;;if respond during stimulus they need to immediately push to ITI phase
  ;;if respond during the ITI they need to continue until end of ITI
  )

;;; ------------------------------------------------------------------
;;; RUN N-BACK TASK
;;; ------------------------------------------------------------------

(defun runTask (study ntrials ntargets &optional (subject 0) (hour 0) (visible t))
  (setf *task-over* nil)
  (setf *responses* '())
  (setf *respTimes* '())
  (setf *retrievedChunks* '())
  (setf *imaginalChunks* '())
  (setf *retrievalChunks* '())
  (setf *retrievedItems* (pairlis '(0 1) '(()())))
  (setf *cue* nil)
  (setf *stimulus* nil)
  (setf *vis-features* nil)
  (setf *numResponses* 0)
  (setf *numTrials* 0)
  (setf *task-stimuli* (case study
			 ;;use cases to expand to different tasks as needed
			 (ops2 (create-ops2-stim ntrials ntargets))
			 (1back (create-1back-stim ntrials ntargets))
			 (2back (create-2back-stim ntrials ntargets))
			 (otherwise (create-ops2-stim ntrials ntargets))))

  ;;create data file header if file does not exist
  (if *local*
      (with-open-file (str *local-data-path*
			       :direction :output
			       :if-exists nil
			       :if-does-not-exist :create)
	(format str "~{~A~^,~}~%" (list "Subject" "Session" "Hour" "Block" "Nback" "Trial" "TrialStart" "Stim" "NbackStim" "RespType" "Response" "RespTime" "Accuracy" "2backMem" "1backMem"))))
  
  ;;relative path to nBack-model-chunks.lisp
  (load (merge-pathnames "nBack-model-chunks.lisp" *pathtomodel*))
  
  (setf *window* (open-exp-window "N-Back Task" :visible visible :x 0 :y 0 :width 600 :height 400))
  
  (install-device '("motor" "keyboard"))
  (install-device *window*)
  (setf *task* (make-instance 'nback-task))
  (init *task*)
  (setf *response* nil)
  ;;loop until task over instead of scheduling next events
  (while (not (task-over (mp-time)))
	 (let ((ses (task-session *task*))
	       (blkNum (session-block *task*))
	       (tNum (bt-index *task*))
	       (tPhase (trial-phase *task*))
               (dispTime nil))
	   (when (equal tPhase 'ITI)
	     (setf dispTime +itiTime+))
	   (when (equal tNum 0)
	     (setf dispTime (+ +itiTime+ +stimTime+)))
	   (when (and (> tNum 0)
		      (equal tPhase 'stimulus))
	     (setf *response* nil)
	     (setf dispTime +stimTime+))

	   ;;(format t "ses: ~a, block: ~a, trial: ~a, phase: ~a, dispTime: ~a~%" ses blkNum tNum tPhase dispTime)
	   
	   ;;; clear-exp-window at start of block then puts the current display on the task window
	   (display-taskScreen ses blkNum tNum tPhase)

	   ;;disable fatigue module and reset stimulus at start of new trial, e.g., when tPhase is 'stimulus
	   (when (and (> tNum 0)
		      (equal tPhase 'stimulus))
	     (sgp :enable-fatigue nil)
	     (reset-stimulus)
	     ;; just as a new stimulus is being presented, check to make sure that the number of trials that have occurred
	     ;; (not including the to-be-presented stimulus) is equal to the number of recorded responses. If not, throw a warning message
	     ;;(when (not (equal *numTrials* *numResponses*))
	     ;;  (print "Warning: Number of trials and number of responses not equal!")
	     ;;  (print *numTrials*)
	     ;;  (print *numResponses*)
	     ;;  )
	     (incf *numTrials*)
	     ;;enable fatigue module
	     (sgp :enable-fatigue t)
	     )	   
	   
	   ;; update the model's visicon with the current task information
	   ;;(update-visicon ses blkNum tNum tPhase)

	   ;;;Run the model here for dispTime or until response is made
	   ;;(run-until-time-or-condition dispTime #'(lambda() *response*))
	   
	   ;;When tPhase is stimulus, break on response and go to ITI phase
	   ;;but when tPhase is 'ITI, run for ITI and do not break
	   ;;(if (and (> tNum 0) (equal tPhase 'stimulus))
	   ;;    (run-until-time-or-condition dispTime #'(lambda() *response*))
	   ;;    (run-full-time dispTime))
	   
	   ;;Based on recording of task, seem like actual method is to run full time all of the time
	   (run-full-time dispTime)

	   ;;write data to file
	   (if (and (or *local* *tcp*) (equal tPhase 'ITI) (> tNum 0))
	       (let* ((nback (nth 0 (nth blkNum (nth ses *task-stimuli*))))
		      (stim (nth tNum (nth blkNum (nth ses *task-stimuli*))))
		      (nback-stim (if (> tnum nback)
				      (nth (- tNum nback) (nth blkNum (nth ses *task-stimuli*)))
				      nil))
		      (resp-type (if (equal stim nback-stim) 1 0))
		      (resp (if *response* 1 0))
		      (resp-time (if *response* (nth 0 *respTimes*) nil))
		      (accuracy (if (equal resp-type 1)
				    (if (equal resp 1)
					1
					0)
				    (if (equal resp 0)
					1
					0)))
		      (two-back-mem (cdr (assoc 'item (cdr (assoc 2 (cdr (assoc (1- tNum) (cdr (assoc blkNum *retrievedItems*)))))))))
		      (one-back-mem (cdr (assoc 'item (cdr (assoc 1 (cdr (assoc (1- tNum) (cdr (assoc blkNum *retrievedItems*)))))))))
		     )
		 (if *local*
		     (write-data-to-file
		      (list subject ses hour (1+ blkNum) nback tNum *start-time* stim nback-stim resp-type resp resp-time accuracy two-back-mem one-back-mem)
		      *local-data-path*))
		 (if *tcp* (setf *tcp-data* (cons (reverse (pairlis '(iteration day hour bout block nback trial curtime stim nback-stim resp-type resp resp-time accuracy)
								    `(,subject
								      ,(ceiling (/ hour 24))
								      ,(mod hour 24)
								      ,hour
								      ,(1+ blkNum)
								      ,nback
								      ,tNum
								      ,*start-time*
								      ,stim
								      ,nback-stim
								      ,resp-type
								      ,resp
								      ,resp-time
								      ,accuracy)))
						  *tcp-data*)))))

	   ;;when end of a block display blank screen for *ses-break* time
	   (when (and (not *task-over*) ;; task is not over
		      (equal tNum (1- (length (nth blkNum (nth ses *task-stimuli*))))) ;;tnum = last trial of block - 1 (83-1=82)
		      (equal tPhase 'ITI))
	     (clear-exp-window *window*)
	     (sgp :enable-fatigue nil)
	     (clear-buffer 'temporal)  ;;clear the temporal buffer at the end of the block to prevent unncecessary events at end of block
	     (no-output (eval (list 'mod-chunk (goal-focus) 'state 'break)))
	     (reset-stimulus)
	     (run-full-time *ses-break*) ;;wait *ses-break* time (default 10 secs) between sessions 
	     (no-output (eval (list 'mod-chunk (goal-focus) 'state 'start)))
	     )
	   
	   ;; update session, block, and trial info
	   (update-ses *task* ses blkNum tNum tPhase) ;;; updates the session when necessary
	   (update-blk *task* ses blkNum tNum tPhase) ;;; updates the block when necessary
	   (update-tNumPhase *task* ses blkNum tNum tPhase) ;;; updates the trial number and phase when necessary
 
	   )
	 )
  )
  

;;; function to output the combined response info list to python
;;; added as an actr command here and then called with actr.call_command('print-resp')
(defun print-resp ()
  (print (combine-lists *responses* *respTimes* *retrievedChunks*))
  )
(add-act-r-command "print-resp" 'print-resp)

(defun print-imaginal-chunks ()
  (print *imaginalChunks*)
  )
(add-act-r-command "print-imaginal-chunks" 'print-imaginal-chunks)

(defun print-retrieval-chunks ()
  (print *retrievalChunks*)
  )
(add-act-r-command "print-retrieval-chunks" 'print-retrieval-chunks)

(defun print-num-responses ()
  (print *numResponses*)
  )
(add-act-r-command "print-num-responses" 'print-num-responses)

(defun call-clear-all ()
  (clear-all)
  )
(add-act-r-command "call-clear-all" 'call-clear-all)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; TCP Socket Communication Code
;; And Parameter Optimization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; sleep schedule set to general OPSII procedures, not yet personalized
(defparameter *OPSI-SS* '((6 23) (30 47) (54 71) (78 95) (102 119) (126 143) (150 167) (174 191) (198 215) (222 239) (246 263) (270 287) (294 311) (318 335) (342 359) (366 383) (390 407) (414 431) (438 455) (462 479) (486 503) (510 527) (534 551) (558 575) (582 599) (606 623) (630 647) (654 671) (678 695) (702 719) (726 743) (750 767) (774 791) (798 815) (822 839) (846 863) (870 887) (894 911) (918 935) (942 959) (966 983) (990 1007) (1014 1031) (1038 1055) (1062 1079) (1086 1103) (1110 1127) (1134 1151) (1158 1175) (1182 1199) (1206 1223) (1230 1247) (1254 1271) (1278 1295) (1302 1319) (1326 1343) (1350 1367) (1374 1391) (1398 1415) (1422 1439) (1446 1463) (1470 1487) (1494 1511) (1518 1535) (1542 1559) (1566 1583) (1590 1607) (1614 1631) (1638 1655) (1662 1679) (1686 1703) (1710 1727) (1734 1751) (1758 1775) (1782 1799) (1806 1823) (1830 1847) (1854 1871) (1878 1895) (1902 1919) (1926 1943) (1950 1967) (1974 1991) (1998 2015) (2022 2039)))

(defparameter *OPSII-SS* '((5 21) (29 45) (53 69) (77 93) (101 117) (125 141) (149 165) (173 189) (197 216) (220 240) (244 264) (268 285) (293 309) (317 336) (340 360) (364 384) (388 405) (413 429) (437 456) (460 480) (484 504) (508 525) (533 549) (557 576) (580 600) (604 624) (628 645) (653 669) (677 693) (701 717) (725 741) (749 765) (773 789) (797 813) (821 837) (845 861) (869 885) (893 909)))

(defparameter *SERE-SS* '((6 23) (30 47) (54 71) (77 97) (101 121) (125 145) (149 169) (173 193) (197 217) (221 241) (245 265) (269 289) (293 313) (317 337) (341 361) (365 385) (389 409) (413 433) (438 455) (462 479) (486 503) (510 527) (534 551) (558 575) (582 599) (606 623) (630 647) (654 671) (678 695) (702 719) (726 743) (750 767) (774 791) (798 815) (822 839) (846 863) (870 887) (894 911) (918 935) (942 959) (966 983) (990 1007) (1014 1031) (1038 1055) (1062 1079)))

(defparameter *HIGH-SS* '((6 23) (30 47) (54 71) (78 95) (102 119) (126 143) (150 167) (174 191) (198 215) (222 239) (246 263) (270 287) (294 311) (318 335) (342 359) (366 383) (390 407) (414 431) (438 455) (462 479) (486 503) (510 527) (534 551) (558 575) (582 599) (606 623) (630 647) (654 671) (678 695) (702 719) (726 743) (750 767) (774 791) (798 815) (822 839) (846 863) (870 887) (894 911) (918 935) (942 959) (966 983) (990 1007)))

;; run through bouts for each iteration ********DO WE WANT TO PARAMETERIZE AT EACH BOUT OR ACROSS ALL BOUTS??*********
(defun run-model-param-opt (&key (dat 0.05) (egs 0.25) (ut0 2.2) (iu 2.6) (utmc -0.01) (utbmc 0.01) (fpdec 0.98) (fpmc -0.05) (fpbmc 0.02) (fdbmc -0.03) (fdc 0.96) (fddec 0.98) (mp 1.0) (bll 0.5) (ans 0.25) (lf 1.0) (mas nil) (ga 0.0) (ia 0.0) (numiterations 10) (bouts '(34 82 130 274 322 394 514 634 754 898)) (schedule *OPSII-SS*) (study 'ops2) (ntrials 80) (ntargets 20) (stim-time 0.5) (iti-time 2.0) (ses-break 10.0) (local-file-output nil) (tcp t) (tcp-file-output nil))
  ;;(format t "Running model~%")
  (setf *dat* dat)
  (setf *egs* egs)
  (setf *ut0* ut0)
  (setf *iu* iu)
  (setf *utmc* utmc)
  (setf *utbmc* utbmc)
  (setf *fp-dec* fpdec)
  (setf *fpmc* fpmc)
  (setf *fpbmc* fpbmc)
  (setf *fdbmc* fdbmc)
  (setf *fdc* fdc)
  (setf *fd-dec* fddec)
  (setf *mp* mp)
  (setf *bll* bll)
  (setf *ans* ans)
  (setf *lf* lf)
  (setf *mas* mas)
  (setf *ga* ga)
  (setf *ia* ia)
  (setf *study* study)
  (setf +stimTime+ stim-time)
  (setf +itiTime+ iti-time)
  (setf *numTotalTrials* ntrials)
  (setf *numTargets* ntargets)
  (setf *ses-break* ses-break)
  (setf *tcp* tcp)
  (setf *tcp-data* nil) ;;reset *tcp-data* each time we run the model
  (if local-file-output
      (progn
	(setf *local* t)
	(setf *local-data-path* (format nil "./data/~a_model_data.csv" local-file-output)))
      (setf *local* nil))
  ;;(format t "Setting Schedule~%")
  (if (stringp schedule)
      (cond ((equal schedule "OPSI")
	     (setf schedule *OPSI-SS*))
	    ((equal schedule "OPSII")
	     (setf schedule *OPSII-SS*))
	    ((equal schedule "SERE")
	     (setf schedule *SERE-SS*))
	    ((equal schedule "HIGH")
	     (setf schedule *HIGH-SS*))
	    (t (setf schedule *OPSII-SS*)))
      (if (not schedule) (setf schedule *OPSII-SS*)))
  (if (not (equal schedule (fatigue-module-schedule (get-module :fatigue))))
      (set-schedule schedule  :p0 3.841432 :u0 38.509212 :k0 0.019455))
  (dolist (b bouts)
    (dotimes (i numiterations)   ;;;if there is learning between bouts then we only want to reset after all bouts, not between iterations, but need to advance the clock between bouts to account for memory decay. for nback, mostly for utility learning if we end up using that for strategy learning.
      (format t "Iteration: ~s Bout: ~s~%" i b)
      (setf *hour* b)
      ;;(format t "Resetting model~%")
      (reset)
      ;;(format t "Done resetting~%")
      (sgp-fct (list :hour b))
      (runTask study ntrials ntargets i b nil)))
  (if tcp-file-output
      (progn
	(with-open-file (str (format nil "./data/~a_tcpdata.csv" tcp-file-output)
			     :direction :output
			     :if-exists nil
			     :if-does-not-exist :create)
	  (format str "~{~A~^,~}~%" (list "Subject" "Day" "Hour" "Bout" "Trial" "TrialStart" "Stim" "NbackStim" "RespType" "Response" "RespTime" "Accuracy")))
	(with-open-file (str (format nil "./data/~a_tcpdata.csv" tcp-file-output)
			     :direction :output
			     :if-exists :append
			     :if-does-not-exist nil)
	  (dolist (row (reverse *tcp-data*))
	    (format str "~{~a~^,~}~%" (list (cdr (assoc 'iteration row))
					    (cdr (assoc 'day row))
					    (cdr (assoc 'hour row))
					    (cdr (assoc 'bout row))
					    (cdr (assoc 'trial row))
					    (cdr (assoc 'curtime row))
					    (cdr (assoc 'stim row))
					    (cdr (assoc 'nback-stim row))
					    (cdr (assoc 'resp-type row))
					    (cdr (assoc 'resp row))
					    (cdr (assoc 'resp-time row))
					    (cdr (assoc 'accuracy row))))))))
  (reverse *tcp-data*))

;; process the incoming message and return a response
(defun process-request (stream)
  (handler-case
      (progn
	(vom:debug ";; Connection opened")
	(with-input-from-string (msg (read-line stream))
	  (vom:debug ";; Recieved message ~S" msg)
	  (let ((json:*json-symbols-package* nil))
	    (let ((json-msg (json:decode-json msg)))
	      (vom:debug ";; Decoded JSON is ~S" json-msg)
	      (when (equal (cdr (assoc 'exit json-msg)) "exit")
		(exit))
	      (let ((response (run-model-param-opt :dat (cdr (assoc 'dat json-msg)) ;;;should include other parameters if provided otherwise defaults
						   :egs (cdr (assoc 'egs json-msg))
						   :ut0 (cdr (assoc 'ut json-msg))
						   :iu (cdr (assoc 'iu json-msg))
						   :utmc (cdr (assoc 'utmc json-msg))
						   :utbmc (cdr (assoc 'utbmc json-msg))
						   :fpdec (cdr (assoc 'fpdec json-msg))
						   :fpmc (cdr (assoc 'fpmc json-msg))
						   :fpbmc (cdr (assoc 'fpbmc json-msg))
						   :fdbmc (cdr (assoc 'fdbmc json-msg))
						   :fdc (cdr (assoc 'fdc json-msg))
						   :fddec (cdr (assoc 'fddec json-msg))
						   :ans (cdr (assoc 'ans json-msg))
						   :bll (cdr (assoc 'bll json-msg))
						   :mp (cdr (assoc 'mp json-msg))
						   :lf (cdr (assoc 'lf json-msg))
						   :bouts (cdr (assoc 'bouts json-msg))
						   :schedule (cdr (assoc 'schedule json-msg))
						   :numiterations (cdr (assoc 'numiterations json-msg)))))
		;;(vom:debug ";; Result is ~S" response)
		(setf response (json:encode-json-to-string response))
		;;(vom:debug ";; Sending ~S" response)
		(vom:debug ";; Sending response of length ~S" (length response))
		(format stream "~S~%" response)
		(finish-output stream))))))
    (error (e) (vom:error "Error processing request: ~A" e)))
  )


;; LOAD NBACK MODEL
(load "nBack-model-main.lisp")

(defun start-server ()
  (usocket:socket-server nil +port+ #'process-request))


;;; Declarative chunks for zero-back HCP WM model

;;;(add-dm 
;;;	(cue isa chunk)
;;;	(find isa chunk)
;;;	(parse isa chunk)
;;;	(encode isa chunk)
;;;	(compare isa chunk)
;;;	(retrieve isa chunk)
;;;	(stimulus isa chunk))
	
;;; create and set the initial goal
(add-dm
 (do-nback isa parse-item state start stage interact nback nil seen "0" position nil target nil trial nil)
 (selfChunk isa self identity me))

(goal-focus do-nback)

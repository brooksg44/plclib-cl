;;;; pulse.lisp

(in-package #:plclib-cl)

(defclass pulse-detector ()
  ((previous-input
    :initform nil
    :accessor pulse-previous-input
    :type boolean
    :documentation "Previous input state for edge detection")
   (rising-edge-output
    :initform nil
    :accessor pulse-rising-edge-output
    :type boolean
    :documentation "Rising edge detection output")
   (falling-edge-output
    :initform nil
    :accessor pulse-falling-edge-output
    :type boolean
    :documentation "Falling edge detection output"))
  (:documentation "PLC-style pulse/edge detector class"))

(defun make-pulse-detector ()
  "Create a new pulse detector"
  (make-instance 'pulse-detector))

(defmethod pulse-update ((detector pulse-detector) input)
  "Update pulse detector with new input and detect edges"
  (let ((current-input (if input t nil))
        (prev-input (pulse-previous-input detector)))
    
    ;; Detect rising edge
    (setf (pulse-rising-edge-output detector)
          (and current-input (not prev-input)))
    
    ;; Detect falling edge
    (setf (pulse-falling-edge-output detector)
          (and (not current-input) prev-input))
    
    ;; Update previous input
    (setf (pulse-previous-input detector) current-input)
    
    ;; Return current input state
    current-input))

(defmethod rising-edge ((detector pulse-detector) input)
  "Detect rising edge of input signal"
  (pulse-update detector input)
  (pulse-rising-edge-output detector))

(defmethod falling-edge ((detector pulse-detector) input)
  "Detect falling edge of input signal"
  (pulse-update detector input)
  (pulse-falling-edge-output detector))

(defmethod any-edge ((detector pulse-detector) input)
  "Detect any edge (rising or falling) of input signal"
  (pulse-update detector input)
  (or (pulse-rising-edge-output detector)
      (pulse-falling-edge-output detector)))

(defmethod pulse-reset ((detector pulse-detector))
  "Reset pulse detector state"
  (setf (pulse-previous-input detector) nil)
  (setf (pulse-rising-edge-output detector) nil)
  (setf (pulse-falling-edge-output detector) nil))

;; Convenience functions for quick edge detection
(defparameter *global-pulse-detectors* (make-hash-table)
  "Global hash table for pulse detectors by ID")

(defun get-pulse-detector (detector-id)
  "Get or create a pulse detector by ID"
  (or (gethash detector-id *global-pulse-detectors*)
      (setf (gethash detector-id *global-pulse-detectors*)
            (make-pulse-detector))))

(defun rising-edge-by-id (detector-id input)
  "Detect rising edge using detector identified by ID"
  (rising-edge (get-pulse-detector detector-id) input))

(defun falling-edge-by-id (detector-id input)
  "Detect falling edge using detector identified by ID"
  (falling-edge (get-pulse-detector detector-id) input))

(defun any-edge-by-id (detector-id input)
  "Detect any edge using detector identified by ID"
  (any-edge (get-pulse-detector detector-id) input))
;;;; counters.lisp

(in-package #:plclib-cl)

(defclass counter ()
  ((count-value
    :initarg :count-value
    :initform 0
    :accessor counter-value
    :type integer
    :documentation "Current count value")
   (preset-value
    :initarg :preset-value
    :initform 0
    :accessor counter-preset
    :type integer
    :documentation "Preset count value")
   (up-input-prev
    :initform nil
    :accessor counter-up-input-prev
    :type boolean
    :documentation "Previous state of up input")
   (down-input-prev
    :initform nil
    :accessor counter-down-input-prev
    :type boolean
    :documentation "Previous state of down input")
   (reset-input-prev
    :initform nil
    :accessor counter-reset-input-prev
    :type boolean
    :documentation "Previous state of reset input"))
  (:documentation "PLC-style counter class"))

(defmethod initialize-instance :after ((counter counter) &key)
  "Initialize counter after creation"
  (setf (counter-up-input-prev counter) nil)
  (setf (counter-down-input-prev counter) nil)
  (setf (counter-reset-input-prev counter) nil))

(defun make-counter (&optional (preset 0))
  "Create a new counter with optional preset value"
  (make-instance 'counter :preset-value preset))

(defmethod counter-up ((counter counter) input)
  "Count up on rising edge of input"
  (let ((rising-edge (and input (not (counter-up-input-prev counter)))))
    (setf (counter-up-input-prev counter) input)
    (when rising-edge
      (incf (counter-value counter)))
    (counter-done-p counter)))

(defmethod counter-down ((counter counter) input)
  "Count down on rising edge of input"
  (let ((rising-edge (and input (not (counter-down-input-prev counter)))))
    (setf (counter-down-input-prev counter) input)
    (when rising-edge
      (setf (counter-value counter) 
            (max 0 (1- (counter-value counter)))))
    (counter-done-p counter)))

(defmethod counter-reset ((counter counter) reset-input)
  "Reset counter when reset input is active"
  (let ((reset-edge (and reset-input (not (counter-reset-input-prev counter)))))
    (setf (counter-reset-input-prev counter) reset-input)
    (when reset-edge
      (setf (counter-value counter) 0))
    (counter-done-p counter)))

(defmethod counter-done-p ((counter counter))
  "Check if counter has reached or exceeded preset value"
  (>= (counter-value counter) (counter-preset counter)))

(defmethod counter-underdone-p ((counter counter))
  "Check if counter is below preset value"
  (< (counter-value counter) (counter-preset counter)))

(defmethod counter-set-preset ((counter counter) preset)
  "Set the preset value for the counter"
  (setf (counter-preset counter) preset))

(defmethod counter-clear ((counter counter))
  "Clear the counter value to 0"
  (setf (counter-value counter) 0))
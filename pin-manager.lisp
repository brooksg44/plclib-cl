;;;; pin-manager.lisp

(in-package #:plclib-cl)

(defun get-pin-state (pin-number)
  "Get or create pin state for the given pin number"
  (or (gethash pin-number *pin-states*)
      (setf (gethash pin-number *pin-states*)
            (make-pin-state :number pin-number))))

(defun set-pin-mode (pin-number mode)
  "Set the mode for a pin (:input, :output, :input-pullup)"
  (let ((pin-state (get-pin-state pin-number)))
    (setf (pin-state-mode pin-state) mode)
    pin-state))

(defun update-pin-value (pin-number value)
  "Update pin value and track previous value"
  (let ((pin-state (get-pin-state pin-number)))
    (setf (pin-state-previous-value pin-state) 
          (pin-state-current-value pin-state))
    (setf (pin-state-current-value pin-state) value)
    (setf (pin-state-last-update pin-state) (get-current-time-ms))
    pin-state))

(defun read-pin-value (pin-number)
  "Read current pin value"
  (pin-state-current-value (get-pin-state pin-number)))

(defun read-pin-previous-value (pin-number)
  "Read previous pin value"
  (pin-state-previous-value (get-pin-state pin-number)))

(defun simulate-digital-read (pin-number)
  "Simulate digital read - returns stored value or 0"
  (read-pin-value pin-number))

(defun simulate-analog-read (pin-number)
  "Simulate analog read - returns stored value or 0"
  (read-pin-value pin-number))

(defun simulate-digital-write (pin-number value)
  "Simulate digital write - stores the value"
  (update-pin-value pin-number (if (zerop value) 0 1)))

(defun simulate-analog-write (pin-number value)
  "Simulate analog/PWM write - stores the value"
  (update-pin-value pin-number (min 255 (max 0 value))))
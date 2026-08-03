;;;; types.lisp

(in-package #:plclib-cl)

(deftype pin-number ()
  "Type for pin numbers (0-255)"
  '(integer 0 255))

(deftype digital-value ()
  "Type for digital pin values (0 or 1)"
  '(integer 0 1))

(deftype analog-value ()
  "Type for analog values (0-1023)"
  '(integer 0 1023))

(deftype pwm-value ()
  "Type for PWM values (0-255)"
  '(integer 0 255))

(deftype pin-mode ()
  "Pin mode types"
  '(member :input :output :input-pullup))

(defstruct pin-state
  "Structure to track pin state and previous values"
  (number 0 :type pin-number)
  (mode :input :type pin-mode)
  (current-value 0 :type (or digital-value analog-value))
  (previous-value 0 :type (or digital-value analog-value))
  (last-update 0 :type (unsigned-byte 64)))

(defparameter *scan-value* 0
  "Global scan accumulator, holding the result carried between rung
operations. Digital operations leave 0 or 1 here; INPUT-ANALOG leaves a
raw 0-1023 reading, which COMPARE-* reduce back to 0 or 1.")

(defparameter *pin-states* (make-hash-table)
  "Hash table to store pin states")

(defparameter *serial-enabled* nil
  "Flag to enable/disable serial output")

(defparameter *scan-time* 0
  "Current scan time in milliseconds")

(defun get-current-time-ms ()
  "Get current time in milliseconds"
  #+sbcl
  (multiple-value-bind (seconds microseconds)
      (sb-ext:get-time-of-day)
    (+ (* seconds 1000) (floor microseconds 1000)))
  #+ccl
  (floor (ccl:current-time-in-nanoseconds) 1000000)
  #-(or sbcl ccl)
  (round (* (get-internal-real-time) 1000) internal-time-units-per-second))
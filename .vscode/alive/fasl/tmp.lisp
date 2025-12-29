;;;; io.lisp

(in-package #:plclib-cl)

;; Input functions
(defun input (pin-number)
  "Read digital input from pin"
  (simulate-digital-read pin-number))

(defun input-not (pin-number)
  "Read inverted digital input from pin"
  (if (zerop (simulate-digital-read pin-number)) 1 0))

(defun input-analog (pin-number)
  "Read analog input from pin"
  (simulate-analog-read pin-number))

;; Output functions
(defun output (pin-number value)
  "Write digital output to pin"
  (simulate-digital-write pin-number (if value 1 0))
  (setf *scan-value* (if value 1 0)))

(defun output-not (pin-number value)
  "Write inverted digital output to pin"
  (simulate-digital-write pin-number (if value 0 1))
  (setf *scan-value* (if value 0 1)))

(defun output-pwm (pin-number value)
  "Write PWM output to pin (0-255)"
  (simulate-analog-write pin-number value)
  (setf *scan-value* value))

;; Utility functions for I/O
(defun map-analog (value in-min in-max out-min out-max)
  "Map analog value from one range to another"
  (round (+ out-min (* (/ (- value in-min) (- in-max in-min))
                       (- out-max out-min)))))

(defun constrain-value (value min-val max-val)
  "Constrain value to specified range"
  (max min-val (min max-val value)))

;; Serial communication simulation
(defparameter *serial-output-stream* *standard-output*
  "Stream for serial output")

(defun serial-begin (&optional (baud-rate 9600))
  "Initialize serial communication"
  (setf *serial-enabled* t)
  (when *serial-enabled*
    (format *serial-output-stream* "Serial initialized at ~A baud~%" baud-rate)))

(defun serial-print (message)
  "Print message to serial output"
  (when *serial-enabled*
    (format *serial-output-stream* "~A" message)))

(defun serial-println (message)
  "Print message with newline to serial output"
  (when *serial-enabled*
    (format *serial-output-stream* "~A~%" message)))

(defun serial-print-value (label value)
  "Print labeled value to serial output"
  (when *serial-enabled*
    (format *serial-output-stream* "~A: ~A~%" label value)))

;; Input validation and conditioning
(defun debounce-input (pin-number debounce-time-ms)
  "Debounce digital input with specified time"
  (let ((pin-state (get-pin-state pin-number))
        (current-time (get-current-time-ms)))
    (let ((current-value (simulate-digital-read pin-number))
          (stable-time (- current-time (pin-state-last-update pin-state))))
      (if (= current-value (pin-state-current-value pin-state))
          ;; Value hasn't changed, check if stable long enough
          (>= stable-time debounce-time-ms)
          ;; Value changed, reset stability timer
          (progn
            (setf (pin-state-last-update pin-state) current-time)
            nil)))))

(defun filter-analog (pin-number alpha)
  "Apply exponential moving average filter to analog input"
  (let ((pin-state (get-pin-state pin-number)))
    (let ((current-value (simulate-analog-read pin-number))
          (filtered-value (coerce (pin-state-current-value pin-state) 'double-float)))
      (setf filtered-value 
            (+ (* alpha (coerce current-value 'double-float)) 
               (* (- 1.0d0 alpha) filtered-value)))
      (let ((rounded-value (round filtered-value)))
        (setf (pin-state-current-value pin-state) rounded-value)
        rounded-value))))

;; Diagnostic and monitoring functions
(defun get-pin-info (pin-number)
  "Get comprehensive information about a pin"
  (let ((pin-state (get-pin-state pin-number)))
    (list :pin pin-number
          :mode (pin-state-mode pin-state)
          :current-value (pin-state-current-value pin-state)
          :previous-value (pin-state-previous-value pin-state)
          :last-update (pin-state-last-update pin-state))))

(defun list-active-pins ()
  "List all pins that have been accessed"
  (let ((pins '()))
    (maphash (lambda (pin-number pin-state)
               (declare (ignore pin-state))
               (push pin-number pins))
             *pin-states*)
    (sort pins #'<)))

(defun reset-all-pins ()
  "Reset all pin states"
  (clrhash *pin-states*))
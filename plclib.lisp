;;;; plclib.lisp

(in-package #:plclib-cl)

;; Main PLC scan and control functions

(defparameter *plc-running* nil
  "Flag indicating if PLC is running")

(defparameter *scan-cycle-time* 10
  "Scan cycle time in milliseconds")

(defparameter *scan-count* 0
  "Number of scans completed")

(defparameter *max-scan-time* 0
  "Maximum scan time recorded")

(defparameter *min-scan-time* most-positive-fixnum
  "Minimum scan time recorded")

(defparameter *avg-scan-time* 0
  "Average scan time")

(defun plc-init ()
  "Initialize PLC system"
  (setf *scan-value* nil)
  (setf *scan-time* (get-current-time-ms))
  (setf *plc-running* nil)
  (setf *scan-count* 0)
  (setf *max-scan-time* 0)
  (setf *min-scan-time* most-positive-fixnum)
  (setf *avg-scan-time* 0)
  (clrhash *pin-states*)
  (clrhash *timers*)
  (clrhash *global-pulse-detectors*)
  (when *serial-enabled*
    (serial-println "PLC System Initialized")))

(defun plc-reset ()
  "Reset PLC system"
  (plc-init))

(defun plc-start ()
  "Start PLC operation"
  (setf *plc-running* t)
  (when *serial-enabled*
    (serial-println "PLC Started")))

(defun plc-stop ()
  "Stop PLC operation"
  (setf *plc-running* nil)
  (when *serial-enabled*
    (serial-println "PLC Stopped")))

(defun plc-scan ()
  "Perform one PLC scan cycle"
  (let ((scan-start (get-current-time-ms)))
    
    ;; Update scan time
    (setf *scan-time* scan-start)
    
    ;; Increment scan counter
    (incf *scan-count*)
    
    ;; Update all pin states (simulate hardware reads)
    ;; In a real implementation, this would read from actual hardware
    
    ;; Calculate scan time statistics
    (let* ((scan-end (get-current-time-ms))
           (scan-duration (- scan-end scan-start)))
      (setf *max-scan-time* (max *max-scan-time* scan-duration))
      (setf *min-scan-time* (min *min-scan-time* scan-duration))
      (setf *avg-scan-time* (/ (+ (* *avg-scan-time* (1- *scan-count*)) 
                                  scan-duration)
                               *scan-count*))
      
      ;; Return scan statistics
      (list :scan-count *scan-count*
            :scan-time scan-duration
            :max-scan-time *max-scan-time*
            :min-scan-time *min-scan-time*
            :avg-scan-time *avg-scan-time*))))

(defun plc-run-continuous (&optional (cycle-time-ms 10))
  "Run PLC in continuous mode with specified cycle time"
  (setf *scan-cycle-time* cycle-time-ms)
  (plc-start)
  
  ;; This would typically be implemented with threads in a real application
  ;; For demonstration purposes, we'll just show the concept
  (when *serial-enabled*
    (serial-println (format nil "PLC running continuously with ~Ams cycle time" 
                           cycle-time-ms))))

(defun get-scan-value ()
  "Get current scan value"
  *scan-value*)

(defun set-scan-value (value)
  "Set current scan value"
  (setf *scan-value* value))

;; Diagnostic and monitoring functions
(defun get-plc-status ()
  "Get comprehensive PLC status information"
  (list :running *plc-running*
        :scan-count *scan-count*
        :scan-time *scan-time*
        :max-scan-time *max-scan-time*
        :min-scan-time (if (= *min-scan-time* most-positive-fixnum) 0 *min-scan-time*)
        :avg-scan-time *avg-scan-time*
        :cycle-time *scan-cycle-time*
        :active-pins (length (list-active-pins))
        :active-timers (hash-table-count *timers*)
        :active-pulse-detectors (hash-table-count *global-pulse-detectors*)))

(defun print-plc-status ()
  "Print PLC status to serial output"
  (when *serial-enabled*
    (let ((status (get-plc-status)))
      (serial-println "=== PLC Status ===")
      (serial-println (format nil "Running: ~A" (getf status :running)))
      (serial-println (format nil "Scan Count: ~A" (getf status :scan-count)))
      (serial-println (format nil "Max Scan Time: ~Ams" (getf status :max-scan-time)))
      (serial-println (format nil "Min Scan Time: ~Ams" (getf status :min-scan-time)))
      (serial-println (format nil "Avg Scan Time: ~,2Fms" (getf status :avg-scan-time)))
      (serial-println (format nil "Active Pins: ~A" (getf status :active-pins)))
      (serial-println (format nil "Active Timers: ~A" (getf status :active-timers)))
      (serial-println "================"))))

;; Hardware simulation functions
(defun simulate-input-change (pin-number value)
  "Simulate an input change for testing"
  (update-pin-value pin-number value)
  (when *serial-enabled*
    (serial-println (format nil "Pin ~A input changed to ~A" pin-number value))))

(defun simulate-analog-input-change (pin-number value)
  "Simulate an analog input change for testing"
  (update-pin-value pin-number (constrain-value value 0 1023))
  (when *serial-enabled*
    (serial-println (format nil "Pin ~A analog input changed to ~A" 
                           pin-number value))))

;; Convenience macros for PLC programming style
(defmacro with-plc-scan (&body body)
  "Execute body within a PLC scan context"
  `(progn
     (plc-scan)
     (progn ,@body)))

(defmacro plc-rung (condition &body outputs)
  "Define a PLC rung with condition and outputs"
  `(when ,condition
     ,@outputs))

(defmacro contact-no (pin)
  "Normally Open contact"
  `(input ,pin))

(defmacro contact-nc (pin)
  "Normally Closed contact" 
  `(input-not ,pin))

(defmacro coil (pin value)
  "Output coil"
  `(output ,pin ,value))

;; Example ladder logic helper functions
(defun start-stop-circuit (start-pin stop-pin output-pin memory-bit)
  "Implement typical start/stop circuit with memory"
  (let ((start-contact (contact-no start-pin))
        (stop-contact (contact-nc stop-pin))
        (memory-contact (if memory-bit 1 0)))
    (let ((result (plc-and stop-contact 
                          (plc-or start-contact memory-contact))))
      (coil output-pin result)
      result)))
;;;; examples.lisp

(in-package #:plclib-cl)

;; Example 1: Basic Input/Output
(defun example-basic-io ()
  "Demonstrate basic input/output operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Basic I/O Example ===")

  ;; Set up pin modes
  (set-pin-mode 2 :input)    ; Input pin
  (set-pin-mode 13 :output)  ; Output pin

  ;; Simulate input changes and show output response
  (simulate-input-change 2 1)
  (let ((input-state (input 2)))
    (output 13 input-state)
    (serial-print-value "Input Pin 2" input-state)
    (serial-print-value "Output Pin 13" (read-pin-value 13)))

  (simulate-input-change 2 0)
  (let ((input-state (input 2)))
    (output 13 input-state)
    (serial-print-value "Input Pin 2" input-state)
    (serial-print-value "Output Pin 13" (read-pin-value 13))))

;; Example 2: Timer Operations
(defun example-timers ()
  "Demonstrate timer operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Timer Example ===")

  ;; Timer ON example
  (simulate-input-change 3 1)
  (let ((timer-output (timer-on (input 3) 'timer1 1000))) ; 1 second delay
    (serial-print-value "Timer ON Output" timer-output))

  ;; Simulate time passing (in real application, this would happen naturally)
  (sleep 1.5)
  (let ((timer-output (timer-on (input 3) 'timer1 1000)))
    (serial-print-value "Timer ON Output (after delay)" timer-output))

  ;; Timer PULSE example
  (let ((pulse-output (timer-pulse t 'pulse-timer 500))) ; 500ms pulse
    (serial-print-value "Timer PULSE Output" pulse-output)))

;; Example 3: Counter Operations
(defun example-counters ()
  "Demonstrate counter operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Counter Example ===")

  (let ((counter (make-counter 5))) ; Preset to 5
    ;; Simulate count pulses
    (loop for i from 1 to 7 do
      (simulate-input-change 4 1)
      (counter-up counter (input 4))
      (simulate-input-change 4 0)
      (counter-up counter (input 4))
      (serial-println (format nil "Count: ~A, Done: ~A"
                             (counter-value counter)
                             (counter-done-p counter))))))

;; Example 4: Shift Register
(defun example-shift-register ()
  "Demonstrate shift register operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Shift Register Example ===")

  (let ((shifter (make-shift-register 8)))
    ;; Load some data and shift
    (shift-load shifter t #b10101010)
    (serial-println (format nil "Initial bits: ~8,'0B" (shift-bits shifter)))

    ;; Shift left with data
    (shift-left shifter t t) ; Shift left, load 1
    (serial-println (format nil "After shift left: ~8,'0B" (shift-bits shifter)))

    (shift-left shifter t nil) ; Shift left, load 0
    (serial-println (format nil "After shift left: ~8,'0B" (shift-bits shifter)))))

;; Example 5: Edge Detection
(defun example-edge-detection ()
  "Demonstrate edge detection"
  (plc-init)
  (serial-begin)
  (serial-println "=== Edge Detection Example ===")

  (let ((detector (make-pulse-detector)))
    ;; Test rising edge
    (rising-edge detector nil)
    (serial-print-value "Rising edge (0->0)" (rising-edge detector nil))
    (serial-print-value "Rising edge (0->1)" (rising-edge detector t))
    (serial-print-value "Rising edge (1->1)" (rising-edge detector t))
    (serial-print-value "Falling edge (1->0)" (falling-edge detector nil))))

;; Example 6: Logic Operations
(defun example-logic-operations ()
  "Demonstrate logic operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Logic Operations Example ===")

  ;; Set up some inputs
  (simulate-input-change 5 1)
  (simulate-input-change 6 0)
  (simulate-input-change 7 1)

  (let ((input5 (input 5))
        (input6 (input 6))
        (input7 (input 7)))
    (serial-print-value "Input 5" input5)
    (serial-print-value "Input 6" input6)
    (serial-print-value "Input 7" input7)

    (serial-print-value "AND 5,6,7" (plc-and input5 input6 input7))
    (serial-print-value "OR 5,6,7" (plc-or input5 input6 input7))
    (serial-print-value "XOR 5,6,7" (plc-xor input5 input6 input7))
    (serial-print-value "NOT 5" (plc-not input5))))

;; Example 7: Start/Stop Circuit
(defun example-start-stop-circuit ()
  "Demonstrate typical start/stop motor circuit"
  (plc-init)
  (serial-begin)
  (serial-println "=== Start/Stop Circuit Example ===")

  (set-pin-mode 8 :input)   ; Start button
  (set-pin-mode 9 :input)   ; Stop button
  (set-pin-mode 10 :output) ; Motor output

  (let ((motor-running nil))
    ;; Test start sequence
    (simulate-input-change 8 1) ; Press start
    (simulate-input-change 9 0) ; Stop button not pressed
    (setf motor-running (start-stop-circuit 8 9 10 motor-running))
    (serial-print-value "Motor running after start" motor-running)

    ;; Test stop sequence
    (simulate-input-change 8 0) ; Release start
    (simulate-input-change 9 1) ; Press stop
    (setf motor-running (start-stop-circuit 8 9 10 motor-running))
    (serial-print-value "Motor running after stop" motor-running)))

;; Example 8: Analog Processing
(defun example-analog-processing ()
  "Demonstrate analog input processing"
  (plc-init)
  (serial-begin)
  (serial-println "=== Analog Processing Example ===")

  ;; Simulate analog input
  (simulate-analog-input-change 0 512) ; Mid-range value

  (let ((analog-value (input-analog 0)))
    (serial-print-value "Raw analog value" analog-value)

    ;; Scale to percentage
    (let ((percentage (map-analog analog-value 0 1023 0 100)))
      (serial-print-value "Percentage" percentage))

    ;; Scale to engineering units (e.g., temperature)
    (let ((temperature (map-analog analog-value 0 1023 -40 125)))
      (serial-print-value "Temperature (C)" temperature))))

;; Example 9: Stack Operations
(defun example-stack-operations ()
  "Demonstrate stack operations"
  (plc-init)
  (serial-begin)
  (serial-println "=== Stack Operations Example ===")

  (let ((stack (make-stack)))
    (stack-push stack t)
    (stack-push stack nil)
    (stack-push stack t)

    (serial-print-value "Stack size" (stack-size stack))
    (serial-print-value "Top value" (stack-top stack))

    ;; Perform AND operation
    (stack-and stack)
    (serial-print-value "After AND" (stack-top stack))

    ;; Perform OR operation
    (stack-push stack t)
    (stack-or stack)
    (serial-print-value "After OR" (stack-top stack))))

;; Example 10: Complete PLC Program
(defun example-complete-plc-program ()
  "Demonstrate a complete PLC program with multiple rungs"
  (plc-init)
  (serial-begin)
  (serial-println "=== Complete PLC Program Example ===")

  ;; Initialize system
  (set-pin-mode 0 :input)   ; Emergency stop
  (set-pin-mode 1 :input)   ; Start button
  (set-pin-mode 2 :input)   ; Level sensor
  (set-pin-mode 10 :output) ; Pump motor
  (set-pin-mode 11 :output) ; Alarm lamp
  (set-pin-mode 12 :output) ; Running lamp

  (let ((pump-running nil)
        (alarm-state nil)
        (level-detector (make-pulse-detector)))

    ;; Main control logic
    (loop for cycle from 1 to 5 do
      (serial-println (format nil "--- Scan Cycle ~A ---" cycle))

      ;; Rung 1: Emergency stop check
      (let ((e-stop (input-not 0))) ; Normally closed E-stop
        (unless e-stop
          (setf pump-running nil)
          (setf alarm-state t)
          (serial-println "EMERGENCY STOP ACTIVATED")))

      ;; Rung 2: Start/Stop logic with level interlock
      (when (input-not 0) ; E-stop not active
        (let ((start-btn (input 1))
              (level-ok (input 2)))
          (when (and start-btn level-ok)
            (setf pump-running t))
          (unless level-ok
            (setf pump-running nil))))

      ;; Rung 3: Output assignments
      (output 10 pump-running)     ; Pump motor
      (output 11 alarm-state)      ; Alarm lamp
      (output 12 pump-running)     ; Running lamp

      ;; Rung 4: Level monitoring with edge detection
      (when (falling-edge level-detector (input 2))
        (serial-println "WARNING: Level sensor triggered"))

      ;; Print status
      (serial-print-value "Pump Running" pump-running)
      (serial-print-value "Alarm Active" alarm-state)
      (serial-print-value "Level OK" (input 2))

      ;; Simulate some input changes
      (case cycle
        (1 (simulate-input-change 0 0)  ; E-stop OK
           (simulate-input-change 2 1)) ; Level OK
        (2 (simulate-input-change 1 1)) ; Press start
        (3 (simulate-input-change 1 0)) ; Release start
        (4 (simulate-input-change 2 0)) ; Level fail
        (5 (simulate-input-change 2 1))) ; Level OK again

      (sleep 0.1))))

;; Function to run all examples
(defparameter *all-examples*
  '(example-basic-io
    example-timers
    example-counters
    example-shift-register
    example-edge-detection
    example-logic-operations
    example-start-stop-circuit
    example-analog-processing
    example-stack-operations
    example-complete-plc-program)
  "Example programs run by RUN-ALL-EXAMPLES, in order")

(defun run-all-examples ()
  "Run all example programs, separated by a blank line"
  (serial-begin)
  (serial-println "Starting PLC-CL Examples...")

  (let ((*announce-init* nil))
    (dolist (example *all-examples*)
      (serial-println "")
      (funcall example)))

  (serial-println "")
  (serial-println "All examples completed!"))
;;;; package.lisp

(defpackage #:plclib-cl
  (:use #:cl)
  (:export
   ;; Core PLC functionality
   #:plc-scan
   #:plc-init
   #:plc-reset
   
   ;; Pin and I/O management
   #:input
   #:input-not
   #:input-analog
   #:output
   #:output-not
   #:output-pwm
   #:load-value
   #:output-value
   #:output-not-value
   #:output-pwm-value
   #:set-pin-mode
   #:simulate-input-change
   #:simulate-analog-input-change
   #:read-pin-value
   #:get-pin-info
   #:list-active-pins
   #:reset-all-pins
   
   ;; Timer functions
   #:timer-on
   #:timer-off
   #:timer-pulse
   #:timer-cycle
   
   ;; Counter class and functions
   #:counter
   #:make-counter
   #:counter-up
   #:counter-down
   #:counter-reset
   #:counter-preset
   #:counter-done-p
   #:counter-value
   
   ;; Shift register class and functions
   #:shift-register
   #:make-shift-register
   #:shift-left
   #:shift-right
   #:shift-reset
   #:shift-load
   #:shift-bits
   
   ;; Stack class and functions
   #:stack
   #:make-stack
   #:stack-push
   #:stack-pop
   #:stack-and
   #:stack-or
   #:stack-load
   #:stack-empty-p
   
   ;; Pulse detection
   #:pulse-detector
   #:make-pulse-detector
   #:rising-edge
   #:falling-edge
   
   ;; Scan accumulator bit operations
   #:*scan-value*
   #:get-scan-value
   #:set-scan-value
   #:and-bit
   #:and-not-bit
   #:or-bit
   #:or-not-bit
   #:xor-bit
   #:and-bit-value
   #:and-not-bit-value
   #:or-bit-value
   #:or-not-bit-value
   #:xor-bit-value

   ;; Logic operations
   #:plc-truthy
   #:plc-and
   #:plc-or
   #:plc-xor
   #:plc-not
   #:compare-gt
   #:compare-lt
   #:compare-eq
   #:compare-ne
   #:compare-ge
   #:compare-le
   
   ;; Serial monitoring
   #:serial-print
   #:serial-println
   #:serial-begin
   #:serial-print-value
   
   ;; PLC system control
   #:plc-start
   #:plc-stop
   #:get-plc-status
   #:print-plc-status
   #:plc-run-continuous
   
   ;; Examples
   #:run-all-examples
   
   ;; Ladder logic helpers
   #:plc-rung
   #:contact-no
   #:contact-nc
   #:coil
   #:start-stop-circuit))
;;;; logic.lisp

(in-package #:plclib-cl)

(defun plc-truthy (input)
  "True when INPUT represents an energised signal.

PLC contacts are read as the integers 0 and 1, but every non-NIL value is true
in Common Lisp, so 0 would otherwise count as energised. This treats 0 and NIL
as de-energised and anything else as energised, which lets the functions below
accept contact readings and booleans interchangeably."
  (cond ((null input) nil)
        ((numberp input) (not (zerop input)))
        (t t)))

(defun plc-and (&rest inputs)
  "PLC AND operation - returns true if all inputs are true"
  (every #'plc-truthy inputs))

(defun plc-or (&rest inputs)
  "PLC OR operation - returns true if any input is true"
  (some #'plc-truthy inputs))

(defun plc-xor (&rest inputs)
  "PLC XOR operation - returns true if odd number of inputs are true"
  (oddp (count-if #'plc-truthy inputs)))

(defun plc-not (input)
  "PLC NOT operation - returns logical inverse of input"
  (not (plc-truthy input)))

(defun plc-nand (&rest inputs)
  "PLC NAND operation - NOT AND"
  (not (apply #'plc-and inputs)))

(defun plc-nor (&rest inputs)
  "PLC NOR operation - NOT OR"
  (not (apply #'plc-or inputs)))

;; Comparison functions
(defun compare-eq (val1 val2)
  "Compare equal"
  (= val1 val2))

(defun compare-ne (val1 val2)
  "Compare not equal"
  (not (= val1 val2)))

(defun compare-gt (val1 val2)
  "Compare greater than"
  (> val1 val2))

(defun compare-ge (val1 val2)
  "Compare greater than or equal"
  (>= val1 val2))

(defun compare-lt (val1 val2)
  "Compare less than"
  (< val1 val2))

(defun compare-le (val1 val2)
  "Compare less than or equal"
  (<= val1 val2))

;; Range checking
(defun in-range (value min-val max-val)
  "Check if value is within range (inclusive)"
  (and (>= value min-val) (<= value max-val)))

(defun out-of-range (value min-val max-val)
  "Check if value is outside range"
  (not (in-range value min-val max-val)))

;; Bit manipulation functions
(defun get-bit (value bit-position)
  "Get bit at specified position (0-based)"
  (if (logbitp bit-position value) 1 0))

(defun set-bit (value bit-position)
  "Set bit at specified position"
  (logior value (ash 1 bit-position)))

(defun clear-bit (value bit-position)
  "Clear bit at specified position"
  (logand value (lognot (ash 1 bit-position))))

(defun toggle-bit (value bit-position)
  "Toggle bit at specified position"
  (logxor value (ash 1 bit-position)))

;; Word operations
(defun high-byte (word-value)
  "Get high byte of 16-bit word"
  (logand (ash word-value -8) #xFF))

(defun low-byte (word-value)
  "Get low byte of 16-bit word"
  (logand word-value #xFF))

(defun make-word (high-byte low-byte)
  "Make 16-bit word from high and low bytes"
  (logior (ash (logand high-byte #xFF) 8)
          (logand low-byte #xFF)))

;; Math functions commonly used in PLC
(defun scale-linear (input in-min in-max out-min out-max)
  "Linear scaling function"
  (+ out-min (* (/ (- input in-min) (- in-max in-min))
                (- out-max out-min))))

(defun deadband (input center-value band-width)
  "Apply deadband around center value"
  (let ((half-band (/ band-width 2)))
    (cond
      ((< input (- center-value half-band)) input)
      ((> input (+ center-value half-band)) input)
      (t center-value))))

(defun hysteresis (input on-threshold off-threshold previous-state)
  "Hysteresis function with on/off thresholds"
  (cond
    ((>= input on-threshold) t)
    ((<= input off-threshold) nil)
    (t previous-state)))
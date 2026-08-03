;;;; bitops.lisp
;;;;
;;;; Scan-accumulator bit operations, combining *SCAN-VALUE* with a pin reading
;;;; or a value. These were missing from the port entirely; the Arduino original
;;;; spells them andBit, andNotBit, orBit, orNotBit and xorBit.
;;;;
;;;; A rung reads as a sequence of operations on the accumulator:
;;;;
;;;;     (input 0)           ; load X0
;;;;     (and-not-bit 1)     ; AND with NOT X1
;;;;     (or-bit 2)          ; OR with X2
;;;;     (output-coil 100)   ; drive the coil
;;;;
;;;; Upstream combines the accumulator with the operand using C bitwise
;;;; operators on unsigned int, not logical ones, and this port follows it.
;;;; The two agree whenever the accumulator holds 0 or 1, which is every
;;;; well-formed rung; they differ only for a raw INPUT-ANALOG reading that has
;;;; not been reduced by COMPARE-GT or COMPARE-LT.
;;;;
;;;; Note that AND-NOT-BIT uses bitwise complement, matching upstream's
;;;; "scanValue & ~input" rather than a logical negation. LOGANDC2 gives
;;;; exactly that, and unlike C it needs no assumption about integer width.
;;;;
;;;; Each operation comes in two forms. The -VALUE form takes the operand
;;;; directly and corresponds to upstream's unsigned int overload, used to
;;;; combine with a memory bit. The plain form reads a pin and corresponds to
;;;; upstream's int overload. C++ picks between them by argument type; Common
;;;; Lisp cannot, since a pin number and a value are both just integers, so
;;;; they get separate names.

(in-package #:plclib-cl)

;;; Value forms - combine the accumulator with an operand directly

(defun and-bit-value (value)
  "AND the scan accumulator with VALUE (upstream: scanValue & input)"
  (setf *scan-value* (logand *scan-value* value)))

(defun and-not-bit-value (value)
  "AND the scan accumulator with NOT VALUE (upstream: scanValue & ~input)"
  (setf *scan-value* (logandc2 *scan-value* value)))

(defun or-bit-value (value)
  "OR the scan accumulator with VALUE (upstream: scanValue | input)"
  (setf *scan-value* (logior *scan-value* value)))

(defun or-not-bit-value (value)
  "OR the scan accumulator with NOT VALUE.

Upstream does not use a bitwise expression here; it tests the accumulator
against 1 and otherwise replaces it outright. That looks inconsistent beside
the other four, and it does mean an unreduced analog reading is treated as
false, but this port reproduces upstream rather than correcting it."
  (if (= *scan-value* 1)
      *scan-value*
      (setf *scan-value* (if (zerop value) 1 0))))

(defun xor-bit-value (value)
  "XOR the scan accumulator with VALUE (upstream: scanValue ^ input)"
  (setf *scan-value* (logxor *scan-value* value)))

;;; Pin forms - read the pin, then combine

(defun and-bit (pin-number)
  "AND the scan accumulator with the reading from PIN-NUMBER"
  (and-bit-value (simulate-digital-read pin-number)))

(defun and-not-bit (pin-number)
  "AND the scan accumulator with the inverted reading from PIN-NUMBER"
  (and-not-bit-value (simulate-digital-read pin-number)))

(defun or-bit (pin-number)
  "OR the scan accumulator with the reading from PIN-NUMBER"
  (or-bit-value (simulate-digital-read pin-number)))

(defun or-not-bit (pin-number)
  "OR the scan accumulator with the inverted reading from PIN-NUMBER"
  (or-not-bit-value (simulate-digital-read pin-number)))

(defun xor-bit (pin-number)
  "XOR the scan accumulator with the reading from PIN-NUMBER"
  (xor-bit-value (simulate-digital-read pin-number)))

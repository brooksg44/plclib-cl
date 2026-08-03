;;;; tests.lisp
;;;;
;;;; Test suite for plclib-cl. Run with:
;;;;
;;;;     sbcl --script tests.lisp
;;;;
;;;; Exits non-zero on failure.

(require :asdf)

(let ((here (make-pathname :name nil :type nil :defaults *load-truename*)))
  (push here asdf:*central-registry*))

;; Force a rebuild rather than trusting the fasl cache. ASDF decides by
;; timestamp, which is too coarse when sources are rewritten in quick
;; succession, and a stale fasl makes this suite report on code that is no
;; longer on disk. Recompiling a dozen small files costs little.
(handler-bind ((warning #'muffle-warning))
  (asdf:load-system :plclib-cl :force t))

(in-package #:plclib-cl)

(defvar *checks* 0)
(defvar *failures* 0)

(defun section (name)
  (format t "~&--- ~a ---~%" name))

(defun check (label got want)
  (incf *checks*)
  (unless (equal got want)
    (incf *failures*)
    (format t "~&  FAIL ~a~%       got ~s, wanted ~s~%" label got want))
  (equal got want))

(defmacro guarded (label &body body)
  "Run BODY, turning an unhandled error into a failure.

Without this an error part way through kills the script, so everything after
it silently goes unrun and the summary never prints."
  `(handler-case (progn ,@body)
     (error (e)
       (incf *failures*)
       (format t "~&  ERROR in ~a: ~a~%" ,label e))))

(defun report ()
  (format t "~&~%~d checks, ~d failures~%" *checks* *failures*)
  (format t "~a~%" (if (zerop *failures*) "ALL PASS" "FAILURES")))


;;; ------------------------------------------------------------------
;;; Scan accumulator bit operations
;;;
;;; Upstream combines the accumulator with the operand using C bitwise
;;; operators, so these are checked against LOGAND / LOGANDC2 / LOGIOR /
;;; LOGXOR rather than against boolean logic.
;;; ------------------------------------------------------------------

(section "bit operations agree with the C bitwise semantics")
(let ((mismatches 0)
      (total 0))
  (dolist (a '(0 1 2 5 255 256 511 512 700 1023))
    (dolist (b '(0 1 2 255 512 1023))
      (incf total 4)
      (setf *scan-value* a)
      (unless (= (and-bit-value b) (logand a b)) (incf mismatches))
      (setf *scan-value* a)
      (unless (= (and-not-bit-value b) (logandc2 a b)) (incf mismatches))
      (setf *scan-value* a)
      (unless (= (or-bit-value b) (logior a b)) (incf mismatches))
      (setf *scan-value* a)
      (unless (= (xor-bit-value b) (logxor a b)) (incf mismatches))))
  (check (format nil "~d operand pairs match" total) mismatches 0))

(section "digital truth tables")
(dolist (case '(;; acc operand  and  andnot  or   xor
                (0   0        0    0       0    0)
                (0   1        0    0       1    1)
                (1   0        0    1       1    1)
                (1   1        1    0       1    0)))
  (destructuring-bind (acc operand want-and want-andnot want-or want-xor) case
    (setf *scan-value* acc)
    (check (format nil "~d and-bit ~d" acc operand) (and-bit-value operand) want-and)
    (setf *scan-value* acc)
    (check (format nil "~d and-not-bit ~d" acc operand) (and-not-bit-value operand) want-andnot)
    (setf *scan-value* acc)
    (check (format nil "~d or-bit ~d" acc operand) (or-bit-value operand) want-or)
    (setf *scan-value* acc)
    (check (format nil "~d xor-bit ~d" acc operand) (xor-bit-value operand) want-xor)))

(section "and-not-bit uses bitwise complement, as upstream does")
;; upstream: scanValue & ~input. With a multi-bit accumulator this clears only
;; the bits the operand sets, it does not reduce the result to 0.
(setf *scan-value* 512)
(check "512 and-not-bit 1 -> 512" (and-not-bit-value 1) 512)
(setf *scan-value* 513)
(check "513 and-not-bit 1 -> 512" (and-not-bit-value 1) 512)

(section "or-not-bit keeps upstream's = 1 guard")
;; Deliberately not a bitwise expression upstream. Changing this to a
;; non-zero test would diverge from the original; see bitops.lisp.
(dolist (case '((0 0 1) (0 1 0) (1 0 1) (1 1 1)))
  (destructuring-bind (acc operand want) case
    (setf *scan-value* acc)
    (check (format nil "~d or-not-bit ~d" acc operand) (or-not-bit-value operand) want)))
(setf *scan-value* 512)
(check "512 or-not-bit 1 -> 0, per upstream" (or-not-bit-value 1) 0)

(section "pin forms read the pin then combine")
(plc-init)
(set-pin-mode 0 :input)
(set-pin-mode 1 :input)
(simulate-input-change 0 1)
(simulate-input-change 1 0)
(check "input 0 loads the accumulator" (input 0) 1)
(check "and-bit on a high pin" (and-bit 0) 1)
(check "and-bit on a low pin" (and-bit 1) 0)
(setf *scan-value* 1)
(check "and-not-bit on a low pin" (and-not-bit 1) 1)
(setf *scan-value* 1)
(check "and-not-bit on a high pin" (and-not-bit 0) 0)
(setf *scan-value* 0)
(check "or-bit on a high pin" (or-bit 0) 1)
(setf *scan-value* 0)
(check "or-not-bit on a low pin" (or-not-bit 1) 1)
(setf *scan-value* 0)
(check "xor-bit on a high pin" (xor-bit 0) 1)

(section "a whole rung chains through the accumulator")
(plc-init)
(dolist (p '(0 1 2)) (set-pin-mode p :input))
(set-pin-mode 100 :output)
;; X0 AND NOT X1, driving the coil
(simulate-input-change 0 1)
(simulate-input-change 1 0)
(input 0)
(and-not-bit 1)
(output 100)
(check "X0=1, X1=0 energises the coil" (read-pin-value 100) 1)
(simulate-input-change 1 1)
(input 0)
(and-not-bit 1)
(output 100)
(check "X0=1, X1=1 de-energises the coil" (read-pin-value 100) 0)

(section "coil forms read the accumulator without disturbing it")
(plc-init)
(set-pin-mode 100 :output)
(setf *scan-value* 1)
(check "output returns the accumulator" (output 100) 1)
(check "accumulator survives output" *scan-value* 1)
;; The property that matters is that a multi-bit accumulator reaches OUTPUT-PWM
;; intact, so OUTPUT must not normalise it on the way past. Checking this with
;; an accumulator of 1 proves nothing, since normalising 1 gives back 1.
(set-pin-mode 101 :output)
(setf *scan-value* 512)
(check "output returns a multi-bit accumulator" (output 100) 512)
(check "multi-bit accumulator survives output" *scan-value* 512)
(setf *scan-value* 700)
(output-not 100)
(check "multi-bit accumulator survives output-not" *scan-value* 700)
(setf *scan-value* 1023)
(output 100)
(output-pwm 101)
(check "a coil then PWM off the same analog reading" (read-pin-value 101) 255)
(setf *scan-value* 0)
(output-not 100)
(check "output-not inverts" (read-pin-value 100) 1)
(setf *scan-value* 1023)
(output-pwm 100)
(check "output-pwm scales 1023 to 255" (read-pin-value 100) 255)
(check "accumulator survives output-pwm" *scan-value* 1023)

(section "output uses upstream's = 1 guard on the accumulator")
;; Upstream tests scanValue against 1 rather than for non-zero, so an analog
;; reading that has not been reduced by COMPARE-* reads as off.
(plc-init)
(set-pin-mode 100 :output)
(setf *scan-value* 512)
(output 100)
(check "512 reads as off, per upstream" (read-pin-value 100) 0)
(setf *scan-value* 512)
(output-not 100)
(check "output-not with 512 energises" (read-pin-value 100) 1)

(section "-value forms still take an explicit value")
(plc-init)
(set-pin-mode 100 :output)
(check "output-value writes and loads" (output-value 100 1) 1)
(check "output-value drove the pin" (read-pin-value 100) 1)
(check "output-not-value inverts"
       (progn (output-not-value 100 1) (read-pin-value 100)) 0)
(check "output-pwm-value writes the raw value"
       (progn (output-pwm-value 100 200) (read-pin-value 100)) 200)

(section "load-value loads the accumulator directly")
(check "load-value returns what it stored" (load-value 7) 7)
(check "accumulator holds it" *scan-value* 7)


;;; ------------------------------------------------------------------
;;; Expression-style logic functions
;;;
;;; These take contact readings, which are the integers 0 and 1. Every
;;; non-NIL value is true in Common Lisp, so 0 used to count as energised.
;;; ------------------------------------------------------------------

(section "plc-truthy treats 0 as de-energised")
(check "0 is false" (plc-truthy 0) nil)
(check "1 is true" (plc-truthy 1) t)
(check "nil is false" (plc-truthy nil) nil)
(check "t is true" (plc-truthy t) t)
(check "512 is true" (plc-truthy 512) t)

(section "logic functions on contact readings")
(check "(plc-and 1 0) is false" (plc-and 1 0) nil)
(check "(plc-and 1 1) is true" (and (plc-and 1 1) t) t)
(check "(plc-and 0 0) is false" (plc-and 0 0) nil)
(check "(plc-or 0 0) is false" (plc-or 0 0) nil)
(check "(plc-or 0 1) is true" (and (plc-or 0 1) t) t)
(check "(plc-not 0) is true" (plc-not 0) t)
(check "(plc-not 1) is false" (plc-not 1) nil)
(check "(plc-xor 1 0) is true" (plc-xor 1 0) t)
(check "(plc-xor 1 1) is false" (plc-xor 1 1) nil)
(check "(plc-xor 0 0) is false" (plc-xor 0 0) nil)
(check "(plc-nand 1 0) is true" (plc-nand 1 0) t)
(check "(plc-nor 0 0) is true" (plc-nor 0 0) t)

(section "booleans still work, so existing callers are unaffected")
(check "(plc-and t t) is true" (and (plc-and t t) t) t)
(check "(plc-and t nil) is false" (plc-and t nil) nil)
(check "(plc-or nil nil) is false" (plc-or nil nil) nil)
(check "mixed t and 1" (and (plc-and t 1) t) t)
(check "mixed nil and 0" (plc-and nil 0) nil)

(section "start-stop-circuit, which the truthiness bug broke")
;; With nothing pressed and no memory bit the output must stay off. Before the
;; fix (plc-or 0 0) returned 0, which counted as true, and the motor ran.
(plc-init)
(dolist (p '(10 11)) (set-pin-mode p :input))
(set-pin-mode 12 :output)
(simulate-input-change 10 0)   ; start not pressed
(simulate-input-change 11 0)   ; stop not pressed, so the NC contact conducts
(start-stop-circuit 10 11 12 nil)
(check "idle circuit leaves the motor off" (read-pin-value 12) 0)

(simulate-input-change 10 1)   ; press start
(start-stop-circuit 10 11 12 nil)
(check "pressing start runs the motor" (read-pin-value 12) 1)

(simulate-input-change 10 0)   ; release start, memory bit holds
(start-stop-circuit 10 11 12 t)
(check "memory bit seals the circuit in" (read-pin-value 12) 1)

(simulate-input-change 11 1)   ; press stop
(start-stop-circuit 10 11 12 t)
(check "pressing stop drops the motor" (read-pin-value 12) 0)


;;; ------------------------------------------------------------------
;;; Timers
;;;
;;; The timer functions take contact readings, which are the integers 0 and 1.
;;; TIMER-OFF stored its input straight into TIMER-STATE-OUTPUT, a slot typed
;;; BOOLEAN, so (timer-off (input pin) ...) raised a type error. All four also
;;; treated a reading of 0 as energised.
;;; ------------------------------------------------------------------

(section "timers accept contact readings, not just booleans")
(guarded "timers with integer inputs"
  (plc-init)
  (check "timer-on with the integer 1" (progn (timer-on 1 'ta 1000) t) t)
  (check "timer-off with the integer 1" (progn (timer-off 1 'tb 1000) t) t)
  (check "timer-pulse with the integer 1" (progn (timer-pulse 1 'tc 1000) t) t)
  (check "timer-cycle with the integer 1" (progn (timer-cycle 1 'td 500 500) t) t))

(section "timers return booleans, whatever they are given")
(guarded "timer return types"
 (plc-init)
 (dolist (name '(ta tb tc td))
  (dolist (in '(0 1 nil t))
    (let ((r (timer-on in name 1000)))
      (check (format nil "timer-on ~s returns a boolean" in)
             (and (member r '(t nil)) t) t)))))

(section "a reading of 0 is de-energised, not energised")
(guarded "zero is de-energised"
 (plc-init)
;; timer-off starts its delay when the input is false. Given 0, which is
;; de-energised, it must start rather than follow the input as if it were true.
(check "timer-off with 0 does not error" (progn (timer-off 0 'te 10000) t) t)
(check "timer-off with 0 behaves as with NIL"
       (progn (plc-init) (timer-off 0 'tf 10000))
       (progn (plc-init) (timer-off nil 'tg 10000)))
(check "timer-on with 0 behaves as with NIL"
       (progn (plc-init) (timer-on 0 'th 10000))
       (progn (plc-init) (timer-on nil 'ti 10000)))
;; A single call does not separate these: an unnormalised 0 takes the "start
;; the timer" branch, which also returns NIL. The difference only shows on the
;; next scan, once the started timer has had a zero-length delay to expire.
(check "timer-on with 0 never starts the delay"
       (progn (plc-init) (timer-on 0 'tp 0) (timer-on 0 'tp 0)) nil)
(check "timer-on with NIL agrees"
       (progn (plc-init) (timer-on nil 'tq 0) (timer-on nil 'tq 0)) nil)
;; timer-pulse and timer-cycle do separate on one call, since both energise
;; their output the moment they are triggered.
(check "timer-pulse with 0 does not fire" (progn (plc-init) (timer-pulse 0 'tr 10000)) nil)
(check "timer-pulse with NIL agrees" (progn (plc-init) (timer-pulse nil 'ts 10000)) nil)
(check "timer-cycle with 0 does not run" (progn (plc-init) (timer-cycle 0 'tt 500 500)) nil)
(check "timer-cycle with 0 behaves as with NIL"
       (progn (plc-init) (timer-cycle 0 'tj 500 500))
       (progn (plc-init) (timer-cycle nil 'tk 500 500))))

(section "a timer driven straight from a pin, as the README shows")
(guarded "timer from a pin"
 (plc-init)
 (set-pin-mode 2 :input)
(simulate-input-change 2 1)
(check "timer-on from (input 2)" (progn (timer-on (input 2) 'tl 1000) t) t)
(check "timer-off from (input 2)" (progn (timer-off (input 2) 'tm 1000) t) t)
(simulate-input-change 2 0)
(check "timer-on from a low pin" (progn (timer-on (input 2) 'tn 1000) t) t)
(check "timer-off from a low pin" (progn (timer-off (input 2) 'to 1000) t) t))


;;; ------------------------------------------------------------------
;;; Compatibility with plclib-cl-web
;;;
;;; The web system calls exactly these seven symbols. Their signatures and
;;; behaviour must not drift, or plclib-cl-web breaks.
;;; ------------------------------------------------------------------

(section "the plclib-cl-web coupling surface")
(check "plc-init is callable" (progn (plc-init) t) t)
(check "serial-begin is callable" (progn (serial-begin) t) t)
(check "set-pin-mode takes pin and mode"
       (progn (set-pin-mode 5 :input) (pin-state-mode (get-pin-state 5))) :input)
(check "simulate-input-change takes pin and value"
       (progn (simulate-input-change 5 1) (read-pin-value 5)) 1)
;; plclib-cl-web calls OUTPUT-VALUE, renamed from OUTPUT when OUTPUT took on
;; upstream's single-argument form. Its behaviour is unchanged.
(check "output-value takes pin and value"
       (progn (set-pin-mode 105 :output) (output-value 105 1) (read-pin-value 105)) 1)
(check "output-value with NIL clears the pin"
       (progn (output-value 105 nil) (read-pin-value 105)) 0)
;; The integer 0 is the case that matters: it is true in Common Lisp, so a
;; plain (if value 1 0) energises the coil. plclib-cl-web reaches here through
;; set-output, which passes 0 rather than NIL.
(check "output-value with the integer 0 clears the pin"
       (progn (output-value 105 1) (output-value 105 0) (read-pin-value 105)) 0)
(check "output-not-value with the integer 0 energises the pin"
       (progn (output-not-value 105 0) (read-pin-value 105)) 1)
(check "output-value loads the accumulator"
       (progn (output-value 105 1) *scan-value*) 1)
(check "output-value with 0 loads the accumulator with 0"
       (progn (output-value 105 0) *scan-value*) 0)
(check "plc-reset is callable" (progn (plc-reset) t) t)
(check "plc-scan is callable" (progn (plc-scan) t) t)

(section "the accumulator starts as an integer, not nil")
;; LOGAND and friends would error on NIL, so plc-init must leave a number here.
(plc-init)
(check "plc-init leaves 0" *scan-value* 0)
(check "and-bit-value works straight after init" (and-bit-value 1) 0)
(plc-reset)
(check "plc-reset leaves 0" *scan-value* 0)

(report)
(sb-ext:exit :code (if (zerop *failures*) 0 1))

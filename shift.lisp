;;;; shift.lisp

(in-package #:plclib-cl)

(defclass shift-register ()
  ((bits
    :initarg :bits
    :initform 0
    :accessor shift-bits
    :type integer
    :documentation "Bit register for shift operations")
   (size
    :initarg :size
    :initform 16
    :accessor shift-size
    :type (integer 1 64)
    :documentation "Size of shift register in bits")
   (shift-input-prev
    :initform nil
    :accessor shift-input-prev
    :type boolean
    :documentation "Previous state of shift input")
   (reset-input-prev
    :initform nil
    :accessor shift-reset-input-prev
    :type boolean
    :documentation "Previous state of reset input"))
  (:documentation "PLC-style shift register class"))

(defmethod initialize-instance :after ((shifter shift-register) &key)
  "Initialize shift register after creation"
  (setf (shift-input-prev shifter) nil)
  (setf (shift-reset-input-prev shifter) nil))

(defun make-shift-register (&optional (size 16))
  "Create a new shift register with specified size"
  (make-instance 'shift-register :size size :bits 0))

(defmethod shift-left ((shifter shift-register) shift-input data-input)
  "Shift left on rising edge of shift input, loading data input into LSB"
  (let ((shift-edge (and shift-input (not (shift-input-prev shifter))))
        (mask (1- (ash 1 (shift-size shifter)))))
    (setf (shift-input-prev shifter) shift-input)
    (when shift-edge
      (setf (shift-bits shifter) 
            (logand mask 
                    (logior (ash (shift-bits shifter) 1)
                            (if data-input 1 0)))))
    (shift-bits shifter)))

(defmethod shift-right ((shifter shift-register) shift-input data-input)
  "Shift right on rising edge of shift input, loading data input into MSB"
  (let ((shift-edge (and shift-input (not (shift-input-prev shifter))))
        (mask (1- (ash 1 (shift-size shifter))))
        (msb-pos (1- (shift-size shifter))))
    (setf (shift-input-prev shifter) shift-input)
    (when shift-edge
      (setf (shift-bits shifter) 
            (logand mask 
                    (logior (ash (shift-bits shifter) -1)
                            (if data-input (ash 1 msb-pos) 0)))))
    (shift-bits shifter)))

(defmethod shift-reset ((shifter shift-register) reset-input)
  "Reset shift register when reset input is active"
  (let ((reset-edge (and reset-input (not (shift-reset-input-prev shifter)))))
    (setf (shift-reset-input-prev shifter) reset-input)
    (when reset-edge
      (setf (shift-bits shifter) 0))
    (shift-bits shifter)))

(defmethod shift-load ((shifter shift-register) load-input load-value)
  "Load value into shift register"
  (when load-input
    (let ((mask (1- (ash 1 (shift-size shifter)))))
      (setf (shift-bits shifter) (logand mask load-value))))
  (shift-bits shifter))

(defmethod shift-get-bit ((shifter shift-register) bit-position)
  "Get value of specific bit in shift register"
  (if (and (>= bit-position 0) (< bit-position (shift-size shifter)))
      (if (logbitp bit-position (shift-bits shifter)) 1 0)
      0))

(defmethod shift-rotate-left ((shifter shift-register) rotate-input)
  "Rotate left on rising edge of rotate input"
  (let ((rotate-edge (and rotate-input (not (shift-input-prev shifter))))
        (mask (1- (ash 1 (shift-size shifter))))
        (msb-pos (1- (shift-size shifter))))
    (setf (shift-input-prev shifter) rotate-input)
    (when rotate-edge
      (let ((msb (if (logbitp msb-pos (shift-bits shifter)) 1 0)))
        (setf (shift-bits shifter) 
              (logand mask 
                      (logior (ash (shift-bits shifter) 1) msb)))))
    (shift-bits shifter)))

(defmethod shift-rotate-right ((shifter shift-register) rotate-input)
  "Rotate right on rising edge of rotate input"
  (let ((rotate-edge (and rotate-input (not (shift-input-prev shifter))))
        (mask (1- (ash 1 (shift-size shifter))))
        (msb-pos (1- (shift-size shifter))))
    (setf (shift-input-prev shifter) rotate-input)
    (when rotate-edge
      (let ((lsb (if (logbitp 0 (shift-bits shifter)) 1 0)))
        (setf (shift-bits shifter) 
              (logand mask 
                      (logior (ash (shift-bits shifter) -1) 
                              (ash lsb msb-pos))))))
    (shift-bits shifter)))
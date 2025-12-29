;;;; stack.lisp

(in-package #:plclib-cl)

(defclass stack ()
  ((values
    :initform nil
    :accessor stack-values
    :type list
    :documentation "Stack values stored as a list")
   (max-size
    :initarg :max-size
    :initform 16
    :accessor stack-max-size
    :type (integer 1 *)
    :documentation "Maximum stack size"))
  (:documentation "PLC-style stack for boolean operations"))

(defun make-stack (&optional (max-size 16))
  "Create a new stack with specified maximum size"
  (make-instance 'stack :max-size max-size))

(defmethod stack-push ((stack stack) value)
  "Push a boolean value onto the stack"
  (let ((bool-value (if value t nil)))
    (push bool-value (stack-values stack))
    ;; Limit stack size
    (when (> (length (stack-values stack)) (stack-max-size stack))
      (setf (stack-values stack) 
            (subseq (stack-values stack) 0 (stack-max-size stack))))
    bool-value))

(defmethod stack-pop ((stack stack))
  "Pop a value from the stack"
  (if (stack-values stack)
      (pop (stack-values stack))
      nil))

(defmethod stack-empty-p ((stack stack))
  "Check if stack is empty"
  (null (stack-values stack)))

(defmethod stack-top ((stack stack))
  "Get top value without popping"
  (first (stack-values stack)))

(defmethod stack-size ((stack stack))
  "Get current stack size"
  (length (stack-values stack)))

(defmethod stack-clear ((stack stack))
  "Clear all values from stack"
  (setf (stack-values stack) nil))

(defmethod stack-load ((stack stack) value)
  "Load value onto stack (same as push)"
  (stack-push stack value))

(defmethod stack-and ((stack stack))
  "Pop two values, push AND result"
  (if (>= (stack-size stack) 2)
      (let ((val2 (stack-pop stack))
            (val1 (stack-pop stack)))
        (stack-push stack (and val1 val2)))
      (when (>= (stack-size stack) 1)
        (stack-push stack (stack-pop stack)))))

(defmethod stack-or ((stack stack))
  "Pop two values, push OR result"
  (if (>= (stack-size stack) 2)
      (let ((val2 (stack-pop stack))
            (val1 (stack-pop stack)))
        (stack-push stack (or val1 val2)))
      (when (>= (stack-size stack) 1)
        (stack-push stack (stack-pop stack)))))

(defmethod stack-xor ((stack stack))
  "Pop two values, push XOR result"
  (if (>= (stack-size stack) 2)
      (let ((val2 (stack-pop stack))
            (val1 (stack-pop stack)))
        (stack-push stack (and (or val1 val2) 
                               (not (and val1 val2)))))
      (when (>= (stack-size stack) 1)
        (stack-push stack (stack-pop stack)))))

(defmethod stack-not ((stack stack))
  "Pop one value, push NOT result"
  (when (>= (stack-size stack) 1)
    (let ((val (stack-pop stack)))
      (stack-push stack (not val)))))

(defmethod stack-duplicate ((stack stack))
  "Duplicate top value on stack"
  (when (>= (stack-size stack) 1)
    (let ((val (stack-top stack)))
      (stack-push stack val))))

(defmethod stack-swap ((stack stack))
  "Swap top two values on stack"
  (when (>= (stack-size stack) 2)
    (let ((val1 (stack-pop stack))
          (val2 (stack-pop stack)))
      (stack-push stack val1)
      (stack-push stack val2))))
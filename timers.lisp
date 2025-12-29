;;;; timers.lisp

(in-package #:plclib-cl)

(defstruct timer-state
  "Structure to track timer state"
  (start-time 0 :type (unsigned-byte 64))
  (duration 0 :type (unsigned-byte 64))
  (active nil :type boolean)
  (output nil :type boolean))

(defparameter *timers* (make-hash-table)
  "Hash table to store timer states")

(defun get-timer (timer-id)
  "Get or create timer state"
  (or (gethash timer-id *timers*)
      (setf (gethash timer-id *timers*)
            (make-timer-state))))

(defun timer-on (input timer-id duration-ms)
  "Timer ON: Output turns on after delay when input is true"
  (let ((timer (get-timer timer-id))
        (current-time (get-current-time-ms)))
    (cond
      ((and input (not (timer-state-active timer)))
       ;; Start timer
       (setf (timer-state-start-time timer) current-time)
       (setf (timer-state-duration timer) duration-ms)
       (setf (timer-state-active timer) t)
       (setf (timer-state-output timer) nil))
      ((and input (timer-state-active timer))
       ;; Timer running - check if done
       (when (>= (- current-time (timer-state-start-time timer)) 
                 (timer-state-duration timer))
         (setf (timer-state-output timer) t)))
      (t
       ;; Input false - reset timer
       (setf (timer-state-active timer) nil)
       (setf (timer-state-output timer) nil)))
    (timer-state-output timer)))

(defun timer-off (input timer-id duration-ms)
  "Timer OFF: Output turns off after delay when input becomes false"
  (let ((timer (get-timer timer-id))
        (current-time (get-current-time-ms)))
    (cond
      ((and (not input) (not (timer-state-active timer)))
       ;; Start timer
       (setf (timer-state-start-time timer) current-time)
       (setf (timer-state-duration timer) duration-ms)
       (setf (timer-state-active timer) t)
       (setf (timer-state-output timer) t))
      ((and (not input) (timer-state-active timer))
       ;; Timer running - check if done
       (when (>= (- current-time (timer-state-start-time timer)) 
                 (timer-state-duration timer))
         (setf (timer-state-output timer) nil)))
      (t
       ;; Input true - output follows input
       (setf (timer-state-active timer) nil)
       (setf (timer-state-output timer) input)))
    (timer-state-output timer)))

(defun timer-pulse (input timer-id duration-ms)
  "Timer PULSE: Output pulses for duration when input triggers"
  (let ((timer (get-timer timer-id))
        (current-time (get-current-time-ms)))
    (when (and input (not (timer-state-active timer)))
      ;; Start pulse
      (setf (timer-state-start-time timer) current-time)
      (setf (timer-state-duration timer) duration-ms)
      (setf (timer-state-active timer) t)
      (setf (timer-state-output timer) t))
    
    (when (timer-state-active timer)
      ;; Check if pulse is done
      (when (>= (- current-time (timer-state-start-time timer)) 
                (timer-state-duration timer))
        (setf (timer-state-active timer) nil)
        (setf (timer-state-output timer) nil)))
    
    (timer-state-output timer)))

(defun timer-cycle (enable timer-id on-duration-ms off-duration-ms)
  "Timer CYCLE: Cycles between on and off durations while enabled"
  (let ((timer (get-timer timer-id))
        (current-time (get-current-time-ms)))
    (if enable
        (progn
          (unless (timer-state-active timer)
            ;; Start cycle in ON state
            (setf (timer-state-start-time timer) current-time)
            (setf (timer-state-duration timer) on-duration-ms)
            (setf (timer-state-active timer) t)
            (setf (timer-state-output timer) t))
          
          ;; Check for state transitions
          (when (>= (- current-time (timer-state-start-time timer)) 
                    (timer-state-duration timer))
            (if (timer-state-output timer)
                ;; Switch to OFF state
                (progn
                  (setf (timer-state-start-time timer) current-time)
                  (setf (timer-state-duration timer) off-duration-ms)
                  (setf (timer-state-output timer) nil))
                ;; Switch to ON state
                (progn
                  (setf (timer-state-start-time timer) current-time)
                  (setf (timer-state-duration timer) on-duration-ms)
                  (setf (timer-state-output timer) t)))))
        ;; Disabled - reset timer
        (progn
          (setf (timer-state-active timer) nil)
          (setf (timer-state-output timer) nil)))
    
    (timer-state-output timer)))
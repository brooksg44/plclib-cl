;;;; plclib-cl.asd

(asdf:defsystem #:plclib-cl
  :description "A Common Lisp implementation of PLC programming functionality"
  :author "Reverse engineered from plcLib by wditch"
  :license "MIT"
  :version "0.1.0"
  :serial t
  :depends-on ()
  :components ((:file "package")
               (:file "types")
               (:file "pin-manager")
               (:file "timers")
               (:file "counters")
               (:file "shift")
               (:file "stack")
               (:file "pulse")
               (:file "logic")
               (:file "io")
               (:file "bitops")
               (:file "plclib")
               (:file "examples")))
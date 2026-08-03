# PLCLIB-CL

A Common Lisp implementation of PLC (Programmable Logic Controller) functionality, reverse engineered from the Arduino plcLib by wditch.

## Overview

This library provides PLC-style programming capabilities for Common Lisp applications, including:

- Digital and analog I/O simulation
- Timer functions (ON, OFF, PULSE, CYCLE)
- Counter operations (UP, DOWN, PRESET)
- Shift register operations
- Stack-based logic operations
- Edge detection and pulse monitoring
- Boolean logic operations
- Ladder logic programming constructs

## Installation

1. Clone this repository to your Common Lisp systems directory
2. Load the system using ASDF:

```lisp
(asdf:load-system :plclib-cl)
```

## Dependencies

This library has no external dependencies and uses only built-in Common Lisp functionality.

## Quick Start

```lisp
(use-package :plclib-cl)

;; Initialize the PLC system
(plc-init)
(serial-begin)

;; Basic I/O operations
(set-pin-mode 2 :input)
(set-pin-mode 13 :output)

;; Simulate input and control output. Operations chain through the scan
;; accumulator: INPUT loads it, OUTPUT drives a pin from it.
(simulate-input-change 2 1)
(input 2)
(output 13)

;; Or compute a value yourself and write it with the explicit-value form
(output-value 13 (input 2))

;; Use timers
(let ((timer-result (timer-on (input 2) 'my-timer 1000)))
  (output-value 13 timer-result))

;; Use counters
(let ((counter (make-counter 10)))
  (counter-up counter (input 2))
  (output-value 13 (counter-done-p counter)))
```

## The Scan Accumulator

A rung is built by chaining operations through `*scan-value*`, a global accumulator, exactly as the Arduino original does with its `scanValue`:

```lisp
(input 0)          ; load the accumulator from pin 0
(and-not-bit 1)    ; AND it with NOT pin 1
(or-bit 2)         ; OR it with pin 2
(output 100)       ; drive the coil from it
```

`input`, `input-not` and `input-analog` load the accumulator (and also return the value). `output`, `output-not` and `output-pwm` read it and drive a pin, leaving it untouched so one rung can drive several coils.

### Bit operations

| Operation | Upstream | Effect on the accumulator |
| --- | --- | --- |
| `and-bit` | `andBit` | `(logand acc operand)` |
| `and-not-bit` | `andNotBit` | `(logandc2 acc operand)` |
| `or-bit` | `orBit` | `(logior acc operand)` |
| `or-not-bit` | `orNotBit` | see note below |
| `xor-bit` | `xorBit` | `(logxor acc operand)` |

These are **bitwise**, matching the C original, not boolean. The two agree whenever the accumulator holds 0 or 1, which is every well-formed rung; they diverge only for a raw `input-analog` reading that has not been reduced by `compare-gt` or `compare-lt`.

Note that `and-not-bit` uses bitwise complement, matching upstream's `scanValue & ~input` rather than a logical negation, so `512 and-not-bit 1` is 512, not 0.

### Pins versus values

Each bit operation comes in two forms:

```lisp
(and-bit 1)          ; reads pin 1, then combines
(and-bit-value 1)    ; combines with the value 1 directly
```

The Arduino original distinguishes these with C++ overloads — `in(int)` reads a pin, `in(unsigned int)` takes a value, and the compiler chooses. Common Lisp cannot, since a pin number and a value are both just integers, so they get separate names. `load-value` is the accumulator-loading counterpart to `input`.

### Two styles

The accumulator operations above are one way to write a rung. The `plc-and` family is the other, taking values as arguments and returning a result. Both are supported; they do not interact.

```lisp
;; accumulator style
(input 0) (and-not-bit 1) (output 100)

;; expression style
(output-value 100 (plc-and (input 0) (plc-not (input 1))))
```

## Core Components

### Pin Management
- `input`, `input-not`, `input-analog` - Read a pin, loading the accumulator
- `load-value` - Load the accumulator directly
- `output`, `output-not`, `output-pwm` - Drive a pin from the accumulator
- `output-value`, `output-not-value`, `output-pwm-value` - Drive a pin from an explicit value
- `set-pin-mode` - Configure pin modes
- `simulate-input-change` - Simulate hardware input changes

### Timers
- `timer-on` - Turn on after delay
- `timer-off` - Turn off after delay  
- `timer-pulse` - Generate pulse of specified duration
- `timer-cycle` - Cycle between on/off states

### Counters
- `make-counter` - Create counter with preset
- `counter-up`, `counter-down` - Count operations
- `counter-reset` - Reset counter
- `counter-done-p` - Check if preset reached

### Shift Registers
- `make-shift-register` - Create shift register
- `shift-left`, `shift-right` - Shift operations
- `shift-load` - Load value into register
- `shift-reset` - Reset register

### Logic Operations
- `and-bit`, `and-not-bit`, `or-bit`, `or-not-bit`, `xor-bit` - Accumulator operations, plus their `-value` forms
- `plc-and`, `plc-or`, `plc-xor`, `plc-not` - Boolean operations on arguments
- `plc-truthy` - Whether a value counts as energised
- `compare-eq`, `compare-gt`, `compare-lt` - Comparison functions
- `get-bit`, `set-bit`, `clear-bit` - Bit manipulation

Contacts read as the integers 0 and 1, but every non-`NIL` value is true in Common Lisp, so `0` would otherwise count as energised. The `plc-` functions and the explicit-value outputs run their arguments through `plc-truthy`, which treats `0` and `NIL` as de-energised and anything else as energised. Booleans work unchanged, so `T` and `NIL` callers are unaffected:

```lisp
(plc-and 1 0)   ; => NIL
(plc-not 0)     ; => T
(plc-truthy 0)  ; => NIL
```

### Edge Detection
- `make-pulse-detector` - Create edge detector
- `rising-edge`, `falling-edge` - Detect signal edges

### Stack Operations
- `make-stack` - Create logic stack
- `stack-push`, `stack-pop` - Stack manipulation
- `stack-and`, `stack-or` - Logic operations on stack

## Examples

The library includes comprehensive examples demonstrating:

1. Basic I/O operations
2. Timer usage
3. Counter operations
4. Shift register manipulation
5. Edge detection
6. Logic operations
7. Start/stop motor circuits
8. Analog signal processing
9. Stack operations
10. Complete PLC programs

Run all examples with:

```lisp
(run-all-examples)
```

## Tests

```
sbcl --script tests.lisp
```

92 checks covering the accumulator operations against `logand` / `logandc2` / `logior` / `logxor`, the digital truth tables, contact truthiness, `start-stop-circuit`, and the symbols `plclib-cl-web` depends on. Exits non-zero on failure.

The suite forces a rebuild rather than trusting the ASDF fasl cache, which decides by timestamp and can otherwise report on code no longer on disk.

## Ladder Logic Programming

The library supports ladder logic style programming:

```lisp
;; Define a rung with contacts and coils
(plc-rung (plc-and (contact-no 2) (contact-nc 3))
  (coil 13 t)
  (coil 14 nil))

;; Start/stop circuit with memory
(start-stop-circuit start-pin stop-pin output-pin memory-bit)
```

## PLC System Control

```lisp
;; Initialize and start PLC
(plc-init)
(plc-start)

;; Perform scan cycles
(plc-scan)

;; Get system status
(get-plc-status)
(print-plc-status)

;; Stop PLC
(plc-stop)
```

## Serial Communication

The library includes serial communication simulation:

```lisp
(serial-begin 9600)
(serial-println "Hello PLC World!")
(serial-print-value "Sensor" sensor-value)
```

## Hardware Simulation

Since this is a software implementation, all hardware I/O is simulated:

```lisp
;; Simulate digital input changes
(simulate-input-change pin-number value)

;; Simulate analog input changes  
(simulate-analog-input-change pin-number value)

;; Read simulated pin states
(get-pin-info pin-number)
(list-active-pins)
```

## License

MIT License - See original plcLib project for inspiration and reference.

## Contributing

This is a reverse-engineered implementation for educational and development purposes. Contributions welcome!

## Differences from Original

This Common Lisp implementation differs from the original Arduino C++ library in several ways:

1. **Platform Independent** - Runs on any Common Lisp implementation
2. **Hardware Simulation** - All I/O operations are simulated in software
3. **Enhanced Features** - Additional utilities and debugging capabilities
4. **Object-Oriented Design** - Uses CLOS for counters, shift registers, etc.
5. **Functional Programming** - Leverages Common Lisp's functional capabilities
6. **Interactive Development** - Supports REPL-based development and testing
7. **Overloads become names** - C++ picks between `in(int)` and `in(unsigned int)`, or between `out(pin)` and `out(&variable)`, by argument type. Common Lisp cannot tell a pin number from a value, so these become separate functions: `input` and `load-value`, `output` and `output-value`
8. **Arbitrary-precision integers** - `logandc2` gives `a & ~b` exactly, with no assumption about whether `unsigned int` is 16 or 32 bits on the target

Where the original is quirky, this port follows it rather than quietly correcting it. `or-not-bit`, `output` and `output-not` test the accumulator against 1 rather than for non-zero, unlike the other operations. That means an `input-analog` reading which has not been through `compare-gt` or `compare-lt` reads as off in those three and as on elsewhere. The C source behaves this way, and `tests.lisp` pins it so that "fixing" it fails the suite.

## API Reference

Every exported symbol, grouped by purpose. All functions carry documentation strings, reachable with `(documentation 'name 'function)`.

### System control

```lisp
(plc-init)                     ; clear pins, timers, counters and the accumulator
(plc-reset)                    ; same as plc-init
(plc-start)                    ; mark the system running
(plc-stop)                     ; mark it stopped
(plc-scan)                     ; run one scan cycle, updating the statistics
(plc-run-continuous 10)        ; set the cycle time and start
(get-plc-status)               ; => plist of :running :scan-count :scan-time ...
(print-plc-status)             ; print the same, to the serial stream
```

`plc-run-continuous` sets the cycle time and starts the system; it does not itself loop. Driving the scan is left to the caller, so wrap `plc-scan` in whatever loop or thread suits the application.

### Pins and I/O

```lisp
(set-pin-mode 2 :input)        ; :input, :output or :input-pullup
(read-pin-value 2)             ; => 0 or 1, without touching the accumulator

(input 2)                      ; read a pin, loading the accumulator
(input-not 2)                  ; read inverted
(input-analog 3)               ; read 0-1023
(load-value 1)                 ; load the accumulator directly

(output 13)                    ; drive a pin from the accumulator
(output-not 13)                ; drive it inverted
(output-pwm 13)                ; drive as PWM, scaling 0-1023 to 0-255

(output-value 13 1)            ; drive a pin from an explicit value
(output-not-value 13 1)
(output-pwm-value 13 200)
```

### Hardware simulation and diagnostics

```lisp
(simulate-input-change 2 1)          ; set what a digital pin will read
(simulate-analog-input-change 3 500) ; the analog equivalent
(get-pin-info 2)                     ; => plist of :pin :mode :current-value ...
(list-active-pins)                   ; => sorted list of every pin touched
(reset-all-pins)                     ; forget all pin state
```

### Scan accumulator

```lisp
*scan-value*                   ; the accumulator itself
(get-scan-value)               ; read it
(set-scan-value 1)             ; write it

(and-bit 1)                    ; combine with a pin reading
(and-not-bit 1)
(or-bit 1)
(or-not-bit 1)
(xor-bit 1)

(and-bit-value 1)              ; combine with a value
(and-not-bit-value 1)
(or-bit-value 1)
(or-not-bit-value 1)
(xor-bit-value 1)
```

See [The Scan Accumulator](#the-scan-accumulator) for what these do and how the two forms differ.

### Logic and comparison

```lisp
(plc-truthy 0)                 ; => NIL. 0 and NIL are de-energised
(plc-and 1 1)                  ; variadic, => generalised boolean
(plc-or 0 1)
(plc-xor 1 0)
(plc-not 0)

(compare-eq 5 5)  (compare-ne 5 6)
(compare-gt 6 5)  (compare-ge 5 5)
(compare-lt 5 6)  (compare-le 5 5)
```

### Timers

Each takes an enable input, an identifier that keys its state, and a duration in milliseconds.

```lisp
(timer-on input 'my-timer 1000)              ; on after the input holds for 1s
(timer-off input 'my-timer 1000)             ; off 1s after the input drops
(timer-pulse input 'my-timer 1000)           ; a single 1s pulse
(timer-cycle enable 'my-timer 500 500)       ; 500ms on, 500ms off
```

### Counters

```lisp
(let ((c (make-counter 10)))       ; preset defaults to 0
  (counter-up c input)             ; count on a rising edge of INPUT
  (counter-down c input)
  (counter-reset c reset-input)    ; reset on a rising edge of RESET-INPUT
  (counter-value c)                ; current count
  (counter-preset c)               ; the preset
  (counter-done-p c))              ; has the count reached the preset
```

### Shift registers

```lisp
(let ((s (make-shift-register 16)))          ; size defaults to 16
  (shift-left s clock data)                  ; shift on a rising edge of CLOCK
  (shift-right s clock data)
  (shift-load s load-input value)
  (shift-reset s reset-input)
  (shift-bits s))                            ; the register contents
```

### Stack

```lisp
(let ((s (make-stack 16)))         ; max depth defaults to 16
  (stack-push s t)
  (stack-load s t)                 ; a synonym for stack-push
  (stack-and s)                    ; pop two, push their AND
  (stack-or s)
  (stack-pop s)
  (stack-empty-p s))
```

### Edge detection

```lisp
(let ((d (make-pulse-detector)))
  (rising-edge d input)            ; => T on the scan the input goes high
  (falling-edge d input))          ; => T on the scan it goes low
```

### Ladder logic helpers

```lisp
(contact-no 2)                     ; normally open, expands to (input 2)
(contact-nc 3)                     ; normally closed, expands to (input-not 3)
(coil 13 value)                    ; expands to (output-value 13 value)

(plc-rung (plc-and (contact-no 2) (contact-nc 3))
  (coil 13 t))

(start-stop-circuit 8 9 10 memory-bit)   ; start pin, stop pin, output, memory
```

### Serial simulation

```lisp
(serial-begin 9600)                ; announces itself once
(serial-print "text")
(serial-println "text with a newline")
(serial-print-value "Sensor" 512)  ; prints "Sensor: 512"
```

### A complete session

```lisp
(ql:quickload :plclib-cl)
(in-package :plclib-cl)

(plc-init)
(serial-begin)
(set-pin-mode 0 :input)
(set-pin-mode 1 :input)
(set-pin-mode 100 :output)

(simulate-input-change 0 1)
(simulate-input-change 1 0)

(input 0)                ; load X0
(and-not-bit 1)          ; AND with NOT X1
(output 100)             ; drive the coil

(read-pin-value 100)     ; => 1
```
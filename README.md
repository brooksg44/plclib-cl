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

See the exported symbols in `package.lisp` for a complete API reference. All functions include documentation strings accessible via `(documentation 'function-name 'function)`.
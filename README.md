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

;; Simulate input and control output
(simulate-input-change 2 1)
(output 13 (input 2))

;; Use timers
(let ((timer-result (timer-on (input 2) 'my-timer 1000)))
  (output 13 timer-result))

;; Use counters
(let ((counter (make-counter 10)))
  (counter-up counter (input 2))
  (output 13 (counter-done-p counter)))
```

## Core Components

### Pin Management
- `input`, `input-not`, `input-analog` - Read pin values
- `output`, `output-not`, `output-pwm` - Write pin values
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
- `plc-and`, `plc-or`, `plc-xor`, `plc-not` - Boolean operations
- `compare-eq`, `compare-gt`, `compare-lt` - Comparison functions
- `get-bit`, `set-bit`, `clear-bit` - Bit manipulation

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

## API Reference

See the exported symbols in `package.lisp` for a complete API reference. All functions include documentation strings accessible via `(documentation 'function-name 'function)`.
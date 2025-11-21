MIPS-Based MCU Architecture

This project implements a MIPS-based microcontroller (MCU) with Memory-Mapped I/O and interrupt support. It includes a single-cycle CPU core and essential peripheral modules, demonstrating modular microcontroller design in VHDL.

CPU Core (MIPS)
MIPS.vhd: Single-cycle processor executing fetch, decode, execute, memory access, and write-back stages.
Supports arithmetic, logical operations, branching, and memory interactions.

Peripherals
Basic Timer (BasicTimer.vhd): Up/down counting, output compare, interrupts, and PWM support.
GPIO (GPIO.vhd): Handles input/output with buttons, switches, LEDs, and generates interrupts.
Input/Output Peripheral: Separates input and output functionality for efficient communication.
Interrupt Controller (InterruptController.vhd): Manages and prioritizes external interrupts, coordinating with CPU.
Optional Address Decoder (OptAddrDecoder.vhd): Maps addresses to correct peripherals, avoiding conflicts.
Seven-Segment Decoder (SevenSegDecoder.vhd): Displays hexadecimal values on 7-segment display for debugging.

Included Files
MCU.vhd – Top-level entity
MIPS.vhd, IFETCH.vhd, IDECODE.vhd, CONTROL.vhd, ALU_CONTROL.vhd, ALU.vhd, EXECUTE.vhd, DMEMORY.vhd – CPU core modules
BasicTimer.vhd, GPIO.vhd, InputPeripheral.vhd, OutputPeripheral.vhd, InterruptController.vhd, OptAddrDecoder.vhd, SevenSegDecoder.vhd – Peripheral modules

Purpose
This project demonstrates CPU-peripheral interactions, modular microcontroller design, and hands-on VHDL programming skills, making it ideal for learning and experimentation in digital system design.

# Juanchos-6502
The MOS Technology 6502 is an 8-bit microprocessor that was designed by a small team led by Chuck Peddle for MOS Technology. The design team had formerly worked at Motorola on the Motorola 6800 project; the 6502 is essentially a simplified, less expensive and faster version of that design.

The purpose of this emulator is to provide documentation of the MOS 6502 for emulator developers, detailing the microprocessor's functionality at a low-level. This project is created for educational purposes. This emulator provides the following:

- Cycle-based emulation of all official 6502 instructions.
- Cycle-based emulation of all illegal 6502 opcodes (expect for JAM).
- Emulation of all documented addressing modes.
- Emulation of arithmetic operations.
- Emulation of 16-bit additions.
- Emulation of 16-bit subtractions.
- Emulation of signed values.
- Emulation of flags with ADC and SBC.
- Emulation of decimal mode (BCD).
- Emulation of jump vectors and stack operations.
- Emulation of the break flag and the stack.
- Implementation of the 6502's pinout.
- Emulation of the power-up state and reset state.

This MOS 6502 emulator is not 100% cycle-accurate. My implementation of cycle counting is rather barebones and even though it does take additional cycles into account, it never goes farther than:

- CYCLES [insert 6502 instruction + addressing mode] = Number of cycles
- CYCLES [insert 6502 instruction + addressing mode] [imply if this is either a same/different page boundary cross or just cross the page boundary without any further specifications] = Number of cycles

Because of the simplistic nature of my approach, this emulator may not be able to handle all hardware edge cases. It may get the job done for most programs/games, but don't expect it to run everything flawlessly. Here is the documentation used to create this MOS 6502 emulator: https://www.masswerk.at/6502/6502_instruction_set.html

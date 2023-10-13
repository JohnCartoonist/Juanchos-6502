# Juanchos-6502
The MOS Technology 6502 is an 8-bit microprocessor that was designed by a small team led by Chuck Peddle for MOS Technology. The design team had formerly worked at Motorola on the Motorola 6800 project; the 6502 is essentially a simplified, less expensive and faster version of that design.

The mission of this emulator is to reproduce the 6502 microprocessor's instructions in 6502 assembly for the purposes of video game preservation. This emulator provides the following:

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
- Some implementation of the 6502's pinout.
- Emulation of the power-up state and reset state.

This 6502 microprocessor emulator is not 100% cycle-accurate. My implementation of cycle counting is rather barebones and even though it does take additional cycles into account, it never goes farther than:
CYCLES [insert 6502 instruction + addressing mode] = Number of cycles
CYCLES [insert 6502 instruction + addressing mode] [imply this is either a page boundary cross of branch] = Number of cycles
Because of the simplistic nature of my approach, this emulator may not be able to handle all hardware edge cases. It may get the job done for most programs/games, but don't expect it to run everything flawlessly.

Here is the documentation used to create this 6502 microprocessor emulator: https://www.masswerk.at/6502/6502_instruction_set.html

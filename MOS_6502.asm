; Cycle-based MOS 6502 microprocessor emulator written in 6502 assembly by Juan Andres Diaz Torres (also known as 'JohnCartoonist') - 2023
;
; The purpose of this emulator is to provide documentation of the MOS 6502 for emulator developers, detailing the microprocessor's functionality at a low-level.
; This project is created for educational purposes. This emulator provides the following:
;
; - Cycle-based emulation of all official 6502 instructions.
; - Cycle-based emulation of all illegal 6502 opcodes (expect for JAM).
; - Emulation of all documented addressing modes.
; - Emulation of arithmetic operations.
; - Emulation of 16-bit additions.
; - Emulation of 16-bit subtractions.
; - Emulation of signed values.
; - Emulation of flags with ADC and SBC.
; - Emulation of decimal mode (BCD).
; - Emulation of jump vectors and stack operations.
; - Emulation of the break flag and the stack.
; - Implementation of the 6502's pinout.
; - Emulation of the power-up state and reset state.
;
; For reference, here is the documentation I've utilized in order to write this emulator: https://www.masswerk.at/6502/6502_instruction_set.html

; Address Modes
OPC A         ; Operand is AC (implied single byte instruction)
OPC $LLHH	  ; Operand is address $HHLL
OPC $LLHH,X	  ; Operand is address; effective address is address incremented by X with carry
OPC $LLHH,Y	  ; Operand is address; effective address is address incremented by Y with carry
OPC #$BB	  ; Operand is byte BB
OPC	          ; Operand implied
OPC ($LLHH)	  ; Operand is address; effective address is contents of word at address: C.w($HHLL)
OPC ($LL,X)	  ; Operand is zeropage address; effective address is word in (LL + X, LL + X + 1), inc. without carry: C.w($00LL + X)
OPC ($LL),Y	  ; Operand is zeropage address; effective address is word in (LL, LL + 1) incremented by Y with carry: C.w($00LL) + Y
OPC $BB	      ; Branch target is PC + signed offset BB
OPC $LL	      ; Operand is zeropage address (hi-byte is zero, address = $00LL)
OPC $LL,X	  ; Operand is zeropage address; effective address is address incremented by X without carry
OPC $LL,Y	  ; Operand is zeropage address; effective address is address incremented by Y without carry

; Implied Addressing
CLC           ; Clear the carry flag
ROL A         ; Rotate contents of accumulator left by one position
ROL           ; Same as above, implicit notation (A implied)
TXA           ; Transfer contents of X-register to the accumulator
PHA           ; Push the contents of the accumulator to the stack
RTS           ; return from subroutine (by pulling PC from stack)

; Immediate Addressing
LDA #$07      ; Load the literal hexidecimal value "$7" into the accumulator
ADC #$A0      ; Add the literal hexidecimal value "$A0" to the accumulator
CPX #$32      ; Compare the X-register to the literal hexidecimal value "$32"

; Absolute Addressing
LDA $3010     ; Load the contents of address "$3010" into the accumulator
ROL $08A0     ; Rotate the contents of address "$08A0" left by one position
JMP $4000     ; jump to (continue with) location "$4000"

; Zero-Page Addressing
LDA $80       ; Load the contents of address "$0080" into the accumulator
BIT $A2       ; Perform bit-test with the contents of address "$00A2"
ASL $9A       ; Arithmetic shift left of the contents of location "$009A"

; Indexed Addressing: Absolute,X and Absolute,Y
LDA $3120,X   ; Load the contents of address "$3120 + X" into A
LDX $8240,Y   ; Load the contents of address "$8240 + Y" into X
INC $1400,X   ; Increment the contents of address "$1400 + X"

; Indexed Addressing: Zero-Page,X (and Zero-Page,Y)
LDA $80,X     ; Load the contents of address "$0080 + X" into A
LSR $82,X     ; Shift the contents of address "$0082 + X" left
LDX $60,Y     ; Load the contents of address "$0060 + Y" into X

; Indirect Addressing
JMP ($FF82)   ; Jump to address given in addresses "$FF82" and "$FF83"

; Pre-Indexed Indirect, "(Zero-Page,X)"
LDA ($70,X)   ; Load the contents of the location given in addresses "$0070+X" and "$0070+1+X" into A
STA ($A2,X)   ; Store the contents of A in the location given in addresses "$00A2+X" and "$00A3+X"
EOR ($BA,X)   ; Perform an exlusive OR of the contents of A and the contents of the location given in addresses "$00BA+X" and "$00BB+X"

; Post-Indexed Indirect, "(Zero-Page),Y"
LDA ($70),Y   ; Add the contents of the Y-register to the pointer provided in "$0070" and "$0071" and load the contents of this address into A
STA ($A2),Y   ; Store the contents of A in the location given by the pointer in "$00A2" and "$00A3" plus the contents of the Y-register
EOR ($BA),Y   ; Perform an exlusive OR of the contents of A and the address given by the addition of Y to the pointer in "$00BA" and "$00BB"

; Relative Addressing (Conditional Branching)
BEQ $1005     ; Branch to location "$1005", if the zero flag is set. If the current address is $1000, this will give an offset of $03.
BCS $08C4     ; Branch to location "$08C4", if the carry flag is set. If the current address is $08D4, this will give an offset of $EE (−$12).
BCC $084A     ; Branch to location "$084A", if the carry flag is clear.

; Instructions
; ADC - Add Memory to Accumulator with Carry
ADC_IMMEDIATE = $69    ; Immediate Addressing
ADC_ZEROPAGE = $65     ; Zero-Page Addressing
ADC_ZEROPAGE_X = $75   ; Zero-Page Addressing (X)
ADC_ABSOLUTE = $6D     ; Absolute Addressing
ADC_ABSOLUTE_X = $7D   ; Absolute Addressing (X)
ADC_ABSOLUTE_Y = $79   ; Absolute Addressing (Y)
ADC_INDIRECT_X = $61   ; Indirect Addressing (X)
ADC_INDIRECT_Y = $71   ; Indirect Addressing (Y)

; Byte Counts
BYTES_ADC_IMMEDIATE = 2
BYTES_ADC_ZEROPAGE = 2
BYTES_ADC_ZEROPAGE_X = 2
BYTES_ADC_ABSOLUTE = 3
BYTES_ADC_ABSOLUTE_X = 3
BYTES_ADC_ABSOLUTE_Y = 3
BYTES_ADC_INDIRECT_X = 2
BYTES_ADC_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ADC_IMMEDIATE = 2
CYCLES_ADC_ZEROPAGE = 3
CYCLES_ADC_ZEROPAGE_X = 4
CYCLES_ADC_ABSOLUTE = 4
CYCLES_ADC_ABSOLUTE_X = 4
CYCLES_ADC_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_ADC_ABSOLUTE_Y = 4
CYCLES_ADC_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_ADC_INDIRECT_X = 6
CYCLES_ADC_INDIRECT_Y = 5
CYCLES_ADC_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6   ; Add 1 to cycles if page boundary is crossed

; AND - AND Memory with Accumulator
AND_IMMEDIATE = $29    ; Immediate Addressing
AND_ZEROPAGE = $25     ; Zero-Page Addressing
AND_ZEROPAGE_X = $35   ; Zero-Page Addressing (X)
AND_ABSOLUTE = $2D     ; Absolute Addressing
AND_ABSOLUTE_X = $3D   ; Absolute Addressing (X)
AND_ABSOLUTE_Y = $39   ; Absolute Addressing (Y)
AND_INDIRECT_X = $21   ; Indirect Addressing (X)
AND_INDIRECT_Y = $31   ; Indirect Addressing (Y)

; Byte Counts
BYTES_AND_IMMEDIATE = 2
BYTES_AND_ZEROPAGE = 2
BYTES_AND_ZEROPAGE_X = 2
BYTES_AND_ABSOLUTE = 3
BYTES_AND_ABSOLUTE_X = 3
BYTES_AND_ABSOLUTE_Y = 3
BYTES_AND_INDIRECT_X = 2
BYTES_AND_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_AND_IMMEDIATE = 2
CYCLES_AND_ZEROPAGE = 3
CYCLES_AND_ZEROPAGE_X = 4
CYCLES_AND_ABSOLUTE = 4
CYCLES_AND_ABSOLUTE_X = 4
CYCLES_AND_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_AND_ABSOLUTE_Y = 4
CYCLES_AND_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_AND_INDIRECT_X = 6
CYCLES_AND_INDIRECT_Y = 5
CYCLES_ADC_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6   ; Add 1 to cycles if page boundary is crossed

; ASL - Shift Left One Bit (Memory or Accumulator)
ASL_ACCUMULATOR = $0A  ; Accumulator
ASL_ZEROPAGE = $06     ; Zero-Page Addressing
ASL_ZEROPAGE_X = $16   ; Zero-Page Addressing (X)
ASL_ABSOLUTE = $0E     ; Absolute Addressing
ASL_ABSOLUTE_X = $1E   ; Absolute Addressing (X)

; Byte Counts
BYTES_ASL_ACCUMULATOR = 1
BYTES_ASL_ZEROPAGE = 2
BYTES_ASL_ZEROPAGE_X = 2
BYTES_ASL_ABSOLUTE = 3
BYTES_ASL_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ASL_ACCUMULATOR = 2
CYCLES_ASL_ZEROPAGE = 5
CYCLES_ASL_ZEROPAGE_X = 6
CYCLES_ASL_ABSOLUTE = 6
CYCLES_ASL_ABSOLUTE_X = 7

; BCC - Branch on Carry Clear
BCC_RELATIVE = $90     ; Relative Addressing

; Byte Counts
BYTES_BBC_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BBC_RELATIVE = 2
CYCLES_BBC_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BBC_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BCS - Branch on Carry Set
BCS_RELATIVE = $B0     ; Relative Addressing

; Byte Counts
BYTES_BCS_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BCS_RELATIVE = 2
CYCLES_BCS_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BCS_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BEQ - Branch on Result Zero
BEQ_RELATIVE = $F0     ; Relative Addressing

; Byte Counts
BYTES_BEQ_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BEQ_RELATIVE = 2
CYCLES_BEQ_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BEQ_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BIT - Test Bits in Memory with Accumulator
BIT_ZEROPAGE = $24     ; Zero-Page Addressing
BIT_ABSOLUTE = $2C     ; Absolute Addressing

; Byte Counts
BYTES_BIT_ZEROPAGE = 2
BYTES_BIT_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BIT_ZEROPAGE = 3
CYCLES_BIT_ABSOLUTE = 4

; BMI - Branch on Result Minus
BMI_RELATIVE = $30     ; Relative Addressing

; Byte Counts
BYTES_BMI_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BMI_RELATIVE = 2
CYCLES_BMI_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BMI_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BNE - Branch on Result not Zero
BNE_RELATIVE = $D0     ; Relative Addressing

; Byte Counts
BYTES_BNE_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BNE_RELATIVE = 2
CYCLES_BNE_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BNE_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BPL - Branch on Result Plus
BPL_RELATIVE = $10     ; Relative Addressing

; Byte Counts
BYTES_BPL_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BPL_RELATIVE = 2
CYCLES_BPL_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BPL_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BRK - Force Break
BRK_IMPLIED = $00      ; Implied Addressing

; Byte Counts
BYTES_BRK_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BRK_IMPLIED = 7

; BVC - Branch on Overflow Clear
BVC_RELATIVE = $70     ; Relative Addressing

; Byte Counts
BYTES_BVC_RELATIVE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BVC_RELATIVE = 2
CYCLES_BVC_RELATIVE_BRANCH_SAME_PAGE = 3       ; Add 1 to cycles if branch occurs on same page
CYCLES_BVC_RELATIVE_BRANCH_DIFFERENT_PAGE = 4  ; Add 2 to cycles if branch occurs to different page

; BVS - Branch on Overflow Set
BVS_RELATIVE = $18     ; Relative Addressing

; Byte Counts
BYTES_BVS_RELATIVE = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_BVS_RELATIVE = 2

; CLC - Clear Carry Flag
CLC_IMPLIED = $18      ; Implied Addressing

; Byte Counts
BYTES_CLC_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CLC_IMPLIED = 2

; CLD - Clear Decimal Mode
CLD_IMPLIED = $D8      ; Implied Addressing

; Byte Counts
BYTES_CLD_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CLD_IMPLIED = 2

; CLI - Clear Interrupt Disable Bit
CLI_IMPLIED = $58      ; Implied Addressing

; Byte Counts
BYTES_CLI_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CLI_IMPLIED = 2

; CLV - Clear Overflow Flag
CLV_IMPLIED = $B8      ; Implied Addressing

; Byte Counts
BYTES_CLV_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.

CYCLES_CLV_IMPLIED = 2

; CMP - Compare Memory with Accumulator
CMP_IMMEDIATE = $C9    ; Immediate Addressing
CMP_ZEROPAGE = $C5     ; Zero-Page Addressing
CMP_ZEROPAGE_X = $D5   ; Zero-Page Addressing (X)
CMP_ABSOLUTE = $CD     ; Absolute Addressing
CMP_ABSOLUTE_X = $DD   ; Absolute Addressing (X)
CMP_ABSOLUTE_Y = $D9   ; Absolute Addressing (Y)
CMP_INDIRECT_X = $C1   ; Indirect Addressing (X)
CMP_INDIRECT_Y = $D1   ; Indirect Addressing (Y)

; Byte Counts
BYTES_CMP_IMMEDIATE = 2
BYTES_CMP_ZEROPAGE = 2
BYTES_CMP_ZEROPAGE_X = 2
BYTES_CMP_ABSOLUTE = 3
BYTES_CMP_ABSOLUTE_X = 3
BYTES_CMP_ABSOLUTE_Y = 3
BYTES_CMP_INDIRECT_X = 2
BYTES_CMP_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CMP_IMMEDIATE = 2
CYCLES_CMP_ZEROPAGE = = 3
CYCLES_CMP_ZEROPAGE_X = 4
CYCLES_CMP_ABSOLUTE = 4
CYCLES_CMP_ABSOLUTE_X = 4
CYCLES_CMP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_CMP_ABSOLUTE_Y = 4
CYCLES_CMP_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_CMP_INDIRECT_X = 6
CYCLES_CMP_INDIRECT_Y = 5
CYCLES_CMP_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6   ; Add 1 to cycles if page boundary is crossed

; CPX - Compare Memory and Index X
CPX_IMMEDIATE = $E0    ; Immediate Addressing
CPX_ZEROPAGE = $E4     ; Zero-Page Addressing
CPX_ABSOLUTE = $EC     ; Absolute Addressing

; Byte Counts
BYTES_CPX_IMMEDIATE = 2
BYTES_CPX_ZEROPAGE = 2
BYTES_CPX_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CPX_IMMEDIATE = 2
CYCLES_CPX_ZEROPAGE = 3
CYCLES_CPX_ABSOLUTE 4

; CPY - Compare Memory and Index Y
CPY_IMMEDIATE = $C0    ; Immediate Addressing
CPY_ZEROPAGE = $C4     ; Zero-Page Addressing
CPY_ABSOLUTE = $CC     ; Absolute Addressing

; Byte Counts
BYTES_CPY_IMMEDIATE = 2
BYTES_CPY_ZEROPAGE = 2
BYTES_CPY_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_CPY_IMMEDIATE = 2
CYCLES_CPY_ZEROPAGE = 3
CYCLES_CPY_ABSOLUTE = 4

; DEC - Decrement Memory by One
DEC_ZEROPAGE = $C6     ; Zero-Page Addressing
DEC_ZEROPAGE_X = $D6   ; Zero-Page Addressing (X)
DEC_ABSOLUTE = $CE     ; Absolute Addressing
DEC_ABSOLUTE_X = $DE   ; Absolute Addressing (X)

; Byte Counts
BYTES_DEC_ZEROPAGE = 2
BYTES_DEC_ZEROPAGE_X = 2
BYTES_DEC_ABSOLUTE = 3
BYTES_DEC_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_DEC_ZEROPAGE = 5
CYCLES_DEC_ZEROPAGE_X = 6
CYCLES_DEC_ABSOLUTE = 6
CYCLES_DEC_ABSOLUTE_X = 7

; DEX - Decrement Index X by One
DEX_IMPLIED = $CA      ; Implied Addressing

; Byte Counts
BYTES_DEX_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_DEX_IMPLIED = 2

; DEY - Decrement Index Y by One
DEY_IMPLIED = $88      ; Implied Addressing

; Byte Counts
BYTES_DEY_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_DEY_IMPLIED = 2

; EOR - Exclusive-OR Memory with Accumulator
EOR_IMMEDIATE = $49    ; Immediate Addressing
EOR_ZEROPAGE = $45     ; Zero-Page Addressing
EOR_ZEROPAGE_X = $55   ; Zero-Page Addressing (X)
EOR_ABSOLUTE = $4D     ; Absolute Addressing
EOR_ABSOLUTE_X = $5D   ; Absolute Addressing (X)
EOR_ABSOLUTE_Y = $59   ; Absolute Addressing (Y)
EOR_INDIRECT_X = $41   ; Indirect Addressing (X)
EOR_INDIRECT_Y = $51   ; Indirect Addressing (Y)

; Byte Counts
BYTES_EOR_IMMEDIATE = 2
BYTES_EOR_ZEROPAGE = 2
BYTES_EOR_ZEROPAGE_X = 2
BYTES_EOR_ABSOLUTE = 3
BYTES_EOR_ABSOLUTE_X = 3
BYTES_EOR_ABSOLUTE_Y = 3
BYTES_EOR_INDIRECT_X = 2
BYTES_EOR_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_EOR_IMMEDIATE = 2
CYCLES_EOR_ZEROPAGE = 3
CYCLES_EOR_ZEROPAGE_X = 4
CYCLES_EOR_ABSOLUTE = 4
CYCLES_EOR_ABSOLUTE_X = 4
CYCLES_EOR_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_EOR_ABSOLUTE_Y = 4
CYCLES_EOR_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_EOR_INDIRECT_X = 6
CYCLES_EOR_INDIRECT_Y = 5
CYCLES_EOR_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6   ; Add 1 to cycles if page boundary is crossed

; INC - Increment Memory by One
INC_ZEROPAGE = $E6     ; Zero-Page Addressing
INC_ZEROPAGE_X = $F6   ; Zero-Page Addressing (X)
INC_ABSOLUTE = $EE     ; Absolute Addressing
INC_ABSOLUTE_X = $FE   ; Absolute Addressing (X)

; Byte Counts
BYTES_INC_ZEROPAGE = 2
BYTES_INC_ZEROPAGE_X = 2
BYTES_INC_ABSOLUTE = 3
BYTES_INC_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_INC_ZEROPAGE = 5
CYCLES_INC_ZEROPAGE_X = 6
CYCLES_INC_ABSOLUTE = 6
CYCLES_INC_ABSOLUTE_X 7

; INX - Increment Index X by One
INX_IMPLIED = $E8      ; Implied Addressing

; Byte Counts
BYTES_INX_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_INX_IMPLIED = 2

; INY - Increment Index Y by One
INY_IMPLIED = $C8      ; Implied Addressing

; Byte Counts
BYTES_INY_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_INY_IMPLIED = 2

; JMP - Jump to New Location
JMP_ABSOLUTE = $4C     ; Absolute Addressing
JMP_INDIRECT = $6C     ; Indirect Addressing

; Byte Counts
BYTES_JMP_ABSOLUTE = 3
BYTES_JMP_INDIRECT = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_JMP_ABSOLUTE = 3
CYCLES_JMP_INDIRECT = 5

; JSR - Jump to New Location Saving Return Address
JSR_ABSOLUTE = $20     ; Absolute Addressing

; Byte Counts
BYTES_JSR_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_JSR_ABSOLUTE = 6

; LDA - Load Accumulator with Memory
LDA_IMMEDIATE = $A9    ; Immediate Addressing
LDA_ZEROPAGE = $A5     ; Zero-Page Addressing
LDA_ZEROPAGE_X = $B5   ; Zero-Page Addressing (X)
LDA_ABSOLUTE = $AD     ; Absolute Addressing
LDA_ABSOLUTE_X = $BD   ; Absolute Addressing (X)
LDA_ABSOLUTE_Y = $B9   ; Absolute Addressing (Y)
LDA_INDIRECT_X = $A1   ; Indirect Addressing (X)
LDA_INDIRECT_Y = $B1   ; Indirect Addressing (Y)

; Byte Counts
BYTES_LDA_IMMEDIATE = 2
BYTES_LDA_ZEROPAGE = 2
BYTES_LDA_ZEROPAGE_X = 2
BYTES_LDA_ABSOLUTE = 3
BYTES_LDA_ABSOLUTE_X = 3
BYTES_LDA_ABSOLUTE_Y = 3
BYTES_LDA_INDIRECT_X = 2
BYTES_LDA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LDA_IMMEDIATE = 2
CYCLES_LDA_ZEROPAGE = 3
CYCLES_LDA_ZEROPAGE_X = 4
CYCLES_LDA_ABSOLUTE = 4
CYCLES_LDA_ABSOLUTE_X = 4
CYCLES_LDA_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_LDA_ABSOLUTE_Y = 4
CYCLES_LDA_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed
CYCLES_LDA_INDIRECT_X = 6
CYCLES_LDA_INDIRECT_Y = 5
CYCLES_LDA_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6   ; Add 1 to cycles if page boundary is crossed

; LDX - Load Index X with Memory
LDX_IMMEDIATE = $A2    ; Immediate Addressing
LDX_ZEROPAGE = $A6     ; Zero-Page Addressing
LDX_ZEROPAGE_Y $B6     ; Zero-Page Addressing (Y)
LDX_ABSOLUTE = $AE     ; Absolute Addressing
LDX_ABSOLUTE_Y = $BE   ; Absolute Addressing (Y)

; Byte Counts
BYTES_LDX_IMMEDIATE = 2
BYTES_LDX_ZEROPAGE = 2
BYTES_LDX_ZEROPAGE_Y = 2
BYTES_LDX_ABSOLUTE = 3
BYTES_LDX_ABSOLUTE_Y = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LDX_IMMEDIATE = 2
CYCLES_LDX_ZEROPAGE = 3
CYCLES_LDX_ZEROPAGE_Y = 4
CYCLES_LDX_ABSOLUTE = 4
CYCLES_LDX_ABSOLUTE_Y = 4
CYCLES_LDX_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed

; LDY - Load Index Y with Memory
LDY_IMMEDIATE = $A0    ; Immediate Addressing
LDY_ZEROPAGE = $A4     ; Zero-Page Addressing
LDY_ZEROPAGE_X = $B4   ; Zero-Page Addressing (X)
LDY_ABSOLUTE = $AC     ; Absolute Addressing
LDY_ABSOLUTE_X = $BC   ; Absolute Addressing (X)

; Byte Counts
BYTES_LDY_IMMEDIATE = 2
BYTES_LDY_ZEROPAGE = 2
BYTES_LDY_ZEROPAGE_X = 2
BYTES_LDY_ABSOLUTE = 3
BYTES_LDY_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LDY_IMMEDIATE = 2
CYCLES_LDY_ZEROPAGE = 3
CYCLES_LDY_ZEROPAGE_X = 4
CYCLES_LDY_ABSOLUTE = 4
CYCLES_LDY_ABSOLUTE_X = 4
CYCLES_LDY_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5   ; Add 1 to cycles if page boundary is crossed

; LSR - Shift One Bit Right (Memory or Accumulator)
LSR_ACCUMULATOR = $4A  ; Accumulator
LSR_ZEROPAGE = $46     ; Zero-Page Addressing
LSR_ZEROPAGE_X = $56   ; Zero-Page Addressing (X)
LSR_ABSOLUTE = $4E     ; Absolute Addressing
LSR_ABSOLUTE_X = $5E   ; Absolute Addressing (X)

; Byte Counts
BYTES_LSR_ACCUMULATOR = 1
BYTES_LSR_ZEROPAGE = 2
BYTES_LSR_ZEROPAGE_X = 2
BYTES_LSR_ABSOLUTE = 3
BYTES_LSR_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LSR_ACCUMULATOR = 2
CYCLES_LSR_ZEROPAGE = 5
CYCLES_LSR_ZEROPAGE_X = 6
CYCLES_LSR_ABSOLUTE = 6
CYCLES_LSR_ABSOLUTE_X = 7

; NOP - No Operation
NOP_IMPLIED = $EA      ; Implied Addressing

; Byte Counts
BYTES_NOP_IMPLIED = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_NOP_IMPLIED = 3

; ORA - OR Memory with Accumulator
ORA_IMMEDIATE = $09    ; Immediate Addressing
ORA_ZEROPAGE = $05     ; Zero-Page Addressing
ORA_ZEROPAGE_X = $15   ; Zero-Page Addressing (X)
ORA_ABSOLUTE = $0D     ; Absolute Addressing
ORA_ABSOLUTE_X = $1D   ; Absolute Addressing (X)
ORA_ABSOLUTE_Y = $19   ; Absolute Addressing (Y)
ORA_INDIRECT = $01     ; Indirect Addressing (X)
ORA_INDIRECT_Y = $11   ; Indirect Addressing (Y)

; Byte Counts
BYTES_ORA_IMMEDIATE = 2
BYTES_ORA_ZEROPAGE = 2
BYTES_ORA_ZEROPAGE_X = 2
BYTES_ORA_ABSOLUTE = 3
BYTES_ORA_ABSOLUTE_X = 3
BYTES_ORA_ABSOLUTE_Y = 3
BYTES_ORA_INDIRECT = 2
BYTES_ORA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ORA_IMMEDIATE = 2
CYCLES_ORA_ZEROPAGE = 3
CYCLES_ORA_ZEROPAGE_X = 4
CYCLES_ORA_ABSOLUTE = 4
CYCLES_ADC_ABSOLUTE_X = 4
CYCLES_ORA_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_ORA_ABSOLUTE_Y = 4
CYCLES_ORA_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_ORA_INDIRECT = 6
CYCLES_ORA_INDIRECT_Y = 5
CYCLES_ORA_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6  ; Add 1 to cycles if page boundary is crossed

; PHA - Push Accumulator on Stack
PHA_IMPLIED = $48      ; Implied Addressing

; Byte Counts
BYTES_PHA_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_PHA_IMPLIED = 3

; PHP - Push Processor Status on Stack
PHP_IMPLIED = $08      ; Implied Addressing

; Byte Counts
BYTES_PHP_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_PHP_IMPLIED = 3

; PLA - Pull Accumulator from Stack
PLA_IMPLIED = $68      ; Implied Addressing

; Byte Counts
BYTES_PLA_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_PLA_IMPLIED = 4

; PLP - Pull Processor Status from Stack
PLP_IMPLIED = $28      ; Implied Addressing

; Byte Counts
BYTES_PLP_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_PLP_IMPLIED = 4

; ROL - Rotate One Bit Left (Memory or Accumulator)
ROL_ACCUMULATOR = $2A  ; Accumulator
ROL_ZEROPAGE = $26     ; Zero-Page Addressing
ROL_ZEROPAGE_X = $36   ; Zero-Page Addressing (X)
ROL_ABSOLUTE = $2E     ; Absolute Addressing
ROL_ABSOLUTE_X = $3E   ; Absolute Addressing (X)

; Byte Counts
BYTES_ROL_ACCUMULATOR = 1
BYTES_ROL_ZEROPAGE = 2
BYTES_ROL_ZEROPAGE_X = 2
BYTES_ROL_ABSOLUTE = 3
BYTES_ROL_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ROL_ACCUMULATOR = 2
CYCLES_ROL_ZEROPAGE = 5
CYCLES_ROL_ZEROPAGE_X = 6
CYCLES_ROL_ABSOLUTE = 6
CYCLES_ROL_ABSOLUTE_X = 7

; ROR - Rotate One Bit Right (Memory or Accumulator)
ROR_ACCUMULATOR = $6A  ; Accumulator
ROR_ZEROPAGE = $66     ; Zero-Page Addressing
ROR_ZEROPAGE_X = $76   ; Zero-Page Addressing (X)
ROR_ABSOLUTE = $6E     ; Absolute Addressing
ROR_ABSOLUTE_X = $7E   ; Absolute Addressing (X)

; Byte Counts
BYTES_ROR_ACCUMULATOR = 1
BYTES_ROR_ZEROPAGE = 2
BYTES_ROR_ZEROPAGE_X = 2
BYTES_ROR_ABSOLUTE = 3
BYTES_ROR_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ROR_ACCUMULATOR = 2
CYCLES_ROR_ZEROPAGE = 5
CYCLES_ROR_ZEROPAGE_X = 6
CYCLES_ROR_ABSOLUTE = 6
CYCLES_ROR_ABSOLUTE_X = 7

; RTI - Return from Interrupt
RTI_IMPLIED = $40      ; Implied Addressing

; Byte Counts
BYTES_RTI_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_RTI_IMPLIED = 6

; RTS - Return from Subroutine
RTS_IMPLIED = $60      ; Implied Addressing

; Byte Counts
BYTES_RTS_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_RTS_IMPLIED = 6

; SBC - Subtract Memory from Accumulator with Borrow
SBC_IMMEDIATE = $E9    ; Immediate Addressing
SBC_ZEROPAGE = $E5     ; Zero-Page Addressing
SBC_ZEROPAGE_X = $F5   ; Zero-Page Addressing (X)
SBC_ABSOLUTE = $ED     ; Absolute Addressing
SBC_ABSOLUTE_X = $FD   ; Absolute Addressing (X)
SBC_ABSOLUTE_Y = $F9   ; Absolute Addressing (Y)
SBC_INDIRECT_X = $E1   ; Indirect Addressing (X)
SBC_INDIRECT_Y = $F1   ; Indirect Addressing (Y)

; Byte Counts
BYTES_SBC_IMMEDIATE = 2
BYTES_SBC_ZEROPAGE = 2
BYTES_SBC_ZEROPAGE_X = 2
BYTES_SBC_ABSOLUTE = 3
BYTES_SBC_ABSOLUTE_X = 3
BYTES_SBC_ABSOLUTE_Y = 3
BYTES_SBC_INDIRECT_X = 2
BYTES_SBC_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SBC_IMMEDIATE = 2
CYCLES_SBC_ZEROPAGE = 3
CYCLES_SBC_ZEROPAGE_X = 4
CYCLES_SBC_ABSOLUTE = 4
CYCLES_SBC_ABSOLUTE_X = 4
CYCLES_SBC_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_SBC_ABSOLUTE_Y = 4
CYCLES_SBC_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_SBC_INDIRECT_X = 6
CYCLES_SBC_INDIRECT_Y = 5
CYCLES_SBC_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6  ; Add 1 to cycles if page boundary is crossed

; SEC - Set Carry Flag
SEC_IMPLIED = $38      ; Implied Addressing

; Byte Counts
BYTES_SEC_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SEC_IMPLIED = 2

; SED - Set Decimal Flag
SED_IMPLIED = $F8      ; Implied Addressing

; Byte Counts
BYTES_SED_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SED_IMPLIED = 3

; SEI - Set Interrupt Disable Status
SEI_IMPLIED = $78      ; Implied Addressing

; Byte Counts
BYTES_SEI_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SEI_IMPLIED = 2

; STA - Store Accumulator in Memory
STA_ZEROPAGE = $85     ; Zero-Page Addressing
STA_ZEROPAGE_X = $95   ; Zero-Page Addressing (X)
STA_ABSOLUTE = $8D     ; Absolute Addressing
STA_ABSOLUTE_X = $9D   ; Absolute Addressing (X)
STA_ABSOLUTE_Y = $99   ; Absolute Addressing (Y)
STA_INDIRECT_X = $81   ; Indirect Addressing (X)
STA_INDIRECT_Y = $91   ; Indirect Addressing (Y)

; Byte Counts
BYTES_STA_ZEROPAGE = 2
BYTES_STA_ZEROPAGE_X = 2
BYTES_STA_ABSOLUTE = 3
BYTES_STA_ABSOLUTE_X = 3
BYTES_STA_ABSOLUTE_Y = 3
BYTES_STA_INDIRECT_X = 2
BYTES_STA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_STA_ZEROPAGE = 3
CYCLES_STA_ZEROPAGE_X = 4
CYCLES_STA_ABSOLUTE = 4
CYCLES_STA_ABSOLUTE_X = 5
CYCLES_STA_ABSOLUTE_Y = 5
CYCLES_STA_INDIRECT_X = 6
CYCLES_STA_INDIRECT_Y = 6

; STX - Store Index X in Memory
STX_ZEROPAGE = $86     ; Zero-Page Addressing
STX_ZEROPAGE_Y = $96   ; Zero-Page Addressing (Y)
STX_ABSOLUTE = $8E     ; Absolute Addressing

; Byte Counts
BYTES_STX_ZEROPAGE = 2
BYTES_STX_ZEROPAGE_X = 2
BYTES_STX_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_STX_ZEROPAGE = 3
CYCLES_STX_ZEROPAGE_X = 4
CYCLES_STX_ABSOLUTE = 4

; STY - Sore Index Y in Memory
STY_ZEROPAGE = $84     ; Zero-Page Addressing
STY_ZEROPAGE_X = $94   ; Zero-Page Addressing (X)
STY_ABSOLUTE = $8C     ; Absolute Addressing

; Byte Counts
BYTES_STY_ZEROPAGE = 2
BYTES_STY_ZEROPAGE_X = 2
BYTES_STY_ABSOLUTE = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_STY_ZEROPAGE = 3
CYCLES_STY_ZEROPAGE_X = 4
CYCLES_STY_ABSOLUTE = 4

; TAX - Transfer Accumulator to Index X
TAX_IMPLIED = $AA      ; Implied Addressing

; Byte Counts
BYTES_TAX_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TAX_IMPLIED = 2

; TAY - Transfer Accumulator to Index Y
TAY_IMPLIED = $A8      ; Implied Addressing

; Byte Counts
BYTES_TAY_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TAY_IMPLIED = 2

; TSX - Transfer Stack Pointer to Index X
TSX_IMPLIED = $BA      ; Implied Addressing

; Byte Counts
BYTES_TSX_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TSX_IMPLIED = 2

; TXA - Transfer Index X to Accumulator
TXA_IMPLIED = $8A      ; Implied Addressing

; Byte Counts
BYTES_TSA_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TSA_IMPLIED = 2

; TXS - Transfer Index X to Stack Register
TXS_IMPLIED = $9A      ; Implied Addressing

; Byte Counts
BYTES_TXS_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TXS_IMPLIED = 2

; TYA - Transfer Index Y to Accumulator
TYA_IMPLIED = $98      ; Implied Addressing

; Byte Counts
BYTES_TYA_IMPLIED = 1

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TYA_IMPLIED = 2

; "Illegal" Opcodes and Undocumented Instructions
; The following instructions are undocumented are not guaranteed to work.
; ALR (ASR)
ALR_IMMEDIATE = $4B    ; Immediate Addressing

; Byte Counts
BYTES_ALR_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ALR_IMMEDIATE = 2

; ANC
ANC_IMMEDIATE = $0B    ; Immediate Addressing

; Byte Counts
BYTES_ANC_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ANC_IMMEDIATE = 2

; ANC (ANC2)
ANC_IMMEDIATE = $2B    ; Immediate Addressing

; Byte Counts
BYTES_ANC_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ANC_IMMEDIATE = 2

; ANE (XAA)
ANE_IMMEDIATE = $8B    ; Immediate Addressing

; Byte Counts
BYTES_ANE_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ANE_IMMEDIATE = 2    ; Highly unstable

; ARR
ARR_IMMEDIATE = $6B    ; Immediate Addressing

; Byte Counts
BYTES_ARR_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ARR_IMMEDIATE = 2

; DCP (DCM)
DCP_ZEROPAGE = $C7     ; Zero-Page Addressing
DCP_ZEROPAGE_X = $D7   ; Zero-Page Addressing (X)
DCP_ABSOLUTE = $CF     ; Absolute Addressing
DCP_ABSOLUTE_X = $DF   ; Absolute Addressing (X)
DCP_ABSOLUTE_Y = $DB   ; Absolute Addressing (Y)
DCP_INDIRECT_X = $C3   ; Indirect Addressing (X)
DCP_INDIRECT_Y = $D3   ; Indirect Addressing (Y)

; Byte Counts
BYTES_DCP_ZEROPAGE = 2
BYTES_DCP_ZEROPAGE_X = 2
BYTES_DCP_ABSOLUTE = 3
BYTES_DCP_ABSOLUTE_X = 3
BYTES_DCP_ABSOLUTE_Y = 3
BYTES_DCP_INDIRECT_X = 2
BYTES_DCP_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_DCP_ZEROPAGE = 5
CYCLES_DCP_ZEROPAGE_X = 6
CYCLES_DCP_ABSOLUTE = 6
CYCLES_DCP_ABSOLUTE_X = 7
CYCLES_DCP_ABSOLUTE_Y = 7
CYCLES_DCP_INDIRECT_X = 8
CYCLES_DCP_INDIRECT_Y = 8

; ISC (ISB, INS)
ISC_ZEROPAGE = $E7     ; Zero-Page Addressing
ISC_ZEROPAGE_X = $F7   ; Zero-Page Addressing (X)
ISC_ABSOLUTE = $EF     ; Absolute Addressing
ISC_ABSOLUTE_X = $FF   ; Absolute Addressing (X)
ISC_ABSOLUTE_Y = $FB   ; Absolute Addressing (Y)
ISC_INDIRECT_X = $E3   ; Indirect Addressing (X)
ISC_INDIRECT_Y = $F3   ; Indirect Addressing (Y)

; Byte Counts
BYTES_ISC_ZEROPAGE = 2
BYTES_ISC_ZEROPAGE_X = 2
BYTES_ISC_ABSOLUTE = 3
BYTES_ISC_ABSOLUTE_X = 3
BYTES_ISC_ABSOLUTE_Y = 3
BYTES_ISC_INDIRECT_X = 2
BYTES_ISC_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ISC_ZEROPAGE = 5
CYCLES_ISC_ZEROPAGE_X = 6
CYCLES_ISC_ABSOLUTE = 6
CYCLES_ISC_ABSOLUTE_X = 7
CYCLES_ISC_ABSOLUTE_Y = 7
CYCLES_ISC_INDIRECT_X = 8
CYCLES_ISC_INDIRECT_Y = 8

; LAS (LAR)
LAS_ABSOLUTE_Y = $BB   ; Absolute Addressing (Y)

; Byte Counts
BYTES_LAS_ABSOLUTE_Y = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LAS_ABSOLUTE_Y = 4
CYCLES_LAS_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed

; LAX
LAX_ZEROPAGE = $A7     ; Zero-Page Addressing
LAX_ZEROPAGE_Y = $B7   ; Zero-Page Addressing (Y)
LAX_ABSOLUTE = $AF     ; Absolute Addressing
LAX_ABSOLUTE_Y = $BF   ; Absolute Addressing (Y)
LAX_INDIRECT_X = $A3   ; Indirect Addressing (X)
LAX_INDIRECT_Y = $B3   ; Indirect Addressing (Y)

; Byte Counts
BYTES_LAX_ZEROPAGE = 2
BYTES_LAX_ZEROPAGE_Y = 2
BYTES_LAX_ABSOLUTE = 3
BYTES_LAX_ABSOLUTE_Y = 3
BYTES_LAX_INDIRECT_X = 2
BYTES_LAX_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LAX_ZEROPAGE = 3
CYCLES_LAX_ZEROPAGE_Y = 4
CYCLES_LAX_ABSOLUTE = 4
CYCLES_LAX_ABSOLUTE_Y 4
CYCLES_LAX_ABSOLUTE_Y_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_LAX_INDIRECT_X = 6
CYCLES_LAX_INDIRECT_Y = 5
CYCLES_LAX_INDIRECT_Y_PAGE_BOUNDARY_CROSSED = 6  ; Add 1 to cycles if page boundary is crossed

; LXA (LAX immediate)
LXA_IMMEDIATE = $AB    ; Immediate Addressing

; Byte Counts
BYTES_LXA_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_LXA_IMMEDIATE = 2    ; Highly unstable

; RLA
RLA_ZEROPAGE = $27     ; Zero-Page Addressing
RLA_ZEROPAGE_X = $37   ; Zero-Page Addressing (X)
RLA_ABSOLUTE = $2F     ; Absolute Addressing
RLA_ABSOLUTE_X = $3F   ; Absolute Addressing (X)
RLA_ABSOLUTE_Y = $3B   ; Absolute Addressing (Y)
RLA_INDIRECT_X = $23   ; Indirect Addressing (X)
RLA_INDIRECT_Y = $33   ; Indirect Addressing (Y)

; Byte Counts
BYTES_RLA_ZEROPAGE = 2
BYTES_RLA_ZEROPAGE_X = 2
BYTES_RLA_ABSOLUTE = 3
BYTES_RLA_ABSOLUTE_X = 3
BYTES_RLA_ABSOLUTE_Y = 3
BYTES_RLA_INDIRECT_X = 2
BYTES_RLA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_RLA_ZEROPAGE = 5
CYCLES_RLA_ZEROPAGE_X = 6
CYCLES_RLA_ABSOLUTE = 6
CYCLES_RLA_ABSOLUTE_X = 7
CYCLES_RLA_ABSOLUTE_Y = 7
CYCLES_RLA_INDIRECT_X = 8
CYCLES_RLA_INDIRECT_Y = 8

; RRA
RRA_ZEROPAGE = $67     ; Zero-Page Addressing
RRA_ZEROPAGE_X = $77   ; Zero-Page Addressing (X)
RRA_ABSOLUTE = $6F     ; Absolute Addressing
RRA_ABSOLUTE_X = $7F   ; Absolute Addressing (X)
RRA_ABSOLUTE_Y = $7B   ; Absolute Addressing (Y)
RRA_INDIRECT_X = $63   ; Indirect Addressing (X)
RRA_INDIRECT_Y = $73   ; Indirect Addressing (Y)

; Byte Counts
BYTES_RRA_ZEROPAGE = 2
BYTES_RRA_ZEROPAGE_X = 2
BYTES_RRA_ABSOLUTE = 3
BYTES_RRA_ABSOLUTE_X = 3
BYTES_RRA_ABSOLUTE_Y = 3
BYTES_RRA_INDIRECT_X = 2
BYTES_RRA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_RRA_ZEROPAGE = 5
CYCLES_RRA_ZEROPAGE_X = 6
CYCLES_RRA_ABSOLUTE = 6
CYCLES_RRA_ABSOLUTE_X = 7
CYCLES_RRA_ABSOLUTE_Y = 7
CYCLES_RRA_INDIRECT_X = 8
CYCLES_RRA_INDIRECT_Y = 8

; SAX (AXS, AAX)
SAX_ZEROPAGE = $87     ; Zero-Page Addressing
SAX_ZEROPAGE_Y = $97   ; Zero-Page Addressing (Y)
SAX_ABSOLUTE = $8F     ; Absolute Addressing
SAX_INDIRECT = $83     ; Indirect Addressing (X)

; Byte Counts
BYTES_SAX_ZEROPAGE = 2
BYTES_SAX_ZEROPAGE_Y = 2
BYTES_SAX_ABSOLUTE = 3
BYTES_SAX_INDIRECT = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SAX_ZEROPAGE = 3
CYCLES_SAX_ZEROPAGE_Y = 4
CYCLES_SAX_ABSOLUTE = 4
CYCLES_SAX_INDIRECT = 6

; SBX (AXS, SAX)
SBX_IMMEDIATE = $CB    ; Immediate Addressing

; Byte Counts
BYTES_SBX_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SBX_IMMEDIATE = 2

; SHA (AHX, AXA)
SHA_ABSOLUTE_Y = $9F   ; Absolute Addressing (Y)
SHA_INDIRECT_Y = $93   ; Indirect Addressing (Y)

; Byte Counts
BYTES_SHA_ABSOLUTE_Y = 3
BYTES_SHA_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SHA_ABSOLUTE_Y = 5    ; Unstable
CYCLES_SHA_INDIRECT_Y = 6    ; Unstable

; SHX (A11, SXA, XAS)
SHX_ABSOLUTE_Y = $9E   ; Absolute Addressing (Y)

; Byte Counts
BYTES_SHX_ABSOLUTE_Y = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SHX_ABSOLUTE_Y = 5    ; Unstable

; SHY (A11, SYA, SAY)
SHY_ABSOLUTE_X = $9C   ; Absolute Addressing (X)

; Byte Counts
BYTES_SHY_ABSOLUTE_Y = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SHY_ABSOLUTE_Y = 5    ; Unstable

; SLO (ASO)
SLO_ZEROPAGE = $07     ; Zero-Page Addressing
SLO_ZEROPAGE_X = $17   ; Zero-Page Addressing (X)
SLO_ABSOLUTE = $0F     ; Absolute Addressing
SLO_ABSOLUTE_X = $1F   ; Absolute Addressing (X)
SLO_ABSOLUTE_Y = $1B   ; Absolute Addressing (Y)
SLO_INDIRECT_X = $03   ; Indirect Addressing (X)
SLO_INDIRECT_Y = $13   ; Indirect Addressing (Y)

; Byte Counts
BYTES_SLO_ZEROPAGE = 2
BYTES_SLO_ZEROPAGE_X = 2
BYTES_SLO_ABSOLUTE = 3
BYTES_SLO_ABSOLUTE_X = 3
BYTES_SLO_ABSOLUTE_Y = 3
BYTES_SLO_INDIRECT_X = 2
BYTES_SLO_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SLO_ZEROPAGE = 5
CYCLES_SLO_ZEROPAGE_X = 6
CYCLES_SLO_ABSOLUTE = 6
CYCLES_SLO_ABSOLUTE_X = 7
CYCLES_SLO_ABSOLUTE_Y = 7
CYCLES_SLO_INDIRECT_X = 8
CYCLES_SLO_INDIRECT_Y = 8

; SRE (LSE)
SRE_ZEROPAGE = $47     ; Zero-Page Addressing
SRE_ZEROPAGE_X = $57   ; Zero-Page Addressing (X)
SRE_ABSOLUTE = $4F     ; Absolute Addressing
SRE_ABSOLUTE_X = $5F   ; Absolute Addressing (X)
SRE_ABSOLUTE_Y = $5B   ; Absolute Addressing (Y)
SRE_INDIRECT_X = $43   ; Indirect Addressing (X)
SRE_INDIRECT_Y = $53   ; Indirect Addressing (Y)

; Byte Counts
BYTES_SRE_ZEROPAGE = 2
BYTES_SRE_ZEROPAGE_X = 2
BYTES_SRE_ABSOLUTE = 3
BYTES_SRE_ABSOLUTE_X = 3
BYTES_SRE_ABSOLUTE_Y = 3
BYTES_SRE_INDIRECT_X = 2
BYTES_SRE_INDIRECT_Y = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_SRE_ZEROPAGE = 5
CYCLES_SRE_ZEROPAGE_X = 6
CYCLES_SRE_ABSOLUTE = 6
CYCLES_SRE_ABSOLUTE_X = 7
CYCLES_SRE_ABSOLUTE_Y = 7
CYCLES_SRE_INDIRECT_X = 8
CYCLES_SRE_INDIRECT_Y = 8

; TAS (XAS, SHS)
TAS_ABSOLUTE_Y = $9B   ; Absolute Addressing (Y)

; Byte Counts
BYTES_TAS_ABSOLUTE_Y = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_TAS_ABSOLUTE_Y = 5    ; Unstable

; USBC (SBC)
USBC_IMMEDIATE = $EB   ; Immediate Addressing

; Byte Counts
BYTES_USBC_IMMEDIATE = 2

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_USBC_IMMEDIATE = 2

; NOPs (including DOP, TOP)
NOP_IMPLIED = $1A      ; Implied Addressing
NOP_IMPLIED = $3A      ; Implied Addressing
NOP_IMPLIED = $5A      ; Implied Addressing
NOP_IMPLIED = $7A      ; Implied Addressing
NOP_IMPLIED = $DA      ; Implied Addressing
NOP_IMPLIED = $FA      ; Implied Addressing
NOP_IMMEDIATE = $80    ; Immediate Addressing
NOP_IMMEDIATE = $82    ; Immediate Addressing
NOP_IMMEDIATE = $89    ; Immediate Addressing
NOP_IMMEDIATE = $C2    ; Immediate Addressing
NOP_IMMEDIATE = $E2    ; Immediate Addressing
NOP_ZEROPAGE = $04     ; Zero-Page Addressing
NOP_ZEROPAGE = $44     ; Zero-Page Addressing
NOP_ZEROPAGE = $64     ; Zero-Page Addressing
NOP_ZEROPAGE_X = $14   ; Zero-Page Addressing (X)
NOP_ZEROPAGE_X = $34   ; Zero-Page Addressing (X)
NOP_ZEROPAGE_X = $54   ; Zero-Page Addressing (X)
NOP_ZEROPAGE_X = $74   ; Zero-Page Addressing (X)
NOP_ZEROPAGE_X = $D4   ; Zero-Page Addressing (X)
NOP_ZEROPAGE_X = $F4   ; Zero-Page Addressing (X)
NOP_ABSOLUTE = $0C     ; Absolute Addressing
NOP_ABSOLUTE_X = $1C   ; Absolute Addressing (X)
NOP_ABSOLUTE_X = $3C   ; Absolute Addressing (X)
NOP_ABSOLUTE_X = $5C   ; Absolute Addressing (X)
NOP_ABSOLUTE_X = $7C   ; Absolute Addressing (X)
NOP_ABSOLUTE_X = $DC   ; Absolute Addressing (X)
NOP_ABSOLUTE_X = $FC   ; Absolute Addressing (X)

; Byte Counts
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMPLIED = 1
BYTES_NOP_IMMEDIATE = 2
BYTES_NOP_IMMEDIATE = 2
BYTES_NOP_IMMEDIATE = 2
BYTES_NOP_IMMEDIATE = 2
BYTES_NOP_IMMEDIATE = 2
BYTES_NOP_ZEROPAGE = 2
BYTES_NOP_ZEROPAGE = 2
BYTES_NOP_ZEROPAGE = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ZEROPAGE_X = 2
BYTES_NOP_ABSOLUTE = 3
BYTES_NOP_ABSOLUTE_X = 3
BYTES_NOP_ABSOLUTE_X = 3
BYTES_NOP_ABSOLUTE_X = 3
BYTES_NOP_ABSOLUTE_X = 3
BYTES_NOP_ABSOLUTE_X = 3
BYTES_NOP_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMPLIED = 2
CYCLES_NOP_IMMEDIATE = 2
CYCLES_NOP_IMMEDIATE = 2
CYCLES_NOP_IMMEDIATE = 2
CYCLES_NOP_IMMEDIATE = 2
CYCLES_NOP_IMMEDIATE = 2
CYCLES_NOP_ZEROPAGE = 3
CYCLES_NOP_ZEROPAGE = 3
CYCLES_NOP_ZEROPAGE = 3
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ZEROPAGE_X = 4
CYCLES_NOP_ABSOLUTE = 4
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed
CYCLES_NOP_ABSOLUTE_X = 4
CYCLES_NOP_ABSOLUTE_X_PAGE_BOUNDARY_CROSSED = 5  ; Add 1 to cycles if page boundary is crossed

; JAM (KIL, HLT)
; Only the instruction codes are included due to a severe lack of documentation.
$02
$12
$22
$32
$42
$52
$62
$72
$92
$B2
$D2
$F2

; BONUS
; ROR  Rev. A (pre-June 1976)
ROR_ACCUMULATOR = $6A  ; Accumulator
ROR_ZEROPAGE = $66     ; Zero-Page Addressing
ROR_ZEROPAGE_X = $76   ; Zero-Page Addressing (X)
ROR_ABSOLUTE = $6E     ; Absolute Addressing
ROR_ABSOLUTE_X = $7E   ; Absolute Addressing (X)

; Byte Counts
BYTES_ROR_ACCUMULATOR = 1
BYTES_ROR_ZEROPAGE = 2
BYTES_ROR_ZEROPAGE_X = 2
BYTES_ROR_ABSOLUTE = 3
BYTES_ROR_ABSOLUTE_X = 3

; Cycle Counts
; This is a basic implementation of cycle counting. It may not cover all edge cases.
CYCLES_ROR_ACCUMULATOR = 2
CYCLES_ROR_ZEROPAGE = 5
CYCLES_ROR_ZEROPAGE_X = 6
CYCLES_ROR_ABSOLUTE = 6
CYCLES_ROR_ABSOLUTE_X = 7

; Arithmetic Operations
              ; ADC: A = A + M + C
CLC           ; Clear carry in preparation
LDA #2        ; Load 2 into the accumulator
ADD #3        ; Add 3 -> now 5 in accumulator

              ; SBC: A = A - M - C̅   ("C̅": "not carry")
SEC           ; Set carry in preparation
LDA #15       ; Load 15 into the accumulator
SBC #8        ; Subtract 8 -> now 7 in accumulator

; 16-Bit Addition
CLC           ; Prepare carry for addition
LDA $1000     ; Load value at address $1000 into A (low byte of first argument)
ADC $1002     ; Add low byte of second argument at $1002
STA $1004     ; Store low byte of result at $1004
LDA $1001     ; Load high byte of first argument
ADC $1003     ; Add high byte of second argument
STA $1005     ; Store high byte of result (result in $1004 and $1005)

; 16-Bit Subtraction
SEC           ; Prepare carry for subtraction
LDA $1000     ; Load value at address $1000 into A (low byte of first argument)
SBC $1002     ; Subtract low byte of second argument at $1002
STA $1004     ; Store low byte of result at $1004
LDA $1001     ; Load high byte of first argument
SBC $1003     ; Subtract high byte of second argument
STA $1005     ; Store high byte of result (result in $1004 and $1005)

; Signed Values
-512 = %1111.1110.0000.0000 = $FE $00
-516 = %1111.1101.1111.1100 = $FD $FC  ; (mind how the +1 step carries over)

; Flags With ADC and SBC
LDA #$40
ADC #$40

; Decimal Mode (BCD)
; The Ricoh 2A03 and Ricoh 2A07 lack decimal mode. Ignore decimal mode if you're working with the NES.
14  %0001.0100  $14
98  %1001.1000  $98

SED
CLC
LDA #$12
ADC #$44      ; Accumulator now holds $56

SED
CLC
LDA #$28
ADC #$14      ; Accumulator now holds $42

; Mind that BCD mode is always unsigned:
SED
SEC
LDA #0
SBC #1

; Jump Vectors and Stack Operations
$FFFA-$FFFB   ; NMI (Non-Maskable Interrupt) vector
$FFFC-$FFFD   ; RES (Reset) vector
$FFFE-$FFFF   ; IRQ (Interrupt Request) vector

; IRQ, NMI, RTI, BRK Operation
01 0E                  ; SP after IRQ or NMI but before RTI
01 0F STATUS ·
01 10 PCL $02
01 11 PCH $03          ; SP before IRQ or NMI and after RTI
01 12     STACK

03 00                  ; PC at time of IRQ or NMI · this instruction will complete before interrupt is serviced
03 01
03 02                  ; PC after RTI

04 05 ·                ; Interrupt service main body
04 06 ·
04 07 RTI $40          ; Return to interrupt

FF FA ADL              ; NMI vector
FF FB ADH              ; NMI vector
FF FC ADL              ; RES vector
FF FD ADH              ; RES vector
FF FE ADL $05          ; IRQ vector
FF FF ADH $04          ; IRQ vector

; JSR, RTS Operation
01 0E                  ; SP after JSR but before return (RTS)
01 0F PCL $02
01 10 PCH $03          ; SP before JSR and after return (RTS) from subroutine
01 11     STACK

03 00 JSR $20          ; Jump to subroutine
03 01 ADL $05
03 02 ADH $04
03 03                  ; Return from subroutine to this location

04 05 ·                ; Subroutine main body
04 06 ·
04 07 ·
04 08 RTS $60          ; Return from subroutine

; The Break Flag and The Stack
; Bits 4 and 5 will always be ignored, when transferred to the status register.
; Bit 1
PHP 0 0 1 1 0 0 1 1 = $33
PLP 0 0 - - 0 0 1 1 = $03
PLA 0 0 1 1 0 0 1 1 = $33

; Bit 2
LDA #$32      ; 00110010
PHA 0 0 1 1 0 0 1 0 = $32
PLP 0 0 - - 0 0 1 0 = $02

; Bit 3
LDA #$C0
PHA 1 1 0 0 0 0 0 0 = $C0
LDA #$08
PHA 0 0 0 0 1 0 0 0 = $08
LDA #$12
PHA 0 0 0 1 0 0 1 0 = $12

RTI

SR: 0 0 - - 0 0 1 0 = $02
PC: $C008

; Pinout (NMOS 6502)
Pin 1: Vss    ; Ground
Pin 2: RDY    ; Ready
Pin 3: OUT    ; Output
Pin 4: IRQ    ; Interrupt Request
Pin 5: N.C.   ; Not Connected)
Pin 6: NMI    ; Non-Maskable Interrupt
Pin 7: SYNC   ; Synchronize
Pin 8: Vcc    ; +5V
Pin 9: AB0    ; Address Bus Bit 0
Pin 10: AB1   ; Address Bus Bit 1
Pin 11: AB2   ; Address Bus Bit 2
Pin 12: AB3   ; Address Bus Bit 3
Pin 13: AB4   ; Address Bus Bit 4
Pin 14: AB5   ; Address Bus Bit 5
Pin 15: AB6   ; Address Bus Bit 6
Pin 16: AB7   ; Address Bus Bit 7
Pin 17: AB8   ; Address Bus Bit 8
Pin 18: AB9   ; Address Bus Bit 9
Pin 19: AB10  ; Address Bus Bit 10
Pin 20: AB11  ; Address Bus Bit 11
Pin 21: Vss   ; Ground
Pin 22: AB12  ; Address Bus Bit 12
Pin 23: AB13  ; Address Bus Bit 13
Pin 24: AB14  ; Address Bus Bit 14
Pin 25: AB15  ; Address Bus Bit 15
Pin 26: DB7   ; Data Bus Bit 7
Pin 27: DB6   ; Data Bus Bit 6
Pin 28: DB5   ; Data Bus Bit 5
Pin 29: DB4   ; Data Bus Bit 4
Pin 30: DB3   ; Data Bus Bit 3
Pin 31: DB2   ; Data Bus Bit 2
Pin 32: DB1   ; Data Bus Bit 1
Pin 33: DB0   ; Data Bus Bit 0
Pin 34: R/W   ; Read/Write
Pin 35: N.C.  ; Not Connected
Pin 36: N.C.  ; Not Connected
Pin 37: IN    ; Input
Pin 38: S.O.  ; Set Overflow
Pin 39: OUT   ; Output
Pin 40: RES   ; Reset

; Power-Up State
LDX #$00      ; Initialize X register to zero
LDY #$00      ; Initialize Y register to zero
LDA #$00      ; Initialize Accumulator to zero
LDI #$FD      ; Initialize Stack Pointer to $FD (in the stack page)
LDS #$00      ; Initialize Status Register to zero (except for the Interrupt Disable bit)

; Reset State
LDX #$00      ; Reinitialize X register to zero
LDY #$00      ; Reinitialize Y register to zero
LDA #$00      ; Reinitialize Accumulator to zero
LDS #$FD      ; Reinitialize Stack Pointer to $FD (in the stack page)

; Load Reset Vector
LDA $FFFC     ; Load low byte of reset vector
STA $FFFE     ; Store it in the lower byte of the Program Counter
LDA $FFFD     ; Load high byte of reset vector
STA $FFFF     ; Store it in the upper byte of the Program Counter

SEI           ; Disable interrupts

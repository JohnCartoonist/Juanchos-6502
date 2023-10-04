; Address Modes
OPC A	      ; Operand is AC (implied single byte instruction)
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
ADC #oper     ; Immediate Addressing
ADC oper      ; Zero-Page Addressing
ADC oper,X    ; Zero-Page Addressing (X)
ADC oper      ; Absolute Addressing
ADC oper,X    ; Absolute Addressing (X)
ADC oper,Y    ; Absolute Addressing (Y)
ADC (oper,X)  ; Indirect Addressing (X)
ADC (oper),Y  ; Indirect Addressing (Y)

; ASL - Shift Left One Bit (Memory or Accumulator)
ASL A         ; Accumulator
ASL oper      ; Zero-Page Addressing
ASL oper,X    ; Zero-Page Addressing (X)
ASL oper      ; Absolute Addressing
ASL oper,X    ; Absolute Addressing (X)

; BCC - Branch on Carry Clear
BCC oper      ; Relative Addressing

; BCS - Branch on Carry Set
BCS oper      ; Relative Addressing

; BEQ - Branch on Result Zero
BEQ oper      ; Relative Addressing

; BIT - Test Bits in Memory with Accumulator
BIT oper      ; Zero-Page Addressing
BIT oper      ; Absolute Addressing

; BMI - Branch on Result Minus
BMI oper      ; Relative Addressing

; BNE - Branch on Result not Zero
BNE oper      ; Relative Addressing

; BPL - Branch on Result Plus
BPL oper      ; Relative Addressing

; BRK - Force Break
BRK           ; Implied Addressing

; BVC - Branch on Overflow Clear
BVC oper      ; Relative Addressing

; BVS - Branch on Overflow Set
BVS oper      ; Relative Addressing

; CLC - Clear Carry Flag
CLC           ; Implied Addressing

; CLD - Clear Decimal Mode
CLD           ; Implied Addressing

; CLI - Clear Interrupt Disable Bit
CLI           ; Implied Addressing

; CLV - Clear Overflow Flag
CLV           ; Implied Addressing

; CMP - Compare Memory with Accumulator
CMP #oper     ; Immediate Addressing
CMP oper      ; Zero-Page Addressing
CMP oper,X    ; Zero-Page Addressing (X)
CMP oper      ; Absolute Addressing
CMP oper,X    ; Absolute Addressing (X)
CMP oper,Y    ; Absolute Addressing (Y)
CMP (oper,X)  ; Indirect Addressing (X)
CMP (oper),Y  ; Indirect Addressing (Y)

; CPX - Compare Memory and Index X
CPX #oper     ; Immediate Addressing
CPX oper      ; Zero-Page Addressing
CPX oper      ; Absolute Addressing

; CPY - Compare Memory and Index Y
CPY #oper     ; Immediate Addressing
CPY oper      ; Zero-Page Addressing
CPY oper      ; Absolute Addressing

; DEC - Decrement Memory by One
DEC oper      ; Zero-Page Addressing
DEC oper,X    ; Zero-Page Addressing (X)
DEC oper      ; Absolute Addressing
DEC oper,X    ; Absolute Addressing (X)

; DEX - Decrement Index X by One
DEX           ; Implied Addressing

; DEY - Decrement Index Y by One
DEY           ; Implied Addressing

; EOR - Exclusive-OR Memory with Accumulator
EOR #oper     ; Immediate Addressing
EOR oper      ; Zero-Page Addressing
EOR oper,X    ; Zero-Page Addressing (X)
EOR oper      ; Absolute Addressing
EOR oper,X    ; Absolute Addressing (X)
EOR oper,Y    ; Absolute Addressing (Y)
EOR (oper,X)  ; Indirect Addressing (X)
EOR (oper),Y  ; Indirect Addressing (Y)

; INC - Increment Memory by One
INC oper      ; Zero-Page Addressing
INC oper,X    ; Zero-Page Addressing (X)
INC oper      ; Absolute Addressing
INC oper,X    ; Absolute Addressing (X)

; INX - Increment Index X by One
INX           ; Implied Addressing

; INY - Increment Index Y by One
INY           ; Implied Addressing

; JMP - Jump to New Location
JMP oper      ; Absolute Addressing
JMP (oper)    ; Indirect Addressing

; JSR - Jump to New Location Saving Return Address
JSR oper      ; Absolute Addressing

; LDA - Load Accumulator with Memory
LDA #oper     ; Immediate Addressing
LDA oper      ; Zero-Page Addressing
LDA oper,X    ; Zero-Page Addressing (X)
LDA oper      ; Absolute Addressing
LDA oper,X    ; Absolute Addressing (X)
LDA oper,Y    ; Absolute Addressing (Y)
LDA (oper,X)  ; Indirect Addressing (X)
LDA (oper),Y  ; Indirect Addressing (Y)

; LDX - Load Index X with Memory
LDX #oper     ; Immediate Addressing
LDX oper      ; Zero-Page Addressing
LDX oper,Y    ; Zero-Page Addressing (Y)
LDX oper      ; Absolute Addressing
LDX oper,Y    ; Absolute Addressing (Y)

; LDY - Load Index Y with Memory
LDY #oper     ; Immediate Addressing
LDY oper      ; Zero-Page Addressing
LDY oper,X    ; Zero-Page Addressing (X)
LDY oper      ; Absolute Addressing
LDY oper,X    ; Absolute Addressing (X)

; LSR - Shift One Bit Right (Memory or Accumulator)
LSR A         ; Accumulator
LSR oper      ; Zero-Page Addressing
LSR oper,X    ; Zero-Page Addressing (X)
LSR oper      ; Absolute Addressing
LSR oper,X    ; Absolute Addressing (X)

; NOP - No Operation
NOP           ; Implied Addressing

; ORA - OR Memory with Accumulator
ORA #oper     ; Immediate Addressing
ORA oper      ; Zero-Page Addressing
ORA oper,X    ; Zero-Page Addressing (X)
ORA oper      ; Absolute Addressing
ORA oper,X    ; Absolute Addressing (X)
ORA oper,Y    ; Absolute Addressing (Y)
ORA (oper,X)  ; Indirect Addressing (X)
ORA (oper),Y  ; Indirect Addressing (Y)

; PHA - Push Accumulator on Stack
PHA           ; Implied Addressing

; PHP - Push Processor Status on Stack
PHP           ; Implied Addressing

; PLA - Pull Accumulator from Stack
PLA           ; Implied Addressing

; PLP - Pull Processor Status from Stack
PLP           ; Implied Addressing

; ROL - Rotate One Bit Left (Memory or Accumulator)
ROL A         ; Accumulator
ROL oper      ; Zero-Page Addressing
ROL oper,X    ; Zero-Page Addressing (X)
ROL oper      ; Absolute Addressing
ROL oper,X    ; Absolute Addressing (X)

; ROR - Rotate One Bit Right (Memory or Accumulator)
ROR A         ; Accumulator
ROR oper      ; Zero-Page Addressing
ROR oper,X    ; Zero-Page Addressing (X)
ROR oper      ; Absolute Addressing
ROR oper,X    ; Absolute Addressing (X)

; RTI - Return from Interrupt
RTI           ; Implied Addressing

; RTS - Return from Subroutine
RTS           ; Implied Addressing

; SBC - Subtract Memory from Accumulator with Borrow
SBC #oper     ; Immediate Addressing
SBC oper      ; Zero-Page Addressing
SBC oper,X    ; Zero-Page Addressing (X)
SBC oper      ; Absolute Addressing
SBC oper,X    ; Absolute Addressing (X)
SBC oper,Y    ; Absolute Addressing (Y)
SBC (oper,X)  ; Indirect Addressing (X)
SBC (oper),Y  ; Indirect Addressing (Y)

; SEC - Set Carry Flag
SEC           ; Implied Addressing

; SED - Set Decimal Flag
SED           ; Implied Addressing

; SEI - Set Interrupt Disable Status
SEI           ; Implied Addressing

; STA - Store Accumulator in Memory
STA oper      ; Zero-Page Addressing
STA oper,X    ; Zero-Page Addressing (X)
STA oper      ; Absolute Addressing
STA oper,X    ; Absolute Addressing (X)
STA oper,Y    ; Absolute Addressing (Y)
STA (oper,X)  ; Indirect Addressing (X)
STA (oper),Y  ; Indirect Addressing (Y)

; STX - Store Index X in Memory
STX oper      ; Zero-Page Addressing
STX oper,Y    ; Zero-Page Addressing (Y)
STX oper      ; Absolute Addressing

; STY - Sore Index Y in Memory
STY oper      ; Zero-Page Addressing
STY oper,X    ; Zero-Page Addressing (X)
STY oper      ; Absolute Addressing

; TAX - Transfer Accumulator to Index X
TAX           ; Implied Addressing

; TAY - Transfer Accumulator to Index Y
TAY           ; Implied Addressing

; TSX - Transfer Stack Pointer to Index X
TSX           ; Implied Addressing

; TXA - Transfer Index X to Accumulator
TXA           ; Implied Addressing

; TXS - Transfer Index X to Stack Register
TXS           ; Implied Addressing

; TYA - Transfer Index Y to Accumulator
TYA           ; Implied Addressing

; "Illegal" Opcodes And Undocumented Instructions
; These opcodes aren't as well documented and they may be unstable.
; ALR (ASR)
ALR #oper     ; Immediate Addressing

; ANC
ANC #oper     ; Immediate Addressing

; ANC (ANC2)
ANC #oper     ; Immediate Addressing

; ANE (XAA)
ANE #oper     ; Immediate Addressing

; ARR
ARR #oper     ; Immediate Addressing

; DCP (DCM)
DCP oper      ; Zero-Page Addressing
DCP oper,X    ; Zero-Page Addressing (X)
DCP oper      ; Absolute Addressing
DCP oper,X    ; Absolute Addressing (X)
DCP oper,Y    ; Absolute Addressing (Y)
DCP (oper,X)  ; Indirect Addressing (X)
DCP (oper),Y  ; Indirect Addressing (Y)

; ISC (ISB, INS)
ISC oper      ; Zero-Page Addressing
ISC oper,X    ; Zero-Page Addressing (X)
ISC oper      ; Absolute Addressing
ISC oper,X    ; Absolute Addressing (X)
ISC oper,Y    ; Absolute Addressing (Y)
ISC (oper,X)  ; Indirect Addressing (X)
ISC (oper),Y  ; Indirect Addressing (Y)

; LAS (LAR)
LAS oper,Y    ; Absolute Addressing (Y)

; LAX
LAX oper      ; Zero-Page Addressing
LAX oper,Y    ; Zero-Page Addressing (Y)
LAX oper      ; Absolute Addressing
LAX oper,Y    ; Absolute Addressing (Y)
LAX (oper,X)  ; Indirect Addressing (X)
LAX (oper),Y  ; Indirect Addressing (Y)

; LXA (LAX immediate)
LXA #oper     ; Immediate Addressing

; RLA
RLA oper      ; Zero-Page Addressing
RLA oper,X    ; Zero-Page Addressing (X)
RLA oper      ; Absolute Addressing
RLA oper,X    ; Absolute Addressing (X)
RLA oper,Y    ; Absolute Addressing (Y)
RLA (oper,X)  ; Indirect Addressing (X)
RLA (oper),Y  ; Indirect Addressing (Y)

; RRA
RRA oper      ; Zero-Page Addressing
RRA oper,X    ; Zero-Page Addressing (X)
RRA oper      ; Absolute Addressing
RRA oper,X    ; Absolute Addressing (X)
RRA oper,Y    ; Absolute Addressing (Y)
RRA (oper,X)  ; Indirect Addressing (X)
RRA (oper),Y  ; Indirect Addressing (Y)

; SAX (AXS, AAX)
SAX oper      ; Zero-Page Addressing
SAX oper,Y    ; Zero-Page Addressing (Y)
SAX oper      ; Absolute Addressing
SAX (oper,X)  ; Indirect Addressing (X)

; SBX (AXS, SAX)
SBX #oper     ; Immediate Addressing

; SHA (AHX, AXA)
SHA oper,Y    ; Absolute Addressing (Y)
SHA (oper),Y  ; Indirect Addressing (Y)

; SHX (A11, SXA, XAS)
SHX oper,Y    ; Absolute Addressing (Y)

; SHY (A11, SYA, SAY)
SHY oper,X    ; Absolute Addressing (X)

; SLO (ASO)
SLO oper      ; Zero-Page Addressing
SLO oper,X    ; Zero-Page Addressing (X)
SLO oper      ; Absolute Addressing
SLO oper,X    ; Absolute Addressing (X)
SLO oper,Y    ; Absolute Addressing (Y)
SLO (oper,X)  ; Indirect Addressing (X)
SLO (oper),Y  ; Indirect Addressing (Y)

; SRE (LSE)
SRE oper      ; Zero-Page Addressing
SRE oper,X    ; Zero-Page Addressing (X)
SRE oper      ; Absolute Addressing
SRE oper,X    ; Absolute Addressing (X)
SRE oper,Y    ; Absolute Addressing (Y)
SRE (oper,X)  ; Indirect Addressing (X)
SRE (oper),Y  ; Indirect Addressing (Y)

; TAS (XAS, SHS)
TAS oper,Y    ; Absolute Addressing (Y)

; USBC (SBC)
USBC #oper    ; Immediate Addressing

; NOPs (including DOP, TOP)
; The opcode representations are being used as a result of poor documentation.
$1A           ; Implied Addressing
$3A           ; Implied Addressing
$5A           ; Implied Addressing
$7A           ; Implied Addressing
$DA           ; Implied Addressing
$FA           ; Implied Addressing
$80           ; Immediate Addressing
$82           ; Immediate Addressing
$89           ; Immediate Addressing
$C2           ; Immediate Addressing
$E2           ; Immediate Addressing
$04           ; Zero-Page Addressing
$44           ; Zero-Page Addressing
$64           ; Zero-Page Addressing
$14           ; Zero-Page Addressing (X)
$34           ; Zero-Page Addressing (X)
$54           ; Zero-Page Addressing (X)
$74           ; Zero-Page Addressing (X)
$D4           ; Zero-Page Addressing (X)
$F4           ; Zero-Page Addressing (X)
$0C           ; Absolute Addressing
$1C           ; Absolute Addressing (X)
$3C           ; Absolute Addressing (X)
$5C           ; Absolute Addressing (X)
$7C           ; Absolute Addressing (X)
$DC           ; Absolute Addressing (X)
$FC           ; Absolute Addressing (X)

; JAM (KIL, HLT)
; The opcode representations are being used as a result of poor documentation.
; No descriptions are provided in the documentation being used for this.
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

; ROR  Rev. A (pre-June 1976)
ROR A         ; Accumulator
ROR oper      ; Zero-Page Addressing
ROR oper,X    ; Zero-Page Addressing (X)
ROR oper      ; Absolute Addressing
ROR oper,X    ; Absolute Addressing (X)

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
-516 = %1111.1101.1111.1100 = $FD $FC

; Flags With ADC And SBC
LDA #$40
ADC #$40

; Decimal Mode (BCD)
SED
CLC
LDA #$12
ADC #$44      ; Accumulator now holds $56

SED
CLC
LDA #$28
ADC #$14      ; Accumulator now holds $42

; Jump Vectors And Stack Operations
$FFFA-$FFFB   ; NMI (Non-Maskable Interrupt) vector
$FFFC-$FFFD   ; RES (Reset) vector
$FFFE-$FFFF   ; IRQ (Interrupt Request) vector

; The Break Flag And The Stack
; Bits 4 and 5 will always be ignored.
; Bit 1
PHP 0 0 1 1 0 0 1 1 = $33
PLP 0 0 - 0 0 0 1 1 = $03
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

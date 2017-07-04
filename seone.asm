BDOS: EQU 0x05

; BDOS calls
_CONOUT: EQU 0x02
_STROUT: EQU 0x09

	org 0x100
	LD A, (0x80)
	AND A
	JP Z, USAGE ; No parameters given. Print usage

	; Write AT+ first
	LD A, "A"
	CALL WRITECHAR
	LD A, "T"
	CALL WRITECHAR
	LD A, "+"
	CALL WRITECHAR

	; Write the given command
	LD HL, 0x82 ; Parameters start at 81h, first one is always a space
WRITELOOP:
	LD A, (HL)
	AND A ; 0 == no more input 
	JP Z, ENDWRITE
	CALL WRITECHAR
	INC HL
	JP WRITELOOP
	
ENDWRITE:
	LD A, 13
	CALL WRITECHAR
	
READLOOP:
	CALL SEREADLINE	
	JP C, TIMEOUT
	
	DEC HL			; Check last char in the buffer
	LD A, 255		; 255, no SE-ONE connected
	CP (HL)
	JP Z, PROGEND
	
	LD A,10			; <LF> is end of output
	CP (HL)
	JP Z, END_PRINT
	INC HL
	
	CALL ADD_STREND
	LD DE, CMDBUF
	CALL STR_PRINT

	JP READLOOP	; Read next line
	
TIMEOUT:
	CALL ADD_STREND
	LD DE, CMDBUF
	CALL STR_PRINT
	LD DE, TXT_TIMEOUT
	CALL STR_PRINT
	RET

END_PRINT:
	CALL ADD_STREND
	LD DE, CMDBUF
	CALL STR_PRINT
PROGEND:
	IN A, (0x20)
	RET

; Add extra output for printing with BDOS call
; IN	HL:	Points to next char in the string buffer
; OUT	-
; Changes	AF,HL
ADD_STREND
	LD A, 13
	LD (HL), A
	INC HL
	LD A, 10
	LD (HL), A
	INC HL
	LD A, '$'
	LD (HL), A
	INC HL
	RET

; Read a line of input from the SE-ONE
; IN	-
; OUT	CMDBUF is filled with the line
; Changes	HL:	Points to end of the string buffer
;			AF, BC
;			C when a timeout occurs
;			NC when no timeout occured
SEREADLINE:
	CCF
	LD HL, CMDBUF	; Move HL to start of buffer
.READZERO:
	IN A, (0x20)	; Read character from SE-ONE
	AND A			;
	JP Z, .READZERO ; Ingore 0	
.CHARLOOP:
	LD (HL), A		; Move to buffer
	INC HL
	CP 13
	RET Z
	CP 10
	RET Z
	CP 255
	RET Z			; 255 received. No SE-ONE connected
	LD B, 255
.READFROMSE:	
	IN A, (0x20)
	AND A
	JP NZ, .CHARLOOP
	DEC B
	JP Z, .TIMEOUT		; ; Read 255 zero's? Probably a timeout
	JP .READFROMSE	; Ignore the zero
.TIMEOUT:
	SCF
	RET
	
; Print string via BDOS
; IN	DE: String ending with $
; OUT	-
;
STR_PRINT:
	LD C, _STROUT
	CALL BDOS
	RET

WRITECHAR:
	OUT (0x20), A
	RET
	
USAGE:
	LD DE, TXT
	LD C, _STROUT
	CALL BDOS
	RET

TXT: db "SE-ONE command program 0.9.1", 13, 10
	 db "Usage: seone <command>", 13, 10, 13,10
	 db "Example: seone SEMODE=FM ", 13,10,"$"

TXT_TIMEOUT: DB 13,10,"Timeout while reading from SE-ONE",13,10,"$"
	
CMDBUF: DS VIRTUAL 256;

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
	OUT (0x20), A
	LD A, "T"
	OUT (0x20), A
	LD A, "+"
	OUT (0x20), A

	; Write the given command
	LD HL, 0x82 ; Parameter start at 81h, first one is always a space
WRITELOOP:
	LD A, (HL)
	AND A ; 0 == no more input 
	JP Z, READLOOP1
	OUT (0x20), A
	INC HL
	JP WRITELOOP

	; And read the output until 0 is returned
READLOOP1:
	IN A, (0x20)
	AND A
	JP Z, READLOOP1; Keep reading until something there is output

READLOOP2:	
	LD E,A		; Print the output character
	LD C, _CONOUT
	CALL BDOS
	
	IN A, (0x20); Read next character	
	AND A
	JP Z, PEND
	JP READLOOP2

PEND:
	RET
	
USAGE:
	LD DE, TXT
	LD C, _STROUT
	CALL BDOS

	RET

TXT: db "SE-ONE test program 0.5.", 13, 10
	 db "Usage: seone <command>", 13, 10, "$"

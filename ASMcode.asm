.model tiny
.data
portA1	equ 80h
portB1	equ 82h	
portC1	equ 84h
creg1	equ 86h
portA2	equ 88h
portB2	equ 8Ah 
portC2	equ 8Ch
creg2	equ 8Eh
mem 	db 	891	dup(0)
pos1 	db 	0Ch
pos2 	db 	0CCh
.code
.startup
			MOV AL,	80h			;Configuring control register of the first 8255
			OUT creg1,	al
			MOV AL,	91h			;Configuring control register of the second 8255
			OUT creg2,	al
			LEA SI,	mem			;Storing memory address in SI register
			MOV CX,	81			;No. of Rows
NEXTROW:	PUSH	CX
			MOV	DL,	0
			MOV	CX,	20
READAGAIN1: CALL	READPIX		;Reads data coming from the Photo-Diodes.
			MOV	AL,	06H
			OUT	portA1,	AL
			MOV	AL,	03H
			OUT	portA1,	AL
			MOV	AL,	09H
			OUT	portA1,	AL
			MOV	AL,	pos1
			OUT	portA1,	AL
			INC DL				;Go to next block.
			LOOP READAGAIN1
								;Only the last pixel is to be read. Reading the last pixel.
			MOV AL,	0EH         ;Enable ALE by resetting the PC6 output of 8255.
			OUT creg2,	AL
			MOV AL,	05H      	;Enable the last photodiode
			OUT portC1,	AL
			MOV AL,	0CH			;To create a start pulse, first making the Output PC7 = 0 of 8255.
			OUT creg2,	AL
			NOP					;Delay of 400 nanosecs
			NOP
			MOV AL,	0DH			;Making Output PC7 = 1 of 8255, i.e., to create a start pulse fully.
			OUT creg2,	AL
NOTOVER:	IN	AL,	portC2		;Check EOC by Polling Method.
			AND AL,	01H
			JNZ	NOTOVER
								;Analog to Digital conversion done by the ADC.
			MOV AL,	0AH
			OUT creg2,	AL 		;Making Output PC5 = 0 of 8255, to enable the output of ADC.
			IN 	AL,	portA2 		;AL contains ADC output now
			CMP AL,	00H
			JZ	SKIP
			MOV	AL,	80H
			OR	[SI+10],	AL	;Storing value of the last pixel in a separate byte.
SKIP:		MOV CX,	20
AGAIN2:		MOV AL,	09H			;Move motor1 back to start of the Row.
			OUT portA1,	AL
			MOV	AL,	03H
			OUT	portA1,	AL
			MOV	AL,	06H
			OUT	portA1,	AL
			MOV	AL,	pos1
			OUT	portA1,	AL
			LOOP	AGAIN2
			MOV AL,	pos2		;Move motor2 vertically by 0.125c.m.
			ROR AL,	1
			OUT	portB1,	AL
			MOV pos2,	AL
			ADD SI,	11			;To start storing values of next row
			POP CX
			DEC CX
			JNZ NEXTROW
.exit

READPIX     PROC	NEAR		;Takes SI and DL as arguments
			PUSH	CX
			MOV	BX,	0         	;BX holds the diode being selected currently through ADC.
			MOV	CX,	4			;Loop 4 times, one time for each photodiode.
NEXTBYTE:	MOV AL,	BL			;Select diode using BX
			OUT	portC1,	AL   
			MOV AL,	0EH         ;Enable ALE by resetting the PC6 output of 8255.
			OUT creg2,	AL
			MOV AL,	0CH			;To create a start pulse, first making the Output PC7 = 0 of 8255.
			OUT creg2,	AL
			NOP					;Delay of 400 nanosecs
			NOP
			MOV AL,	0DH			;Making Output PC7 = 1 of 8255, i.e., to create a start pulse fully.
			OUT creg2,	AL
GOBACK:		IN	AL,	portC2		;Check EOC by Polling Method.
			AND AL,	01H
			JNZ	GOBACK
								;Analog to Digital conversion done by the ADC.
			MOV AL,	0AH
			OUT creg2,	AL 		;Making Output PC5 = 0 of 8255, to enable the output of ADC.
			IN 	AL,	portA2 		;DH contains ADC output now
			CMP AL,	00H			;Check if PhotoDiode has received any light or not.
			JZ 	FORWARD
			MOV DH,	80H
			MOV	AL,	DL
			CBW
			MOV	DI,	02H
			DIV	DI
			PUSH	CX
			CMP	AH,	00H
			JNE	X1
			MOV	CL,	BL
			SHR DH,	CL
			JMP	X2
X1:			MOV	CL,	BL
			ADD	CL,	4
			SHR	DH,	CL
X2:			POP CX
			MOV	AH,	0
			PUSH	BX
			MOV	BX,	AX
			OR	[BX+SI],	DH	;Stores in memory
			POP	BX
FORWARD:    INC	BX
			LOOP	NEXTBYTE
			POP CX
RET
READPIX     ENDP

;procedure to delay
DELAY		PROC	NEAR 
			PUSH	CX
			MOV CX,	15
X:			DEC	CX
			JNZ	X
			POP	CX
RET
DELAY		ENDP

end

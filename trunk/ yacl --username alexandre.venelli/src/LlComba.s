/*
LlComba.s - Comba multiplication algorithms

Copyright 2010 Alexandre VENELLI

This file is part of the YACL.

The YACL is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

The YACL is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License
along with the YACL.  If not, see http://www.gnu.org/licenses/.
*/
#include <avr/io.h>
#include "Llglobvars.h"

    .global LlComba_Mult_C
	.global	LlComba_Mult_ASM
    .global LlComba_Mult_Low_ASM
    .global LlComba_Mult_High_ASM
    .global LlComba_Mult_One_Byte_C
	.global LlComba_Mult_One_Byte_ASM
    .global LlComba_Square_C
	.global LlComba_Square_ASM


  
;
; LlComba_Mult_One_Byte_C
; LlComba_Mult_One_Byte_ASM
;
; R = X * OneByte
; 
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       u2OneByte : Value of the byte
;         in R20-R21
;       u2XLength : Length in bytes of X
;         in R18-R19
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			532
;	0x30			988
;
LlComba_Mult_One_Byte_C:

    ; Save non-scratch registers
	push	r2
	push	r3
    push    r4
    push    r5
    push    r6
    push    r7
	push	r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2


	rcall	LlComba_Mult_One_Byte

	; Convention (r1=0)
	clr		r1
    
    ; Registers restoration
	pop		r17
	pop		r16
    pop     r7
    pop     r6
    pop     r5
    pop     r4
	pop		r3
	pop		r2

	ret

LlComba_Mult_One_Byte_ASM:
	push	r2
	push	r3
    push    r4
    push    r5
    push    r6
    push    r7
	
	rcall	LlComba_Mult_One_Byte

	pop     r7
    pop     r6
    pop     r5
    pop     r4
	pop		r3
	pop		r2

	ret

LlComba_Mult_One_Byte:    
    ; r6 = Zero register
    clr     r6
    
    ; PtrZ = Adr X 
    movw    r30,r18 
    
    ; PtrX = Adr R
    movw    r26,r16
    
    clr     r7
    
    ; COMBA_CLEAR
    clr     r3
    clr     r4
    clr     r5
    
Begin_Loop_Up_One_Byte:    
    
    cp      r7,r22
    breq    End_Loop_Up_One_Byte
    
    mov     r0,r20 ; load the Byte
    ld      r1,z+
    mul     r0,r1
    add     r3,r0
    adc     r4,r1
    adc     r5,r6  
    
    ; COMBA_STORE 
    st      x+,r3
    
    ; COMBA_FORWARD
    mov     r3,r4
    mov     r4,r5
    clr     r5
    
    inc     r7
       
    jmp     Begin_Loop_Up_One_Byte
    
End_Loop_Up_One_Byte:
    
    ; COMBA_STORE_FIN
    st      x+,r3
    
    ret



;
; LlComba_Mult_Low_ASM
;
; (used in Barrett reduction)
;
; Computes the u2NbBytes LSB bytes of the multiplication X*Y
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2XLength : Length in bytes of X
;         in R18-R19
;       u2NbBytes : Number of bytes needed in the result
;         in R16-R17
;
;   !!! u2XLength = u2YLength !!! (pad with zeros if necessary)
;
;   !!! 0 < u2NbBytes < 2*u2XLength !!!
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			3930
;
LlComba_Mult_Low_ASM:
    ldd     r0,y+1
    ldd     r1,y+2
	
	push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	push 	r16
	push 	r17

	movw     r10,r0 ; r10 = u2NbBytes

    ; r5 = Zero register
    clr     r5
    
    ; Adr Y in r24-r25
    movw    r24,r20
    
    clr     r20
    
    ; COMBA_CLEAR
    clr     r6
    clr     r7
    clr     r8
    
    adiw    r24,0x01
    
    
    ldi     r26,0x00
    out     _SFR_IO_ADDR(EIND),r26
    
    
    ; NbBytes >? XLength
    cp      r22,r10
    brsh    NbBytesLowerXLength
    
    sub     r10,r22
    mov     r4,r22
    dec     r4
    sub     r4,r10
    
    jmp     Begin_Loop_Up_Low

NbBytesLowerXLength:
    ; Only part of the first loop on XLength
    mov     r22,r10 ; XLength = NbBytes
    mov     r4,r22
    dec     r4
    

Begin_Loop_Up_Low:    
    
    cp      r20,r22
    breq    End_Loop_Up_Low
    
    ; PtrX = first parameter
    movw    r26,r18
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
    
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    inc     r20
    
    ; move the pointer of the 2nd parameter
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Low
    

End_Loop_Up_Low:

	; 2nd parameter pointer moved one step too many
    sbiw    r24,0x01
    
    ; loop counter = size of Y minus 1
    mov     r20,r22
    
    ; size of Y minus 1
    dec     r20
    
    
    
    
Begin_Loop_Down_Low:
    cp      r20,r4
    breq    End_Loop_Down_Low

    ; PtrX = first parameter
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    dec     r20
    
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
      
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    dec     r20
    
    
    jmp     Begin_Loop_Down_Low

End_Loop_Down_Low:  
    
	pop 	r17
	pop 	r16
	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

    ret


;
; LlComba_Mult_High_ASM
;
; (used in Barrett reduction)
;
; Computes the u2NbBytes MSB bytes of the multiplication X*Y
; Pre-computes 2 more column than the u2NbBytes asked for a more accurate result
;
; !!! pu1R needs u2XLength+2 bytes !!!
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2XLength : Length in bytes of X
;         in R18-R19
;       u2NbBytes : Number of bytes needed in the result
;         in R16-R17
;
;   !!! u2XLength = u2YLength !!! (pad with zeros if necessary)
;
;       1 <= u2NbBytes <= 2*u2XLength - 2
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			4518
;
LlComba_Mult_High_ASM:  
	ldd     r0,y+1
    ldd     r1,y+2

	push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	push 	r16
	push 	r17
	
	movw    r14,r0 ; r14 = u2NbBytes
	  
    ; r5 = Zero register
    clr     r5
    
    ; pu1X in r10-11
    movw    r10,r18
    
    ; Save pu1R in r12-r13
    movw    r12,r16
    
    ; pu1Y in r24-r25
    movw    r24,r20
    adiw    r24,0x01
    
    ; COMBA_CLEAR
    clr     r6
    clr     r7
    clr     r8
    
    ; Init for the JumpTable
    ldi     r26,0x00
    out     _SFR_IO_ADDR(EIND),r26
    
    
    clr     r4
    
    inc     r14
    inc     r14
    
    mov     r20,r22
    lsl     r20      ; r20 = 2*u2XLength
    sub     r20,r14  ; r20 = 2*u2XLength - u2NbBytes
    
    add     r24,r20
    adc     r25,r5 ; pu1Y + r20
    

    
Begin_Loop_Up_Digs_High:    
    
    cp      r20,r22
    brsh    End_Loop_Up_Digs_High
    
    ; PtrX = First parameter
    movw    r26,r18
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
    
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    inc     r20
    
    ; move the pointer of the 2nd parameter
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Digs_High
    

End_Loop_Up_Digs_High:

    ; 2nd parameter pointer moved one step too many
    sbiw    r24,0x01
    
    ; loop counter = size of Y minus 1
    mov     r20,r22
    
    ; size of Y minus 1
    dec     r20



Begin_Loop_Down_Digs_High:
    cp      r20,r4
    breq    End_Loop_Down_Digs_High

    ; PtrX = First parameter
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26

    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    dec     r20
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
      
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    dec     r20
    
    
    jmp     Begin_Loop_Down_Digs_High

End_Loop_Down_Digs_High: 
    
    ; COMBA_STORE_FIN
    movw    r26,r16
    st      x+,r6
    
    
    ; right shift of 2 bytes the result
    ; to get rid of the 2 precomputed columns
    movw    r30,r12
    
    movw    r26,r12
    adiw    r26,0x02
    
    ldi     r20,0x02
    
Begin_Loop_RS:
    cp      r20,r14
    breq    End_Loop_RS
    
    ld      r1,x+
    st      z+,r1
    
    inc     r20
    jmp     Begin_Loop_RS
End_Loop_RS:
    
	pop 	r17
	pop 	r16
	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

    ret


; LlComba_Square_C
; LlComba_Square_ASM
;
; R = X^2
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       u2XLength : Length in bytes of X
;         in R20-R21
; Perf:
; u2XLength			Nb. cycles
;	0x18			5379
;	0x30			15927
;
LlComba_Square_C:
	
	; Save non-scratch registers
	push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	push 	r16
	push 	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r18,r22
	
	rcall	LlComba_Square

	; Convention (r1=0)
	clr		r1
    
    ; Registers restoration
	pop 	r17
	pop 	r16
	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

	ret

LlComba_Square_ASM:
	push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	
	rcall	 LlComba_Square

	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

	ret

LlComba_Square:

    ; r5 = Zero register
    clr     r5
    
    ; pu1X in r24-r25
    movw    r24,r18
    adiw    r24,0x01
    
    
    clr     r22
    
    ; COMBA_CLEAR
    clr     r9
    clr     r10
    clr     r11
    
    clr     r12
    inc     r12
    
    
    ldi     r26,0x00
    out     _SFR_IO_ADDR(EIND),r26
    
    
    ;------------
    ; First round
    ;------------
    
    ; PtrX = First parameter
    movw    r26,r18
    
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r23,r22
    lsr     r23
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    

    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    clr     r6
    clr     r7
    clr     r8
    
    eicall

    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r9,r7
    mov     r10,r8
    clr     r11
    
    inc     r22
    
    ; move the pointer of the 2nd parameter
    adiw    r24,0x01
    
    
    ;---------------------
    ; Begin ascending loop
    ;---------------------
    
Begin_Loop_Up_Sqr:    
    
    cp      r22,r20
    breq    End_Loop_Up_Sqr
    
    ; PtrX = First parameter
    movw    r26,r18
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r23,r22
    dec     r23
	; divide by 2 because in the square we have 2 times less iterations to do
    lsr     r23 
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    

    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
	; internal accumulation registers of the eicall
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    ; x2 the accumulation
    add     r6,r6
    adc     r7,r7
    adc     r8,r8
    
    ; add the carry of previous round
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

	; test if we are in a column of even index or odd index,
	; if even, we have a diagonal element to compute
	; otherwise, no
    ; diagonal element, examples: X0*X0, X1*X1, ...
    mov     r13,r22
    and     r13,r12
    tst     r13
    brne    Test_Odd

    ; even
    
    ; r13=index of the diagonal byte = counter/2
    mov     r13,r22
    lsr     r13
    
    movw    r30,r18
    add     r30,r13
    adc     r31,r5
    ld      r0,z
    ld      r1,z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
    

Test_Odd:

    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r9,r7
    mov     r10,r8
    clr     r11
    
    inc     r22
    
    ; move the pointer of the 2nd parameter
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Sqr
    

End_Loop_Up_Sqr:

    
    ; 2nd parameter pointer moved one step too many
    sbiw    r24,0x01
    
    
    ; loop counter = size of Y minus 2
    mov     r22,r20
    
    ; size of Y minus 2 (because the last round is apart)
    dec     r22
    dec     r22
    
    ;----------------------
    ; Begin decreasing loop
    ;----------------------
    
Begin_Loop_Down_Sqr:
    tst     r22
    breq    End_Loop_Down_Sqr

    ; PtrX = First parameter
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r23,r22
    dec     r23
    ; divide by 2 because in the square we have 2 times less iterations to do
    lsr     r23 
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    
    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    ; internal accumulation registers of the eicall
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    
    ; x2 the accumulation
    add     r6,r6
    adc     r7,r7
    adc     r8,r8
    
    ; add the carry of previous round
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

    
    ; test if we are in a column of even index or odd index,
	; if even, we have a diagonal element to compute
	; otherwise, no
    ; diagonal element, examples: X0*X0, X1*X1, ...
    mov     r13,r22
    and     r13,r12
    tst     r13
    brne    Test_Odd2

    ; even
    
    ; r13=index of the diagonal byte = counter/2
    mov     r13,r22
    lsr     r13
    movw    r30,r24
    sub     r30,r13
    sbc     r31,r5
    ld      r0,-z
    ld      r1,z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
    

Test_Odd2:
      
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r9,r7
    mov     r10,r8
    clr     r11
    
    dec     r22
    
    jmp     Begin_Loop_Down_Sqr

End_Loop_Down_Sqr: 


    ;-----------------
    ; Last round apart
    ;-----------------


    ; PtrX = First parameter
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))   
    
    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    clr     r0
    add     r30,r0
    adc     r31,r5
    
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    ; add carry
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

    ; COMBA_STORE_FIN
    movw    r26,r16
    st      x+,r6
    st      x+,r7
    
    ret


    
; LlComba_Mult_C
; LlComba_Mult_ASM
;
; Comba multiplication of Z=X*Y
;
; WARNING : 560*560 bits = 0x46*0x46 byte
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2XLength : Length in bytes of X
;         in R18-R19
;
;   !!! u2XLength = u2YLength !!! (pad with zeros if necessary)
;
; Length:
;       u2XLength * u2YLength -> 2*u2XLength
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			7064
;	0x30			24416
;
LlComba_Mult_C:

    ; Save non-scratch registers
    push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	push 	r16
	push 	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2
	
	rcall	LlComba_Mult

	; Convention (r1=0)
	clr		r1
    
    ; Registers restoration
	pop 	r17
	pop 	r16
	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

	ret

LlComba_Mult_ASM:
	push	r2
	push	r3
	push	r4
	push 	r5
	push 	r6
	push 	r7
	push 	r8
	push 	r9
	push 	r10
	push 	r11
	push 	r12
	push 	r13
	push 	r14
	push 	r15
	
	rcall	 LlComba_Mult

	pop 	r15
	pop 	r14
	pop 	r13
	pop 	r12
	pop 	r11
	pop 	r10
	pop 	r9
	pop 	r8
	pop 	r7
	pop 	r6
	pop 	r5
	pop 	r4
	pop 	r3
	pop 	r2

	ret

LlComba_Mult:   
    ; r5 = Zero register
    clr     r5
    
    ; pu1Y in r24-r25
    movw    r24,r20
    adiw    r24,0x01
    
    
    clr     r20
    
    ; COMBA_CLEAR
    clr     r6
    clr     r7
    clr     r8
    
    
    ldi     r26,0x00
    out     _SFR_IO_ADDR(EIND),r26
    
Begin_Loop_Up:    
    
    cp      r20,r22
    breq    End_Loop_Up
    
    ; PtrX = First parameter
    movw    r26,r18
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba)) 
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
    
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    inc     r20
    
    ; move the pointer of the 2nd parameter
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up
    

End_Loop_Up:
    ; 2nd parameter pointer moved one step too many
    sbiw    r24,0x01
    
    ; loop counter = size of Y minus 1
    mov     r20,r22
    
    ; size of Y minus 1
    dec     r20
     
Begin_Loop_Down:
    tst     r20
    breq    End_Loop_Down

    ; PtrX = First parameter
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; PtrZ = Adr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba)) 
    
    ; r0 = 3*r24 = 3*loop counter
    ; 3 = size of ((movw+jmp) / 2) in JmpTableComba
    dec     r20
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; PtrZ = PtrZ+r0 = Adr(JmpTable)+3*loop counter
    add     r30,r0
    adc     r31,r5
    
    eicall
      
    ; COMBA_STORE
    movw    r26,r16
    st      x+,r6
    movw    r16,r26   
    
    ; COMBA_FORWARD
    mov     r6,r7
    mov     r7,r8
    clr     r8
    
    dec     r20
        
    jmp     Begin_Loop_Down

End_Loop_Down:    
    
    ; COMBA_STORE_FIN
    movw    r26,r16
    st      x+,r6
    
    ret



;--------------------
; JmpTableComba BEGIN
;--------------------

JmpTableComba:
    movw    r30,r24
    jmp     MultAdd_1
    movw    r30,r24
    jmp     MultAdd_2
    movw    r30,r24
    jmp     MultAdd_3
    movw    r30,r24
    jmp     MultAdd_4
    movw    r30,r24
    jmp     MultAdd_5
    movw    r30,r24
    jmp     MultAdd_6
    movw    r30,r24
    jmp     MultAdd_7
    movw    r30,r24
    jmp     MultAdd_8
    movw    r30,r24
    jmp     MultAdd_9
    movw    r30,r24
    jmp     MultAdd_10
    movw    r30,r24
    jmp     MultAdd_11
    movw    r30,r24
    jmp     MultAdd_12
    movw    r30,r24
    jmp     MultAdd_13
    movw    r30,r24
    jmp     MultAdd_14
    movw    r30,r24
    jmp     MultAdd_15
    movw    r30,r24
    jmp     MultAdd_16
    movw    r30,r24
    jmp     MultAdd_17
    movw    r30,r24
    jmp     MultAdd_18
    movw    r30,r24
    jmp     MultAdd_19
    movw    r30,r24
    jmp     MultAdd_20
    movw    r30,r24
    jmp     MultAdd_21
    movw    r30,r24
    jmp     MultAdd_22
    movw    r30,r24
    jmp     MultAdd_23
    movw    r30,r24
    jmp     MultAdd_24
    movw    r30,r24
    jmp     MultAdd_25
    movw    r30,r24
    jmp     MultAdd_26
    movw    r30,r24
    jmp     MultAdd_27
    movw    r30,r24
    jmp     MultAdd_28
    movw    r30,r24
    jmp     MultAdd_29
    movw    r30,r24
    jmp     MultAdd_30
    movw    r30,r24
    jmp     MultAdd_31
    movw    r30,r24
    jmp     MultAdd_32
    movw    r30,r24
    jmp     MultAdd_33
    movw    r30,r24
    jmp     MultAdd_34
    movw    r30,r24
    jmp     MultAdd_35
    movw    r30,r24
    jmp     MultAdd_36
    movw    r30,r24
    jmp     MultAdd_37
    movw    r30,r24
    jmp     MultAdd_38
    movw    r30,r24
    jmp     MultAdd_39
    movw    r30,r24
    jmp     MultAdd_40
    movw    r30,r24
    jmp     MultAdd_41
    movw    r30,r24
    jmp     MultAdd_42
    movw    r30,r24
    jmp     MultAdd_43
    movw    r30,r24
    jmp     MultAdd_44
    movw    r30,r24
    jmp     MultAdd_45
    movw    r30,r24
    jmp     MultAdd_46
    movw    r30,r24
    jmp     MultAdd_47
    movw    r30,r24
    jmp     MultAdd_48
    movw    r30,r24
    jmp     MultAdd_49
    movw    r30,r24
    jmp     MultAdd_50
    movw    r30,r24
    jmp     MultAdd_51
    movw    r30,r24
    jmp     MultAdd_52
    movw    r30,r24
    jmp     MultAdd_53
    movw    r30,r24
    jmp     MultAdd_54
    movw    r30,r24
    jmp     MultAdd_55
    movw    r30,r24
    jmp     MultAdd_56
    movw    r30,r24
    jmp     MultAdd_57
    movw    r30,r24
    jmp     MultAdd_58
    movw    r30,r24
    jmp     MultAdd_59
    movw    r30,r24
    jmp     MultAdd_60
    movw    r30,r24
    jmp     MultAdd_61
    movw    r30,r24
    jmp     MultAdd_62
    movw    r30,r24
    jmp     MultAdd_63
    movw    r30,r24
    jmp     MultAdd_64
    movw    r30,r24
    jmp     MultAdd_65
    movw    r30,r24
    jmp     MultAdd_66
    movw    r30,r24
    jmp     MultAdd_67
    movw    r30,r24
    jmp     MultAdd_68
    movw    r30,r24
    jmp     MultAdd_69
    movw    r30,r24
    jmp     MultAdd_70
    

MultAdd_70:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_69:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_68:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_67:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_66:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_65:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_64:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_63:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_62:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_61:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_60:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_59:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_58:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_57:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_56:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_55:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_54:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_53:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_52:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_51:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_50:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_49:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_48:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_47:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_46:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_45:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_44:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_43:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_42:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_41:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_40:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_39:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_38:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_37:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_36:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_35:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_34:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_33:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_32:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_31:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_30:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_29:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_28:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_27:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_26:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_25:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_24:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_23:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_22:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_21:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_20:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_19:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_18:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_17:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_16:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_15:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_14:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_13:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_12:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_11:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5  
MultAdd_10:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5    
MultAdd_9:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_8:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_7:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_6:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_5:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_4:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_3:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_2:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
MultAdd_1:
    ld      r0,x+
    ld      r1,-z
    mul     r0,r1
    add     r6,r0
    adc     r7,r1
    adc     r8,r5
    
    ret

;------------------
; JmpTableComba END
;------------------

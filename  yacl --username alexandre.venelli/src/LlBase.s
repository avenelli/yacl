/*
LlBase.s - Basic functions

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
#include "Llglobvars.h"

	.global LlBase_Copy_Pad_C
	.global LlBase_Copy_Pad_ASM
    .global LlBase_SetByte_C
	.global LlBase_SetByte_ASM


; LlBase_SetByte_C
; LlBase_SetByte_ASM
;
; R = byte (+ padding zero)
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       u2ValByte : Value of the byte
;         in R22-R23
;       u2RLength : Length (needed) in bytes of R 
;         in R20-R21
;
LlBase_SetByte_C:
	; Save non-scratch registers
	push	r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r18,r22

	rcall 	LlBase_SetByte

	; Registers restoration
	pop		r17
	pop		r16

	ret

LlBase_SetByte_ASM:
LlBase_SetByte:
    clr     r0 ; cpt
    clr     r1
    movw    r30,r16 ; PtrZ = pu1R
    st      z+,r18 ; store u2ValByte
    inc     r0
Begin_Loop_SetByte:
    cp      r0,r20
    breq    End_Loop_SetByte
    
    st      z+,r1 ; store zero
    
    inc     r0
    jmp     Begin_Loop_SetByte
End_Loop_SetByte:
    ret

; LlBase_Copy_Pad_C
; LlBase_Copy_Pad_ASM
;
; R = X + Padding 0
;
; u2LengthR >= u2LengthX
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       u2XLength : Length in bytes of X
;         in R20-R21
;       u2RLength : Length (needed) in bytes of R 
;         in R18-R19
;
LlBase_Copy_Pad_C:
	; Save non-scratch registers
    push	r2
	push	r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	rcall	LlBase_Copy_Pad

	; Convention (r1=0)
	clr		r1

    ; Registers restoration
	pop		r2
	pop		r16
	pop		r17
	ret

LlBase_Copy_Pad_ASM:
	push	r2
	
	rcall	LlBase_Copy_Pad

	pop		r2
	ret

LlBase_Copy_Pad:
    movw    r26,r18 ; PtrX = pu1X
    movw    r30,r16 ; PtrZ = pu1R
    clr     r1
    clr     r2
    
Begin_Loop_Copy_XLength:
    cp      r1,r20
    breq    End_Loop_Copy_XLength
    
    ld      r0,x+
    st      z+,r0
    
    inc     r1
    jmp     Begin_Loop_Copy_XLength
    
End_Loop_Copy_XLength:  
    
Begin_Loop_Copy_Pad: 
    cp      r1,r22
    breq    End_Loop_Copy_Pad
    
    st      z+,r2
    
    inc     r1
    jmp     Begin_Loop_Copy_Pad
    
End_Loop_Copy_Pad:  
    ret

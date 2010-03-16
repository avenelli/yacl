/*
LlBarrett.s - Barrett modular reduction

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

	.global LlBarrett_Reduce_C
	.global	LlBarrett_Reduce_ASM
    
    .extern LlZpBase_Sub_ASM
    .extern LlZpBase_Add_ASM
    .extern LlComba_Mult_Low_ASM
    .extern LlComba_Mult_High_ASM


#define LlCnsh      4
#define LlCnsl      3
#define NbBytes_h   2
#define NbBytes_l   1

; LlBarrett_Reduce_C
;
; R = X mod ModBase
;
; Algorithm 14.42 HAC - Barrett modular reduction
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of X
;         in R22-R23
;       pu1ModBase  : Adress of the modulo
;         in R20-R21
;       pu1Cns : Adress of the constant
;         in R18-R19
;       pu1Quotient : Adress of the quotient / workspace
;         in R16-R17
;       u2ModLength : Length of the modulo in bytes
;         in R14-R15
;
; Cns = Floor((2^8)^{2*ModLength} / ModBase)
;
; ModLength = M
; CnsLength = M+1
; XLength   = 2M
; QLength   = M+3
; RLength   = M+1
;
; Perf:
; u2LengthX			Nb. cycles
;	0x18			11024
;
LlBarrett_Reduce_C:
	; Save non-scratch registers
    ;----------------
    push	r2
	push	r3
	push	r28
	push	r29


	; IAR-style arguments
	push	r15
	push	r14
	push	r17
	push	r16
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	in 		r28,__SP_L__
    in 		r29,__SP_H__
	rcall	LlBarrett_Reduce_Main

	; Convention (r1=0)
	clr		r1

	pop		r16
	pop		r17
	pop		r14
	pop		r15

    ; Registers restoration
    ;---------------------------
	pop		r29
	pop		r28
	pop 	r3
	pop 	r2

	ret

LlBarrett_Reduce_ASM:
	push	r28
	push	r29

	;in 		r28,__SP_L__
    ;in 		r29,__SP_H__
	rcall	LlBarrett_Reduce_Main

	pop		r29
	pop		r28

	ret

LlBarrett_Reduce_Main:
	ldd      r0,y+1
    ldd      r1,y+2
    ldd      r30,y+3
    ldd      r31,y+4

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
	
	; Allocate on the stack
	in 		r28,__SP_L__
    in 		r29,__SP_H__
	sbiw    r28,4
	in		r4,__SREG__
	cli
	out		__SP_H__,r29
	out		__SREG__,r4
	out		__SP_L__,r28

	mov     r5,r30 ; r5 = ModLength
    inc     r30
    std     y+NbBytes_l,r30
    std     y+NbBytes_h,r31 ; NbBytes=M+1 in stack (for partial mult)
    std     y+LlCnsl,r22
    std     y+LlCnsh,r23 ; Adr(Cns) in stack
    movw    r12,r0 ; r12 = Adr(Quotient)
    
    
    ; r3 = zero constant
    clr     r3
    
    // STEP 1 : Copy and Right Shift of (M-1) the input into Quotient
    
    ; copy the (M-1) MSB of X into R (Quotient)
    movw    r30,r16 ; Z = R (Quotient)    
        
    ; r0 = counter
    clr     r0
    add     r0,r5 
    dec     r0 ; r0 = ModLength - 1
    movw    r26,r18 ; X
    add     r26,r0 ; X + (ModLength-1) 
    adc     r27,r3

    mov     r6,r5
    lsl     r6
    
    inc     r5 ; r5 = ModLength + 1

    
    ; copy X + RightShift into R (Quotient)   
Begin_Loop_Copy_RS:
    cp      r0,r6
    breq    End_Loop_Copy_RS
    
    ld      r1,x+
    st      z+,r1
    
    inc     r0
    jmp     Begin_Loop_Copy_RS
End_Loop_Copy_RS:


    // STEP 2 : Produce the quotient
    ; Save params
    movw    r6,r16  ; Save Adr(R) in r6-r7
    movw    r8,r18  ; Save Adr(X) in r8-r9
    movw    r10,r20 ; Save Adr(ModBase) in r10-r11  
    
    
    ; Q = R * Cns 
    ; Only compute the M+1 MSB bytes of the result
    movw    r18,r16       ; R in r18-19
    ldd     r20,y+LlCnsl
    ldd     r21,y+LlCnsh  ; Adr(Cns) in r20-r21 = second param of Comba   
    mov     r22,r5  ; Length of Quotient in r22 = ModLength + 1 
    movw    r16,r12 ; Result in Q
    ; NbBytes already in stack Y+1-Y
    call    LlComba_Mult_High_ASM
    
    
        
    // STEP 3 : Subtract the multiple of the modulus from the input

	; Add 0x00 after the MSB of ModBase
    ; so that ModLength has the same value if we
	; consider M+1 bytes instead of M bytes.
    movw    r30,r10
    add     r30,r5
    adc     r31,r3
    sbiw    r30,0x01
    st      z,r3    
    
	; R = Q*ModBase
    ; Only computes the M+1 LSB of the result
    movw    r16,r6 ; Adr(R)
    movw    r18,r12 ; Adr(Quotient) in r18-19
    movw    r20,r10  ; Adr(ModBase) in r20-r21
    mov     r22,r5  ; Length of Quotient in r22 = ModLength + 1 
    ; NbBytes already in stack Y+1-Y
    call    LlComba_Mult_Low_ASM
    
    
    ; X = X mod Beta^{M+1}
    mov     r0,r5
    
    mov     r4,r5
    dec     r4      ; r4 = M
    lsl     r4      ; r4 = 2M
    
    movw    r30,r8  ; Z = Adr(X)
    add     r30,r4  ; Z + 2M
    adc     r31,r3
    
    
Begin_Loop_Mod:
    cp      r0,r4
    breq    End_Loop_Mod
    
    st      -z,r3
    
    inc     r0
    jmp     Begin_Loop_Mod
End_Loop_Mod: 

    
    ; Q = X - R
    movw    r16,r12 ; Adr(Quotient) in r16-r17
    movw    r18,r8
    movw    r20,r6
    mov     r22,r5
    call    LlZpBase_Sub_ASM
    
	; Algorithm 14.42 HAC step 3 not necessary
	; because the subtraction computes the absolute value
	       
    ser     r24
	mov		r2,r24

    // STEP 4 : Now subtract the modulus if the residue is too large (e.g. quotient too small)
Begin_Loop_Subtract:    
    ; R = X - ModBase
    movw    r16,r8 ; R (=X)
    movw    r18,r12 ; X (=Q)
    movw    r20,r10 ; ModBase
    mov     r22,r5
    call    LlZpBase_Sub_ASM
    
    
    cp      r16,r2 ; loop while r16 != 0xff 
    breq    End_Loop_Subtract
    
    ; swap params R <-> X
    movw    r30,r8
    movw    r8,r12
    movw    r12,r30
    
    jmp     Begin_Loop_Subtract
    
End_Loop_Subtract:

    ; last Add : R = X + ModBase
    movw    r16,r6
    movw    r18,r8
    movw    r20,r10
    mov     r22,r5
    call    LlZpBase_Add_ASM

	
	movw	r30,r6
	add		r30,r5
	adc		r31,r3
	st		z,r3

	; De-Allocate on the stack
	adiw	r28,4
	in	__tmp_reg__,__SREG__
	cli
	out	__SP_H__,r29
	out	__SREG__,__tmp_reg__
	out	__SP_L__,r28

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


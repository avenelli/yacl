/*
LlZpEccBase.s - Elliptic curve addition and doubling on general curves over Zp 
				considering projective Jacobian coordinates.

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
    .global LlZpEccAdd_C
    .global LlZpEccDbl_C
    
    .extern LlComba_Mult_ASM
	.extern LlComba_Square_ASM
    .extern LlBarrett_Reduce_ASM
    .extern LlZpBase_Add_ASM
    .extern LlZpBase_Mul_2d_ASM
    .extern LlZpBase_Sub_ASM
    .extern LlComba_Mult_One_Byte_ASM
    .extern LlBase_Copy_Pad_ASM
    

#define  EccAddAddrC3h                    24           // Address of C3
#define  EccAddAddrC3l                    23
#define  EccAddAddrZ2h                    22           // Address of Z2
#define  EccAddAddrZ2l                    21
#define  EccAddAddrY2h                    20           // Address of X2
#define  EccAddAddrY2l                    19
#define  EccAddAddrX2h                    18           // Address of X2
#define  EccAddAddrX2l                    17
#define  EccAddAddrZ1h                    16           // Address of Z1
#define  EccAddAddrZ1l                    15
#define  EccAddAddrY1h                    14           // Address of Y1
#define  EccAddAddrY1l                    13
#define  Cns_h                            12           // constant Barrett
#define  Cns_l                            11
#define  Mod_h                            10           // Modulo
#define  Mod_l                            9
#define  ToBeReduced_h                    8            // Address of the number to be reduced
#define  ToBeReduced_l                    7
#define  Remainder_h                      6            // Remainder
#define  Remainder_l                      5
#define  ModLen_h                         4            // length of Modulo
#define  ModLen_l                         3
#define  Quotient_h                       2            // The Quotient
#define  Quotient_l                       1


; LlZpEccAdd_C
;
; Point addition in Jacobian projective coordinates

;
; Input parameters :
;         pu1PointABase       : Address of the first point for adding / the result
;              In R24-R25
;         pu1PointBBase       : Address of the second point for adding
;              In R22-R23
;         u2ModLength         : length of modulo
;              In R20-R21
;         pu1ModBase          : Address of modulo n
;              In R18-R19
;         pu1CnsBase          : Address of the reduction constant
;              In R16-R17
;         pu1Workspace        : Address of the workspace (C1)
;              In R14-R15
;
;
LlZpEccAdd_C:
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

	rcall	LlZpEccAdd

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

LlZpEccAdd:
    // Get the parameters
    //--------------------
    ldd		r0,y+1
    ldd     r1,y+2
    ldd     r2,y+3
    ldd     r3,y+4

    // Save non-scratch registers
    //---------------------------
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

    // Reallocation of the local parameters
    //-------------------------------------
	in 		r28,__SP_L__
    in 		r29,__SP_H__
	sbiw    r28,24
	in		r4,__SREG__
	cli
	out		__SP_H__,r29
	out		__SREG__,r4
	out		__SP_L__,r28  
    
    
    // R24 = M + 4
    movw     r24,r20
    adiw     r24,0x04
    
    
    // Address of C1
    //--------------
    movw     r10,r2                          ; Save into r10-r11

    movw     r6,r10
    // Address of C2
    //--------------
    add      r6,r24
    adc      r7,r25
    movw     r12,r6                          ; Save into r12-r13
    // Address of C3
    //--------------
    add      r6,r24
    adc      r7,r25
    std      y+EccAddAddrC3l,r6                    ; Save in the stack
    std      y+EccAddAddrC3h,r7
    // Address of buffer
    //------------------
    add      r6,r24
    adc      r7,r25
    movw     r4,r6                           ; Save into r2-r3
    // Address of Quotient
    //--------------------
    add      r6,r24
    adc      r7,r25
    add      r6,r24
    adc      r7,r25
    std      y+Quotient_l,r6           ; Save in the stack
    std      y+Quotient_h,r7
    
    
    // Point 1
    //--------
    // Address of X1
    //--------------
    movw     r8,r16                          ; Get the address of X1
    // Address of Y1
    //--------------
    add      r16,r24
    adc      r17,r25
    std      y+EccAddAddrY1l,r16                   ; Save in the stack
    std      y+EccAddAddrY1h,r17
    // Address of Z1
    //--------------
    add      r16,r24
    adc      r17,r25
    std      y+EccAddAddrZ1l,r16                   ; Save in the stack
    std      y+EccAddAddrZ1h,r17

    // Point 2
    //--------
    // Address of X2
    //--------------
    std      y+EccAddAddrX2l,R18                   ; Save in the stack
    std      y+EccAddAddrX2h,R19
    // Address of Y2
    //--------------
    add      r18,r24
    adc      r19,r25
    std      y+EccAddAddrY2l,R18                   ; Save in the stack
    std      y+EccAddAddrY2h,R19
    // Address of Z2
    //--------------
    add      r18,r24
    adc      r19,r25
    std      y+EccAddAddrZ2l,r18                   ; Save in the stack
    std      y+EccAddAddrZ2h,r19


    //---------------------------------
    // Modular reduction initialisation
    //-----------------------------------
    // Address of the buffer to be reduce
    //-----------------------------------
    std      y+ToBeReduced_l,r2
    std      y+ToBeReduced_h,r3
    // Address of modulo
    //------------------
    std      y+Mod_l,R22
    std      y+Mod_h,R23
    // Length of modulo
    //-----------------
    std      y+ModLen_l,R20
    std      y+ModLen_h,R21
    // Address of modular reduction constant
    //--------------------------------------
    std      y+Cns_l,r0
    std      y+Cns_h,r1
    
    
    // r6(-r7) = M+1
    sbiw     r24,0x03
    movw     r6,r24
    
    //--------------------------
    // Step 1 : C1 = Z1^2 mod n 
    //--------------------------
    // Buffer = Z1^2
    //--------------
	movw      r16,r4        ; buffer
	ldd       r18,y+EccAddAddrZ1l
    ldd       r19,y+EccAddAddrZ1h ; Z1
	mov       r20,r6        ; M+1
	call	  LlComba_Square_ASM
    
    // C1 = Buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 2 : C2 = X2*C1 mod n
    //--------------------------
    // Buffer = X2*C1
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrX2l
    ldd       r19,y+EccAddAddrX2h ; X2
    movw      r20,r10       ; C1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C2 = Buffer mod n
    //------------------
    movw      r16,r12       ; C2
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 3 : C1 = C1*Z1 mod n
    //--------------------------
    // Buffer = C1*Z1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    ldd       r20,y+EccAddAddrZ1l
    ldd       r21,y+EccAddAddrZ1h ; Z1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C1 = buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 4 : C3 = Y2*C1 mod n
    //--------------------------
    // Buffer = Y2*C1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    ldd       r20,y+EccAddAddrY2l
    ldd       r21,y+EccAddAddrY2h ; Y2
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C3 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrC3l
    ldd       r17,y+EccAddAddrC3h ; C3
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 5 : C1 = Z2^2 mod n
    //-------------------------
    // Buffer = Z2^2
    //--------------
	movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrZ2l
    ldd       r19,y+EccAddAddrZ2h ; Z2
	mov       r20,r6        ; M+1
	call	  LlComba_Square_ASM
    
    // C1 = Buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 6 : X1 = X1*C1 mod n
    //--------------------------
    // Buffer = X1*C1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r8        ; X1
    movw      r20,r10       ; C1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // X1 = Buffer mod n
    //------------------
    movw      r16,r8        ; X1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 7 : C1 = C1*Z2 mod n
    //--------------------------
    // Buffer = C1*Z2
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    ldd       r20,y+EccAddAddrZ2l
    ldd       r21,y+EccAddAddrZ2h ; Z2
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C1 = buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //--------------------------
    // Step 8 : Y1 = Y1*C1 mod n
    //--------------------------
    // Buffer = Y1*C1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    ldd       r20,y+EccAddAddrY1l
    ldd       r21,y+EccAddAddrY1h ; Y1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // Y1 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrY1l
    ldd       r17,y+EccAddAddrY1h ; Y1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------------
    // Step 9  : Z1 = Z1*Z2 mod n
    //---------------------------
    // Buffer = Z1*Z2
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrZ1l
    ldd       r19,y+EccAddAddrZ1h ; Z1
    ldd       r20,y+EccAddAddrZ2l
    ldd       r21,y+EccAddAddrZ2h ; Z2
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // Z1 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrZ1l
    ldd       r17,y+EccAddAddrZ1h ; Z1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------
    // Step 10 : C1 = Y1-C3
    //---------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r6        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + Y1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    ldd       r20,y+EccAddAddrY1l
    ldd       r21,y+EccAddAddrY1h ; Y1
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Buffer = Buffer - C3
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    ldd       r20,y+EccAddAddrC3l
    ldd       r21,y+EccAddAddrC3h ; C3   
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    
    // C1 = buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-----------------------
    // Step 11 : Y1 = Y1 + C3
    //-----------------------
	// Buffer = Y1 + C3
	//------------------
    movw      r16,r4		; buffer
    ldd       r18,y+EccAddAddrY1l
    ldd       r19,y+EccAddAddrY1h ; Y1
    ldd       r20,y+EccAddAddrC3l
    ldd       r21,y+EccAddAddrC3h ; C3 
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Y1 = Buffer mod p
	//------------------
    ldd       r16,y+EccAddAddrY1l
    ldd       r17,y+EccAddAddrY1h ; Y1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------
    // Step 12 : C3 = X1-C2
    //---------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r6        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + X1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r8        ; X1
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Buffer = Buffer - C2
    //---------------------
    movw      r16,r4
    movw      r18,r4        ; buffer
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    // C3 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrC3l
    ldd       r17,y+EccAddAddrC3h ; C3
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    
    //-----------------------
    // Step 13 : X1 = X1 + C2
    //-----------------------
	// Buffer = X1 + C2
	//------------------
    movw      r16,r4        ; buffer
    movw      r18,r8        ; X1
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
	// X1 = Buffer mod p
	//------------------
    movw      r16,r8		; X1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //------------------------------------
    // Step 14 : Z1 = Z1*C3 mod n ( Z3 ! )
    //------------------------------------
    // Buffer = Z1*C3
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrZ1l
    ldd       r19,y+EccAddAddrZ1h ; Z1
    ldd       r20,y+EccAddAddrC3l
    ldd       r21,y+EccAddAddrC3h ; C3
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // Z1 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrZ1l
    ldd       r17,y+EccAddAddrZ1h ; Z1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------------
    //  Step 15 : C2 = C3^2 mod n
    //---------------------------
    // Buffer = C3^2
    //---------------
	movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrC3l
    ldd       r19,y+EccAddAddrC3h ; C3
	mov       r20,r6        ; M+1
	call	LlComba_Square_ASM  
    
    // C2 = Buffer mod n
    //------------------
    movw      r16,r12       ; C2
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------------
    //  Step 16 : C3 = C2*C3 mod n
    //----------------------------
    // Buffer = C3*C2
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; C2
    ldd       r20,y+EccAddAddrC3l
    ldd       r21,y+EccAddAddrC3h ; C3
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C3 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrC3l
    ldd       r17,y+EccAddAddrC3h ; C3
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------------
    //  Step 17 : C2 = C2*X1 mod n
    //----------------------------
    // Buffer = C2*X1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; C2
    movw      r20,r8        ; X1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C2 = buffer mod n
    //------------------
    movw      r16,r12       ; C2
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------------
    //  Step 18 : C3 = C3*Y1 mod n
    //----------------------------
    // Buffer = C3*Y1
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccAddAddrC3l
    ldd       r19,y+EccAddAddrC3h ; C3
    ldd       r20,y+EccAddAddrY1l
    ldd       r21,y+EccAddAddrY1h ; Y1
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C3 = buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrC3l
    ldd       r17,y+EccAddAddrC3h ; C3
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------------
    //  Step 19 : Y1 = C1^2 mod n
    //---------------------------
    // Buffer = C1^2
    //--------------
	movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    mov       r20,r6        ; M+1
	call	  LlComba_Square_ASM
    
    // Y1 = Buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrY1l
    ldd       r17,y+EccAddAddrY1h ; Y1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------
    //  Step 20 : X1 = Y1-C2
    //----------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r6        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + Y1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    ldd       r20,y+EccAddAddrY1l
    ldd       r21,y+EccAddAddrY1h ; Y1
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Buffer = Buffer - C2
    //---------------------
    movw      r16,r4        ; X1 
    movw      r18,r4        ; buffer
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    
	// X1 = Buffer mod p
	//------------------
    movw      r16,r8        ; X1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //------------------------
    //  Step 21 : C2 = C2-2*X1
    //------------------------
    // Buffer = 2^4*n
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x04      ; 2^4
    mov       r22,r6        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + C2
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Buffer = Buffer - X1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r8        ; X1
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    // Buffer = Buffer - X1
    //-------------------
    movw      r16,r4
    movw      r18,r4        ; buffer
    movw      r20,r8        ; X1
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    // C2 = Buffer mod p
	//------------------
    movw      r16,r12       ; C2
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------------
    //  Step 22 : C1 = C2*C1 mod n
    //----------------------------
    // Buffer = C2*C1
    //---------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; C1
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlComba_Mult_ASM
    
    // C1 = buffer mod n
    //------------------
    movw      r16,r10       ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //----------------------
    //  Step 23 : C2 = C1-C3
    //----------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r6        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + C1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r10       ; C1
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    // Buffer = Buffer - C3
    //-----------------
    movw      r16,r4
    movw      r18,r4        ; buffer
    ldd       r20,y+EccAddAddrC3l
    ldd       r21,y+EccAddAddrC3h ; C3
    mov       r22,r6        ; M+1
    call      LlZpBase_Sub_ASM
    
    // C2 = Buffer mod p
	//------------------
    movw      r16,r12       ; C2
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    
    //--------------------
    // Step 24 : Y1 = C2/2
    //--------------------
    // C2 = C2 + L*modulo 
    //-------------------
    // Buffer = L*modulo 
    //------------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    
    movw      r26,r12       ; X = C2
    ld        r20,x         ; r20 = LSB(C2)
    ori       r20,2         ; We set a bit to 1, to avoid the case zero 
    
    mov       r22,r6        ; M+1
    call      LlComba_Mult_One_Byte_ASM
    
    // Buffer = Buffer + C2
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r12       ; C2
    mov       r22,r6        ; M+1
    call      LlZpBase_Add_ASM
    
    
    // Buffer = Buffer / 2
    //--------------------
    clr     r0
    
    movw      r26,r4 
    add       r26,r6
    adc       r27,r0 ; X = buffer + (M+1)
    movw      r30,r4
    add       r30,r6
    adc       r31,r0 ; Z = buffer + (M+1)
    
    
    ; carry between bytes
    clr     r24
    
    ; Right shift of 1
    ldi     r23,0x01
    
    ; Loop on the bytes
Begin_Loop_Byte:
    cp      r0,r6
    breq    End_Loop_Byte
    
    ld      r2,-x
    
    clr     r3
    clr     r1
    ; Loop on the bits
Begin_Loop_Bit:
    cp      r1,r23
    breq    End_Loop_Bit
    
    ; Right shift r2
    lsr     r2
    ; Get the carry in r3
    ror     r3
    
    inc     r1
    jmp     Begin_Loop_Bit
End_Loop_Bit:
    
    ; add carry of the previous byte
    add     r2,r24
    
    ; store the result
    st      -z,r2
    
    ; put the carry for the next byte
    mov     r24,r3
    
    inc     r0
    jmp     Begin_Loop_Byte

End_Loop_Byte:


    // Y1 = Buffer mod n
    //------------------
    ldd       r16,y+EccAddAddrY1l
    ldd       r17,y+EccAddAddrY1h
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    
    // Deallocation of the local parameters
    //-------------------------------------
	adiw	r28,24
	in	__tmp_reg__,__SREG__
	cli
	out	__SP_H__,r29
	out	__SREG__,__tmp_reg__
	out	__SP_L__,r28
    
    
    // Registers restoration
    //---------------------------
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
    
    
    
#define  EccDblAddrAh		16           // Address of ParamA
#define  EccDblAddrAl		15    
#define  EccDblAddrC2h		14           // Address of C2
#define  EccDblAddrC2l		13
    
; LlZpEccDbl_C
;
; Point doubling in Jacobian projective coordinates
;
; Input parameters:
;         pu1PointToBeDoubled : Address of the point for doubling / the result
;              In R24-R25
;         u2ModLength         : Length of modulo
;              In R22-R23
;         pu1ModBase          : Address of modulo
;              In R20-R21
;         pu1CnsBase          : Address of the reduction constant
;              In R18-R19
;         pu1Workspace        : Address of the workspace
;              In R16-R17
;         pu1AParameterBase   : Address of A
;              In R14-R15
;
LlZpEccDbl_C:
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

	rcall	LlZpEccDbl

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

LlZpEccDbl:
    // Get the parameters
    //--------------------
    ldd      r0,y+1
    ldd      r1,y+2
    ldd      r2,y+3
    ldd      r3,y+4


    // Save non-scratch registers
    //---------------------------
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

    // Reallocation of the local parameters
    //-------------------------------------
	in 		r28,__SP_L__
    in 		r29,__SP_H__
	sbiw    r28,16
	in		r4,__SREG__
	cli
	out		__SP_H__,r29
	out		__SREG__,r4
	out		__SP_L__,r28     
    
    
    // R24 = M + 4
    movw     r24,r18
    adiw     r24,0x04
    
    // Address of parameter A
    //-----------------------
	std		 y+EccDblAddrAl,r2
	std		 y+EccDblAddrAh,r3
    
    
    // Address of C1
    //--------------
    movw     r6,r0                           ; Save into r6-r7

    movw     r12,r0
    // Address of C2
    //--------------
    add      r12,r24
    adc      r13,r25
	std		 y+EccDblAddrC2l,r12
	std		 y+EccDblAddrC2h,r13
    // Address of buffer
    //------------------
    add      r12,r24
    adc      r13,r25
    movw     r4,r12                          ; Save into r4-r5
    // Address of quotient
    //--------------------
    add      r12,r24
    adc      r13,r25
    add      r12,r24
    adc      r13,r25
    std      y+Quotient_l,r12                ; Save in the stack
    std      y+Quotient_h,r13
    
    
    // Point
    //------
    // Address of X
    //--------------
    movw     r10,r16                         ; Save into r10-r11
    // Address of Y
    //--------------
    add      r16,r24
    adc      r17,r25
    movw     r12,r16                         ; Save into r12-r13      
    // Address of Z
    //--------------
    add      r16,r24
    adc      r17,r25
    movw     r14,r16                         ; Save into r14-r15      
    
    
    //---------------------------------
    // Modular reduction initialisation
    //-----------------------------------
    // Address of the buffer to be reduce
    //-----------------------------------
    std      y+ToBeReduced_l,r4
    std      y+ToBeReduced_h,r5
    // Address of modulo
    //------------------
    std      y+Mod_l,R20
    std      y+Mod_h,R21
    // Length of modulo
    //-----------------
    std      y+ModLen_l,R18
    std      y+ModLen_h,R19
    // Address of modular reduction constant
    //--------------------------------------
    std      y+Cns_l,r22
    std      y+Cns_h,r23
    
    
    
    // r8-r9 = M+1
    sbiw     r24,0x03
	movw	r8,r24
    
    
    
    //--------------------------
    // Step 1 : C1 = Z^2 mod n 
    //--------------------------
    // Buffer = Z^2
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r14       ; Z
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM
    
    // C1 = Buffer mod n
    //------------------
    movw      r16,r6        ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 2 : Z = 2*Y*Z mod n
    //-------------------------
    // Buffer = Y*Z
    //-------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; Y
    movw      r20,r14       ; Z
    mov       r22,r8        ; M+1
    call      LlComba_Mult_ASM
    
    // Z = Buffer mod p
    //-----------------
    movw      r16,r14       ; Z
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    // Buffer = 2*Z
    //-------------
    movw      r16,r4        ; buffer
    movw      r18,r14       ; Z
    ldi       r20,0x01      ; 2^1
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Z = Buffer mod p
    //-----------------
    movw      r16,r14       ; Z
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 3 : C1 = C1^2 mod n
    //-------------------------
    // Buffer = C1^2
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r6        ; C1
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM
    
    // C1 = Buffer mod n
    //------------------
    movw      r16,r6        ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    
    //-------------------------
    // Step 4 : Y = Y^2 mod n
    //-------------------------
    // Buffer = Y^2
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; Y
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM
    
    // Y = Buffer mod n
    //------------------
    movw      r16,r12       ; Y
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 5 : C2 = X^2 mod n
    //-------------------------
    // Buffer = X^2
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; X
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM
    
    // C2 = Buffer mod n
    //------------------
    ldd       r16,y+EccDblAddrC2l	; C2
	ldd		  r17,y+EccDblAddrC2h
    movw      r18,r4        		; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   		; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   		; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 6 : X = 4*X*Y mod n
    //-------------------------
    // Buffer = X*Y
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; X
    movw      r20,r12       ; Y
    mov       r22,r8        ; M+1
    call      LlComba_Mult_ASM
    
    // X = Buffer mod n
    //------------------
    movw      r16,r10       ; X
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    // Buffer = 4*X
    //-------------
    movw      r16,r4        ; buffer
    movw      r18,r10       ; X
    ldi       r20,0x02      ; 2^2
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // X = Buffer mod p
    //-----------------
    movw      r16,r10       ; X
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    //-------------------------
    // Step 7 : C2 = 3*C2 mod n
    //-------------------------
    // Buffer = 3*C2
    //--------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccDblAddrC2l	; C2
	ldd		  r19,y+EccDblAddrC2h
    ldi       r20,0x03      ; 3
    mov       r22,r8        ; M+1
    call      LlComba_Mult_One_Byte_ASM
    
    // C2 = Buffer mod p
    //-----------------
    ldd       r16,y+EccDblAddrC2l	; C2
	ldd		  r17,y+EccDblAddrC2h
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 8 : C1 = A*C1 mod n
    //-------------------------
    // Buffer = A*C1
    //--------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccDblAddrAl       ; A
	ldd		  r19,y+EccDblAddrAh
    movw      r20,r6        ; C1
    mov       r22,r8        ; M+1
    call      LlComba_Mult_ASM
    
    // C1 = Buffer mod n
    //------------------
    movw      r16,r6        ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 9 : C2 = C2+C1 mod n
    //-------------------------
    // Buffer = C2+C1
    //--------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccDblAddrC2l	; C2
	ldd		  r19,y+EccDblAddrC2h
    movw      r20,r6        ; C1
    mov       r22,r8        ; M+1
    call      LlZpBase_Add_ASM
    
    // C2 = Buffer mod n
    //------------------
    ldd       r16,y+EccDblAddrC2l	; C2
	ldd		  r17,y+EccDblAddrC2h
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 10 : Y = Y^2 mod n
    //-------------------------
    // Buffer = Y^2
    //--------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; Y
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM
    
    // Y = Buffer mod n
    //------------------
    movw      r16,r12       ; Y
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 11 : Y = 8*Y mod n
    //-------------------------
    // Buffer = 8*Y
    //-------------
    movw      r16,r4        ; buffer
    movw      r18,r12       ; Y
    ldi       r20,0x03      ; 2^3
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Y = Buffer mod n
    //------------------
    movw      r16,r12       ; Y
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //-------------------------
    // Step 12 : C1 = C2^2
    //-------------------------
	// Buffer = C2^2
	//--------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccDblAddrC2l	; C2
	ldd		  r19,y+EccDblAddrC2h
    mov       r20,r8        ; M+1
    call      LlComba_Square_ASM

	// C1 = Buffer mod p
	//------------------
	movw      r16,r6        ; c1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    //----------------------------
    // Step 13 : C1 = C1 - 2*X
    //----------------------------
	// Buffer = 2^4*n
    //---------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x04      ; 2^4
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM

	// Buffer = Buffer + C1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r6        ; C1
    mov       r22,r8        ; M+1
    call      LlZpBase_Add_ASM

    // Buffer = Buffer - X
    //--------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r10       ; X
    mov       r22,r8        ; M+1
    call      LlZpBase_Sub_ASM
    
    // Buffer = Buffer - X
    //--------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r10       ; X
    mov       r22,r8        ; M+1
    call      LlZpBase_Sub_ASM
    
    // C1 = Buffer mod p
    //------------------
    movw      r16,r6        ; C1
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    //----------------------------
    // Step 14 : X = X - C1 mod n
    //----------------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + X
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r10       ; X
    mov       r22,r8        ; M+1
    call      LlZpBase_Add_ASM

    // Buffer = Buffer - C1
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r6        ; C1
    mov       r22,r8        ; M+1
    call      LlZpBase_Sub_ASM
    
    // X = Buffer mod p
    //-----------------
    movw      r16,r10       ; X
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //---------------------------
    // Step 15 : C2 = C2*X mod n
    //--------------------------
    // Buffer = C2*X
    //--------------
    movw      r16,r4        ; buffer
    ldd       r18,y+EccDblAddrC2l	; C2
	ldd		  r19,y+EccDblAddrC2h
    movw      r20,r10       ; X
    mov       r22,r8        ; M+1
    call      LlComba_Mult_ASM
    
    // C2 = Buffer mod n
    //------------------
    ldd       r16,y+EccDblAddrC2l	; C2
	ldd		  r17,y+EccDblAddrC2h
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    
    //----------------------------
    // Step 16 : Y = C2-Y mod n
    //----------------------------
    // Buffer = 2*n
    //-------------
    movw      r16,r4        ; buffer
    ldd       r18,y+Mod_l
    ldd       r19,y+Mod_h   ; Mod
    ldi       r20,0x01      ; 2^1
    mov       r22,r8        ; M+1
    call      LlZpBase_Mul_2d_ASM
    
    // Buffer = Buffer + C2
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    ldd       r20,y+EccDblAddrC2l	; C2
	ldd		  r21,y+EccDblAddrC2h
    mov       r22,r8        ; M+1
    call      LlZpBase_Add_ASM

    // Buffer = Buffer - Y
    //---------------------
    movw      r16,r4        ; buffer
    movw      r18,r4        ; buffer
    movw      r20,r12       ; Y
    mov       r22,r8        ; M+1
    call      LlZpBase_Sub_ASM
    
    // Y = Buffer mod p
    //-----------------
    movw      r16,r12       ; Y
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    //------------------------
    // Step 17 : X1 = C1 mod n
    //------------------------
    // Buffer = C1 + Pad
    //------------------
    movw      r16,r4
    movw      r18,r6
    mov       r20,r8 
    mov       r22,r8 
    dec       r22
    lsl       r22
    call      LlBase_Copy_Pad_ASM
    
    // X = Buffer mod p
    //-----------------
    movw      r16,r10       ; X
    movw      r18,r4        ; buffer
    ldd       r20,y+Mod_l
    ldd       r21,y+Mod_h   ; Mod
    ldd       r22,y+Cns_l
    ldd       r23,y+Cns_h   ; Cns
    call      LlBarrett_Reduce_ASM
    
    
    // Deallocation of the local parameters
    //-------------------------------------
	adiw	r28,16
	in	__tmp_reg__,__SREG__
	cli
	out	__SP_H__,r29
	out	__SREG__,__tmp_reg__
	out	__SP_L__,r28
    
    
    // Registers restoration
    //---------------------------
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
    


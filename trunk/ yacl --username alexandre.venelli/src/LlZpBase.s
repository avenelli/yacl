/*
LlZpBase.s - Elliptic curve addition and doubling on general curves over Zp 
				considering projective Jacobian coordinates.

Copyright 2010 Alexandre VENELLI

This file is part of the YACL.

The YACL is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

The YACL is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
License for more details.

You should have received a copy of the GNU Lesser General Public License
along with the YACL.  If not, see http://www.gnu.org/licenses/.
*/
#include "Llglobvars.h"

    .global LlZpBase_Sub_C
    .global LlZpBase_Add_C
    .global LlZpBase_Mul_2d_C
    .global LlZpBase_InvMod_C
	.global LlZpBase_Sub_ASM
	.global LlZpBase_Add_ASM
	.global LlZpBase_Mul_2d_ASM
	
	.extern LlBase_Copy_Pad_ASM
	.extern LlBase_SetByte_ASM

; LlZpBase_Sub_Signed
;
; (internal use for LlZpBase_InvMod_C)
;
; Signed subtraction
;
; X = X - Y 
; ParamX = r16-r17
; ParamY = r20-r21
; Length = r22-r23
; SignX = r12
; SignY = r13	
LlZpBase_Sub_Signed:
	push	r4
	push	r5
	push	r6
	push	r7

    movw    r4,r18 ; save X
    movw    r6,r20 ; save Y
    
    ; TEST SIGNX, SIGNY
    cp 	    r12,r13
    brne    Sign_X_Y_Diff
	
    ; SIGNX = SIGNY
    ; |X| CMP |Y|
    movw    r16,r18
    movw    r18,r20
    ; r22-r23 already M
    call    LlCmp_Unsigned
    ldi	    r24,0xFF
    cp	    r16,r24
    breq    Y_Higher_Than_X
	
    ; |X| >= |Y|
    ; X = |X| - |Y|
    movw    r16,r4
    movw    r18,r4
    movw    r20,r6
    call    LlZpBase_Sub_ASM
	
    jmp	    End_LlZpBase_Sub_Signed
    
Y_Higher_Than_X:
    ; |Y| > |X|
    ; SIGNX = COM(SIGNX)
    com	    r12 
    ; X = |Y| - |X|
    movw    r16,r4
    movw    r18,r6
    movw    r20,r4
    call    LlZpBase_Sub_ASM
	
    jmp     End_LlZpBase_Sub_Signed
	
	
Sign_X_Y_Diff:
    ; SIGNX != SIGNY
    ; X = |X| + |Y|
    movw    r16,r4
    movw    r18,r4
    movw    r20,r6
    call    LlZpBase_Add_ASM

End_LlZpBase_Sub_Signed:
	pop		r7
	pop		r6
	pop		r5
	pop		r4
    ret
        

; LlCmp_Unsigned
;
; (internal use for LlZpBase_InvMod_C)
;
; Input parameters:
;       pu1X  : Adress of X
;         in R16-R17
;       pu1Y  : Adress of Y
;         in R18-R19
;       u2ModLength : length of modulo
;         in R22-R23
;
; Return in R16:
;       0x00     if X = Y
;       0x01     if X > Y
;       0xFF     if X < Y
LlCmp_Unsigned:
    clr     r0 ; cpt
    movw    r26,r16 ; PtrX = X
    add     r26,r22
    adc     r27,r23
    movw    r30,r18 ; PtrZ = Y
    add     r30,r22
    adc     r31,r23
    clr     r16
Begin_Loop_CmpU:
    cp      r0,r22
    breq    End_CmpU
    
    ld      r1,-x
    ld      r2,-z
    cp      r1,r2
    brlo    Cmp_X_Lower
    cp      r2,r1
    brlo    Cmp_Y_Lower
    
    inc     r0
    jmp     Begin_Loop_CmpU

Cmp_Y_Lower:
    ldi     r24,0x01
    mov     r16,r24
    jmp     End_CmpU
Cmp_X_Lower:
    ldi     r24,0xFF
    mov     r16,r24
 
End_CmpU:
    ret


; LlCmp_Unsigned_Zero
;
; (internal use for LlZpBase_InvMod_C)
;
; X ?= 0 
;
; ParamX = r16-r17
; Length = r22-r23
;
; Return in R16:
;     0x00    if X = 0
;     0xFF    if X!= 0
LlCmp_Unsigned_Zero:
    clr     r0 ; cpt
    movw    r26,r16 ; PtrX = X
    add     r26,r22
    adc     r27,r23
    clr     r16
Begin_Loop_CmpUZ:
    cp      r0,r22
    breq    End_CmpUZ
    
    ld      r1,-x
    tst     r1
    brne    CmpUZ_NotZero
    
    inc     r0
    jmp     Begin_Loop_CmpUZ

CmpUZ_NotZero:
    ldi     r24,0xFF
    mov     r16,r24
End_CmpUZ:
    ret

; LlDiv2
;
; (internal use for LlZpBase_InvMod_C)
;
; X = X/2
;
; ParamX = r16-r17
; Length = r22-r23
LlDiv2:
    clr     r0
    movw    r26,r16 
    add     r26,r22
    adc     r27,r23 ; X = buffer + (M+1)
    movw    r30,r16
    add     r30,r22
    adc     r31,r23 ; Z = buffer + (M+1)
    
    ; carry between bytes
    clr     r24
    
    ; Right shift of 1
    ldi     r25,0x01
    
    ; Loop on the bytes
Begin_Loop_Div2_Byte:
    cp      r0,r22
    breq    End_Loop_Div2_Byte
    
    ld      r2,-x
    
    clr     r3
    clr     r1
    ; Loop on the bits
Begin_Loop_Div2_Bit:
    cp      r1,r25
    breq    End_Loop_Div2_Bit
    
    ; Right shift r2
    lsr     r2
    ; Get the carry in r3
    ror     r3
    
    inc     r1
    jmp     Begin_Loop_Div2_Bit
End_Loop_Div2_Bit:
    
    ; add carry of the previous byte
    add     r2,r24
    
    ; store the result
    st      -z,r2
    
    ; put the carry for the next byte
    mov     r24,r3
    
    inc     r0
    jmp     Begin_Loop_Div2_Byte

End_Loop_Div2_Byte:
    ret



#define InvModVh 8
#define InvModVl 7
#define InvModDh 6
#define InvModDl 5
#define InvModXh 4
#define InvModXl 3
#define InvModMh 2
#define InvModMl 1

; InvMod_Loop_INT
;
; (Internal function of LlZpBase_InvMod_C)
;
; U     (or V)     = r4-r5
; B     (or D)     = r6-r7
; signU (or signV) = r8
; signB (or signD) = r9
InvMod_Loop_INT:
    ; WHILE ( U MOD 2 = 0 )
    movw    r26,r4 ; U (or V)
    ld      r24,x
    andi    r24,0x01
    tst     r24
    brne    End_InvMod_Loop_INT
    ; U = U/2
    movw    r16,r4
    ; r22-r23 already ModLength
    call    LlDiv2

    ; IF ( B MOD 2 = 0 )
    movw    r26,r6 ; B
    ld      r24,x
    andi    r24,0x01
    tst     r24
    brne    B_Mod2_NotEq_Zero
    
    ; B MOD 2 = 0 
    ; => B = B/2
    movw    r16,r6
    ; r22-r23 already ModLength
    call    LlDiv2
    jmp     InvMod_Loop_INT

B_Mod2_NotEq_Zero:
    ; B MOD 2 = 1
    ; B = (B-X)/2
	
    mov	    r12,r9 ; SIGNB
    clr	    r13    ; SIGNX
    movw    r16,r6
    movw    r18,r6
    ldd	    r20,y+InvModMl
    ldd	    r21,y+InvModMh
    call    LlZpBase_Sub_Signed
    mov	    r9,r12 ; save new SIGNB
	
    ; B = B/2
    movw    r16,r6
    ; r22-r23 already ModLength
    call    LlDiv2
	
    jmp     InvMod_Loop_INT
	
End_InvMod_Loop_INT:
    ret


; LlZpBase_InvMod_C
;
; X = X^{-1} mod M
;
; Algorithm 14.61 HAC - Binary extended GCD 
; modified for multiplicative inverses with Note 14.64 HAC 
;
; Input parameters:
;       pu1X  : Adress of X
;         in R16-R17
;       pu1M  : Adress of modulo
;         in R18-R19
;       pu1Workspace  : Adress of Workspace
;         in R20-R21
;		u2ModLength : length of modulo + 1 (at least)
;         in R22-R23
;
; Workspace mapping:
; |__________|__________|__________|__________|
;      u          v           B         D
;
; Workspace size: 4*ModLength
;
; Registers:
; r4 - r5 : u
; r6 - r7 : B
; r8-r9-r10-r11 : signs of u,B,v,D
;
; Perf:
; u2ModLength		Nb. cycles
;	0x18			717139
;	0x30			2481859
;
LlZpBase_InvMod_C:

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
	push	r28
	push	r29
    
    ; Allocate local parameters on the stack
    in 		r28,__SP_L__
    in 		r29,__SP_H__
	sbiw	r28,8
	in		__tmp_reg__,__SREG__
	cli
	out		__SP_H__,r29
	out		__SREG__,__tmp_reg__
	out		__SP_L__,r28

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	rcall 	LlZpBase_InvMod

	; Convention (r1=0)
	clr		r1

    ; Deallocate local parameters on the stack
    adiw	r28,8
	in	__tmp_reg__,__SREG__
	cli
	out	__SP_H__,r29
	out	__SREG__,__tmp_reg__
	out	__SP_L__,r28
    
    ; Registers restoration
    pop		r29
	pop		r28
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

LlZpBase_InvMod:
    std     y+InvModXl,r16
    std     y+InvModXh,r17
    std     y+InvModMl,r18
    std     y+InvModMh,r19
    
    
    ; r24 = ModLength
    movw    r24,r22
	
    ; Allocate variables
    movw    r4,r20 ; r4-r5 = u
	
    add     r20,r24
    adc     r21,r25
    std	    y+InvModVl,r20
    std	    y+InvModVh,r21 ; v
    
    add     r20,r24
    adc     r21,r25
    movw    r6,r20 ; r6-r7 = B
    
    add     r20,r24
    adc     r21,r25
    std	    y+InvModDl,r20
    std     y+InvModDh,r21 ; D
	
    clr	    r8 ;signU
    clr	    r9 ;signB
    clr	    r10 ;signV
    clr	    r11 ;signD
	
    ; Init variables
    ; u = M
    movw    r16,r4
    ; r18 already M
    movw    r20,r22
    ; r22-r23 already ModLength
    call    LlBase_Copy_Pad_ASM
	
    ; v = X
    ldd	    r16,y+InvModVl
    ldd	    r17,y+InvModVh
    ldd     r18,y+InvModXl
    ldd     r19,y+InvModXh
    ; r20-r21 already ModLength
    ; r22-r23 already ModLength
    call    LlBase_Copy_Pad_ASM
    
    ; D = 1
    ldd	    r16,y+InvModDl
    ldd	    r17,y+InvModDh
    clr     r18
    inc     r18
    clr     r19
    ; r20-r21 already ModLength
    call    LlBase_SetByte_ASM
    
    ; B = 0
    movw    r16,r6
    clr     r18
    clr     r19
    ; r20-r21 already ModLength
    call    LlBase_SetByte_ASM
	
    ; LOOP ON (U!=0)
Begin_Loop_InvMod:	
    ; test if u != 0
    movw    r16,r4
    ; r22-r23 already ModLength
    call    LlCmp_Unsigned_Zero
    tst     r16
    brne    Begin_Loop_InvMod_Main	
    jmp     End_Loop_InvMod
Begin_Loop_InvMod_Main:
    ; U = r4-r5
    ; B = r6-r7
    ; signU = r8
    ; signB = r9
    call    InvMod_Loop_INT
	
    ; swap U <-> V
    movw    r24,r4
    ldd	    r4,y+InvModVl
    ldd	    r5,y+InvModVh
    std	    y+InvModVl,r24
    std	    y+InvModVh,r25
    ; swap B <-> D
    movw    r24,r6
    ldd	    r6,y+InvModDl
    ldd	    r7,y+InvModDh
    std	    y+InvModDl,r24
    std	    y+InvModDh,r25
    ; swap sign r8-r9 <-> r10-r11
    movw    r24,r8
    movw    r8,r10
    movw    r10,r24
    ; V = r4-r5
    ; D = r6-r7
    ; signV = r8
    ; signD = r9
    call    InvMod_Loop_INT
	
    ; swap U <-> V
    movw    r24,r4
    ldd	    r4,y+InvModVl
    ldd	    r5,y+InvModVh
    std	    y+InvModVl,r24
    std	    y+InvModVh,r25
    ; swap B <-> D
    movw    r24,r6
    ldd	    r6,y+InvModDl
    ldd	    r7,y+InvModDh
    std	    y+InvModDl,r24
    std	    y+InvModDh,r25
    ; swap sign r8-r9 <-> r10-r11
    movw    r24,r8
    movw    r8,r10
    movw    r10,r24
  
    ; IF ( U >= V )
	
    ; TEST SIGN
    cp	    r8,r10
    brlo    U_Sup_V
    cp	    r10,r8
    brlo    V_Sup_U
	
    movw    r16,r4
    ldd	    r18,y+InvModVl
    ldd	    r19,y+InvModVh
    call    LlCmp_Unsigned
    ldi     r24,0xFF
    cp      r16,r24
    breq    V_Sup_U

U_Sup_V:
    ; U = U - V
    mov	    r12,r8  ; SIGNU
    mov	    r13,r10 ; SIGNV
    movw    r16,r4
    movw    r18,r4
    ldd	    r20,y+InvModVl
    ldd	    r21,y+InvModVh
    call    LlZpBase_Sub_Signed
    mov	    r8,r12 ; save new SIGNU
	
    ; B = B - D
    mov	    r12,r9  ; SIGNB
    mov	    r13,r11 ; SIGND
    movw    r16,r6
    movw    r18,r6
    ldd	    r20,y+InvModDl
    ldd	    r21,y+InvModDh
    call    LlZpBase_Sub_Signed
    mov	    r9,r12 ; save new SIGNU
	
    jmp	    Begin_Loop_InvMod
	
V_Sup_U:
    ; V = V - U
    mov	    r12,r10 ; SIGNV
    mov	    r13,r8  ; SIGNU
    ldd	    r16,y+InvModVl
    ldd	    r17,y+InvModVh
    movw    r18,r16
    movw    r20,r4
    call    LlZpBase_Sub_Signed
    mov	    r10,r12 ; save new SIGNV
	
    ; D = D - B
    mov	    r12,r11 ; SIGND
    mov	    r13,r9  ; SIGNB
    ldd	    r16,y+InvModDl
    ldd	    r17,y+InvModDh
    movw    r18,r16
    movw    r20,r6
    call    LlZpBase_Sub_Signed
    mov	    r11,r12 ; save new SIGND
	
    jmp	    Begin_Loop_InvMod

End_Loop_InvMod:

    tst     r11
    brne    Add_Mod_To_D
    ; COPY D INTO X
    ldd	    r16,y+InvModXl
    ldd	    r17,y+InvModXh
    ldd	    r18,y+InvModDl
    ldd	    r19,y+InvModDh
    movw    r20,r22
    call    LlBase_Copy_Pad_ASM
    
    jmp     End_InvMod

Add_Mod_To_D:
	ldd		r16,y+InvModMl
	ldd		r17,y+InvModMh
	ldd		r18,y+InvModDl
	ldd		r19,y+InvModDh
	call	LlCmp_Unsigned

	ldi	    r24,0xFF
    cp	    r16,r24
    brne    Final_Add_Mod_To_D

	ldd		r16,y+InvModMl
	ldd		r17,y+InvModMh
	ldd		r18,y+InvModMl
	ldd		r19,y+InvModMh
	ldd		r20,y+InvModMl
	ldd		r21,y+InvModMh
	call	LlZpBase_Add_ASM
	jmp		Add_Mod_To_D

Final_Add_Mod_To_D:
    ; X = M - D
    ldd	    r16,y+InvModXl
    ldd	    r17,y+InvModXh
    ldd     r18,y+InvModMl
    ldd     r19,y+InvModMh
    ldd	    r20,y+InvModDl
    ldd	    r21,y+InvModDh
    call    LlZpBase_Sub_ASM
    

End_InvMod:
    
    ret
    

    
; LlZpBase_Add_C
; LlZpBase_Add_ASM
;
; R = X + Y
;
; pu1R can be equal to pu1X
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
; Output:
;       R24 = Last carry
;
; Length:
;       M + M -> M + 1
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			617
;	0x30			1169
;
LlZpBase_Add_C:  

	; Save non-scratch registers
	push	r2
	push	r3
    push    r8
    push    r9
	push    r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	rcall	LlZpBase_Add

	; IAR-style return value in R16
	mov		r24,r16

	; Convention (r1=0)
	clr		r1

    ; Registers restoration
	pop		r17
	pop		r16
    pop     r9
    pop     r8
	pop		r3
	pop		r2

	ret

LlZpBase_Add_ASM:
	push	r2
	push	r3
    push    r8
    push    r9

	rcall 	LlZpBase_Add

    pop     r9
    pop     r8
	pop		r3
	pop		r2

	ret

LlZpBase_Add:	  

    ; r8 = compteur
    clr     r8
    
    ; r24 = carry = 0
    clr     r24
    
    ; r9 = constant a zero
    clr     r9
    
    movw    r26,r20 ; PtrX = Y    
    
Begin_Loop_Add:
    cp      r8,r22
    breq    End_Loop_Add
   
    clr     r2
    ld      r1,x+   ; Load Y
    movw    r30,r18 ; Load X
    ld      r0,z+
    movw    r18,r30 ; Save updated Adr of X
    
    ; r1 = r0 + r1
    add     r1,r0
    adc     r2,r9
    
    ; r1 = r1 + carry
    add     r1,r24
    adc     r2,r9
    
    ; carry in r24
    mov     r24,r2
    andi    r24,1
    
    ; store r1
    movw    r30,r16
    st      z+,r1
    movw    r16,r30
    
    inc     r8
    jmp     Begin_Loop_Add


End_Loop_Add:
	
    ; r16 = last carry
    mov     r16,r24

   
    ret
    
    
    
; LlZpBase_Sub_C
; LlZpBase_Sub_ASM
;
; R = X - Y
;
; pu1R can be equal to pu1X
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
; Return:
;       R24 =
;             0x00    if X > Y => result positive
;             0xFF    if Y < X => result negative => ERROR
;
; Length:
;       XLength - YLength -> XLength 
;
; Perf:
; u2XLength			Nb. cycles
;	0x18			644
;	0x30			1220
;
LlZpBase_Sub_C:
    ; Save non-scratch registers
	push	r2
	push	r3
    push    r8
    push    r9
	push    r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	rcall	LlZpBase_Sub

	; IAR-style return value in R16
	mov		r24,r16

	; Convention (r1=0)
	clr		r1

    ; Registers restoration
	pop		r17
	pop		r16
    pop     r9
    pop     r8
	pop		r3
	pop		r2

	ret
    
LlZpBase_Sub_ASM:
	push	r2
	push	r3
    push    r8
    push    r9

	rcall	LlZpBase_Sub

    pop     r9
    pop     r8
	pop		r3
	pop		r2
	ret

LlZpBase_Sub:    
    ; r8 = counter
    clr     r8
    
    ; r24 = carry = 0
    clr     r24
    
    ; r9 = zero register
    clr     r9
    
    
    movw    r26,r18

Begin_Loop_Sub:
    cp      r8,r22
    breq    End_Loop_Sub
    clr     r3
    
    ; r1 = y[i]
    movw    r30,r20
    ld      r1,z+
    movw    r20,r30
    
    ; r0 = x[i]
    ld      r0,x+
    
    ; r2 = r0-r1
    mov     r2,r0
    sub     r2,r1
    sbc     r3,r9
    
    ; r2 = r2-carry
    sub     r2,r24
    sbc     r3,r9
    
    ; carry in r24
    mov     r24,r3
    andi    r24,1
    
    
    ; store r2
    movw    r30,r16
    st      z+,r2
    movw    r16,r30

    inc     r8
    jmp     Begin_Loop_Sub

End_Loop_Sub:

    clr     r16
    
    tst     r24
    breq    End_Sub
    subi    r16,0x01

End_Sub:
    ret
    

; LlZpBase_Mul_2d_C
; LlZpBase_Mul_2d_ASM
;
; R = X*2^B
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the parameter X
;         in R22-R23
;       u2B  : Integer B
;         in R20-R21
;       u2XLength : Length in bytes of X
;         in R18-R17
;  
; Perf:
; u2XLength			Nb. cycles		u2B
;	0x18			1829			7
;	0x18			493				8
;	0x18			685				9
;	0x18			877				10
;
LlZpBase_Mul_2d_C:
	; Save non-scratch registers
	push	r2
	push	r3
    push    r14
    push    r15
	push    r16
	push	r17

	; IAR-style arguments
	movw	r16,r24
	movw	r2,r18
	movw	r18,r22
	movw	r22,r2

	rcall 	LlZpBase_Mul_2d
	
	; Convention (r1=0)
	clr		r1

    ; Registers restoration
	pop		r17
	pop     r16
    pop     r15
    pop     r14
    pop     r3
    pop     r2

	ret

LlZpBase_Mul_2d_ASM:
	push	r2
	push	r3
    push    r14
    push    r15

	rcall	LlZpBase_Mul_2d
	
	pop     r15
    pop     r14
    pop     r3
    pop     r2

	ret

LlZpBase_Mul_2d:

	; r14 = B div 8
    mov     r14,r20
    lsr     r14      
    lsr     r14
    lsr     r14
    
    ; r15 = B mod 8
    ldi     r24,0x07
    and     r24,r20
    mov     r15,r24
    
    ; PtrZ = pu1R
    movw    r30,r16
    
    ; PtrX = pu1X
    movw    r26,r18
    
    ; r0 = counter
    clr     r0
    
    clr     r3
    
    
    ; Put (B div 8) byte at zero in the result
Begin_Zero_Byte:  
    cp      r0,r14
    breq    End_Zero_Byte
    
    st      z+,r3

    inc     r0
    jmp     Begin_Zero_Byte
    
End_Zero_Byte:    
    
    clr     r0
    
    ; carry between bytes
    clr     r24
    
    ; Loop on the bytes of X
Begin_Loop_Byte:
    cp      r0,r22
    breq    End_Loop_Byte
    
    ld      r2,x+
    
    clr     r3
    clr     r1
    ; Loop on (B mod 8)
Begin_Loop_Bit:
    cp      r1,r15
    breq    End_Loop_Bit
    
    ; Left shift r2
    lsl     r2
    ; Get the carry in r3
    rol     r3
    
    inc     r1
    jmp     Begin_Loop_Bit
End_Loop_Bit:
    
    ; add carry of the previous byte
    add     r2,r24
    
    ; store the result
    st      z+,r2
    
    ; put the carry for the next byte
    mov     r24,r3
    
    inc     r0
    jmp     Begin_Loop_Byte

End_Loop_Byte:

    ; store the carry
    st      z+,r24


    ret


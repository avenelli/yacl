#include <avr/io.h>

    .global LlComba_Mult_C
    .global LlComba_Mult_Low
    .global LlComba_Mult_High
    .global LlComba_Mult_One_Byte_C
    .global LlComba_Square_C


  
;
; LlComba_Mult_One_Byte_C
;
; R = X * OneByte
; 
; Input parameters:
;       pucR  : Adress of the result
;         in R24-R25
;       pucX  : Adress of the first parameter
;         in R22-R23
;       usOneByte : Value of the byte
;         in R20-R21
;       usLengthX : Length in bytes of X
;         in R18-R19
;
; Modified registers:
;   r0...r7  r26-r27 r30-r31
; Unmodified registers:
;   r8 ... r15

LlComba_Mult_One_Byte_C:
    // Save non-scratch registers
    //----------------
	push	r2
	push	r3
    push    r4
    push    r5
    push    r6
    push    r7

    
    ; r6 = Registre à zéro constant
    clr     r6
    
    ; Z = Adr X 
    movw    r30,r22 
    
    ; X = Adr R
    movw    r26,r24
    
    clr     r7
    
    ; COMBA_CLEAR
    clr     r3
    clr     r4
    clr     r5
    
Begin_Loop_Up_One_Byte:    
    
    cp      r7,r18
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

	// Convention (r1=0)
	clr		r1
    
    // Registers restoration
    //---------------------------
    pop     r7
    pop     r6
    pop     r5
    pop     r4
	pop		r3
	pop		r2
    
    ret



;
; LlComba_Mult_Low
;
; NOT CALLABLE FROM C
;
;   Computes the NbBytes LSB bytes of the multiplication X*Y
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2LengthX : Length in bytes of X
;         in R18-R19
;       u2NbBytes : Number of bytes needed in the result
;         in R16-R17
;
;   !!! XLength = YLength !!! (pad with zeros if necessary)
;
;   !!! 0 < NbBytes < 2*XLength !!!
;
LlComba_Mult_Low:
    // Save non-scratch registers
    //----------------
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
    
    movw    r10,r16 ; r10 = u2NbBytes
	movw	r16,r24
	movw	r12,r18
	movw	r18,r22
	movw	r22,r12
    
    ; r5 = Registre à zéro constant
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
    
    ; X = 1er argument
    movw    r26,r18
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    ; Avance le pointeur sur le 2e argument
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Low
    

End_Loop_Up_Low:

    ; pointeur sur le 2e argument avancé un coup de trop
    sbiw    r24,0x01
    
    ; Compteur de boucle = Taille de Y moins 1
    mov     r20,r22
    
    ; Taille de Y moins 1
    dec     r20
    
    
    
    
Begin_Loop_Down_Low:
    cp      r20,r4
    breq    End_Loop_Down_Low

    ; X = 1er argument
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    dec     r20
    
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    
	// Convention (r1=0)
	clr		r1

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


;
; LlComba_Mult_High
;
; NOT CALLABLE FROM C
;
;   Computes the NbBytes MSB bytes of the multiplication X*Y
;   Pre-computes 2 more column than the NbBytes asked for a more accurate result
;
;   !!! pucR needs XLength+2 bytes !!!
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2LengthX : Length in bytes of X
;         in R18-R19
;       u2NbBytes : Number of bytes needed in the result
;         in R16-R17
;
;   !!! XLength = YLength !!! (pad with zeros if necessary)
;
;       1 <= NbBytes <= 2*XLength - 2
;
LlComba_Mult_High:
    // Save non-scratch registers
    //----------------
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
    
    movw    r14,r16 ; r14 = u2NbBytes
	movw	r16,r24
	movw	r12,r18
	movw	r18,r22
	movw	r22,r12

    
    ; r5 = Registre à zéro constant
    clr     r5
    
    ; Adr X in r10-11
    movw    r10,r18
    
    ; Save Adr R in r12-r13
    movw    r12,r16
    
    ; Adr Y in r24-r25
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
    lsl     r20      ; r20 = 2*XLength
    sub     r20,r14  ; r20 = 2*XLength - NbBytes
    
    add     r24,r20
    adc     r25,r5 ; Adr Y + r20
    

    
Begin_Loop_Up_Digs_High:    
    
    cp      r20,r22
    brsh    End_Loop_Up_Digs_High
    
    ; X = 1er argument
    movw    r26,r18
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    ; Avance le pointeur sur le 2e argument
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Digs_High
    

End_Loop_Up_Digs_High:

    ; pointeur sur le 2e argument avancé un coup de trop
    sbiw    r24,0x01
    
    ; Compteur de boucle = Taille de Y moins 1
    mov     r20,r22
    
    ; Taille de Y moins 1
    dec     r20



Begin_Loop_Down_Digs_High:
    cp      r20,r4
    breq    End_Loop_Down_Digs_High

    ; X = 1er argument
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26

    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    dec     r20
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    
    ; right shift of 2 bytes of the result
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
    
	// Convention (r1=0)
	clr		r1

    // Registers restoration
    //---------------------------
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

/*

; LlComba_Square_C
;
; R = X^2
;
; Input parameters:
;       pucR  : Adress of the result
;         in R16-R17
;       pucX  : Adress of the first parameter
;         in R18-R19
;       usLengthX : Length in bytes of X
;         in R20-R21

LlComba_Square_C:
    // Save non-scratch registers
    //----------------
    st       -y,r4
    st       -y,r5
    st       -y,r6
    st       -y,r7
    st       -y,r8
    st       -y,r9
    st       -y,r10
    st       -y,r11
    st       -y,r12
    st       -y,r13
    st       -y,r14
    st       -y,r15
    st       -y,r24
    st       -y,r25
    st       -y,r26
    st       -y,r27
    
    ; r5 = Registre à zéro constant
    clr     r5
    
    ; Adr X in r24-r25
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
    
    
    ;----------
    ; 1er tour
    ;----------
    
    ; X = 1er argument
    movw    r26,r18
    
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r20 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r23,r22
    lsr     r23
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    

    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    ; Avance le pointeur sur le 2e argument
    adiw    r24,0x01
    
    
    ;-------------------------------
    ; Debut de la boucle ascendante
    ;-------------------------------
    
Begin_Loop_Up_Sqr:    
    
    cp      r22,r20
    breq    End_Loop_Up_Sqr
    
    ; X = 1er argument
    movw    r26,r18
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r20 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r23,r22
    dec     r23
    ; divise par 2 car dans le square on a 2x moins de chemin a faire (en descendant dans la colonne)
    lsr     r23 
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    

    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
    add     r30,r0
    adc     r31,r5
    
    ; registres d'accumulation internes a la 'boucle' dans l'eicall
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    ; x2 l'accumulation
    add     r6,r6
    adc     r7,r7
    adc     r8,r8
    
    ; ajoute la carry du tour d'avant
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

    ; test si on traite une colonne d'indice pair pour impair
    ; si pair on a un element diagonal a calculer, sinon non
    ; cad: X0*X0, X1*X1, ...
    mov     r13,r22
    and     r13,r12
    tst     r13
    brne    Test_Odd

    ; pair
    
    ; r13=indice du byte diagonal = cpt/2
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
    
    ; Avance le pointeur sur le 2e argument
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up_Sqr
    

End_Loop_Up_Sqr:

    
    ; pointeur sur le 2e argument avancé un coup de trop
    sbiw    r24,0x01
    
    
    ; Compteur de boucle = Taille de Y moins 1
    mov     r22,r20
    
    ; Taille de Y moins 2 (car dernier tour a part)
    dec     r22
    dec     r22
    
    ;-------------------------------
    ; Debut de la boucle descendante
    ;-------------------------------
    
Begin_Loop_Down_Sqr:
    tst     r22
    breq    End_Loop_Down_Sqr

    ; X = 1er argument
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r23,r22
    dec     r23
    ; divise par 2 car dans le square on a 2x moins de chemin a faire (en descendant dans la colonne)
    lsr     r23 
    mov     r0,r23
    lsl     r0
    add     r0,r23    
    
    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
    add     r30,r0
    adc     r31,r5
    
    ; registres d'accumulation internes a la 'boucle' dans l'eicall
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    
    ; x2 l'accumulation
    add     r6,r6
    adc     r7,r7
    adc     r8,r8
    
    ; ajoute la carry du tour d'avant
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

    
    ; test si on traite une colonne d'indice pair pour impair
    ; si pair on a un element diagonal a calculer, sinon non
    ; cad: X0*X0, X1*X1, ...
    mov     r13,r22
    and     r13,r12
    tst     r13
    brne    Test_Odd2

    ; pair
    
    ; r13=indice du byte diagonal = cpt/2
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


    ;---------------------
    ; Dernier tour a part
    ;---------------------


    ; X = 1er argument
    movw    r26,r18
    adiw    r26,0x01
    movw    r18,r26
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))   
    
    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
    clr     r0
    add     r30,r0
    adc     r31,r5
    
    clr     r6
    clr     r7
    clr     r8
    
    eicall
    
    // add carry
    add     r6,r9
    adc     r7,r10
    adc     r8,r11

    ; COMBA_STORE_FIN
    movw    r26,r16
    st      x+,r6
    st      x+,r7
    
    // Registers restoration
    //---------------------------
    ld       r27,y+
    ld       r26,y+
    ld       r25,y+
    ld       r24,y+
    ld       r15,y+
    ld       r14,y+
    ld       r13,y+
    ld       r12,y+
    ld       r11,y+
    ld       r10,y+
    ld       r9,y+
    ld       r8,y+
    ld       r7,y+
    ld       r6,y+
    ld       r5,y+
    ld       r4,y+
    
    ret

*/
    
; LlComba_Mult_C
;
; Comba multiplication of Z=X*Y
; LIMITE : 560*560 bits = 0x46*0x46 byte
;
; Input parameters:
;       pu1R  : Adress of the result
;         in R24-R25
;       pu1X  : Adress of the first parameter
;         in R22-R23
;       pu1Y  : Adress of the second parameter
;         in R20-R21
;       u2LengthX : Length in bytes of X
;         in R18-R19
;
;   !!! XLength = YLength !!! (pad with zeros if necessary)
;
; Length:
;       XLength * XLength -> 2*XLength
;
LlComba_Mult_C:
    // Save non-scratch registers
    //----------------
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
    
    ; r5 = Registre à zéro constant
    clr     r5

	; Save pu1R in R16-R17
	movw	r16,r24
    
    ; Adr Y in r24-r25
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
    
    cp      r20,r18
    breq    End_Loop_Up
    
    ; X = 1er argument
    movw    r26,r22
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    mov     r0,r20
    lsl     r0
    add     r0,r20    

    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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
    
    ; Avance le pointeur sur le 2e argument
    adiw    r24,0x01
    
    jmp     Begin_Loop_Up
    

End_Loop_Up:
    ; pointeur sur le 2e argument avancé un coup de trop
    sbiw    r24,0x01
    
    ; Compteur de boucle = Taille de Y moins 1
    mov     r20,r18
    
    ; Taille de Y moins 1
    dec     r20
    
    
    
    
Begin_Loop_Down:
    tst     r20
    breq    End_Loop_Down

    ; X = 1er argument
    movw    r26,r22
    adiw    r26,0x01
    movw    r22,r26
    
    ; Z = addr(JmpTable)
    ldi     r30,lo8(pm(JmpTableComba))
    ldi     r31,hi8(pm(JmpTableComba))
    
    ; r0 = 3*r24 = 3*compteur de boucle
    ; 3 = Taille de movw+jmp / 2 dans la JmpTableComba
    dec     r20
    mov     r0,r20
    lsl     r0
    add     r0,r20    
    inc     r20
    
    ; Z = Z+r0 = addr(JmpTable)+3*compteur de boucle
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

	// Convention (r1=0)
	clr		r1
    
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
      

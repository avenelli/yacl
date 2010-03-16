/*
Glitch.s

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

.global Glitch
.global Glitch_End


; Glitch
; Set PORTA = 0x00
; (by default PORTA = 0xFF)
Glitch:
    clr   r17
    out   PORTA,r17
    ret

; Glitch_Fin
; Set PORTA = 0xFF
Glitch_End:
    ser   r17
    out   PORTA,r17
    ret

; Chenille
; Connect PORTA to LEDS and enjoy ;-)
DLY:
    dec   r17
    brne  DLY
    dec   r18
    brne  DLY   
    ret
    
Chenille:
    clr   r23
    clr   r1
    ser   r16
    ; light off all LEDs
    out   DDRA,r16
    out   PORTA,r16
    
    ser   r25 ; Mask1 = 0xFF
    
Loop1:    
    ldi   r24,0x7F ; Mask2
    ldi   r27,0x07
Loop2:
    mov   r1,r24
    and   r1,r25
    com   r1
    out   PORTA,r1
    com   r1
    call  DLY
    
    lsr   r24
    ori   r24,0x80
    
    cp    r27,r23
    breq  End_Loop2
    dec   r27
    rjmp  Loop2
End_Loop2:

    lsl   r25
    cpi   r23,0x07
    breq  End_Loop1
    inc   r23
    rjmp  Loop1
    
End_Loop1:

    ser   r25
    out   PORTA,r25
    call  DLY    
    com   r25
    out   PORTA,r25
    call  DLY    
    com   r25
    out   PORTA,r25
    call  DLY    
    com   r25
    out   PORTA,r25
    call  DLY    
    com   r25
    out   PORTA,r25
    call  DLY  

    jmp   Chenille
    
    ret
    

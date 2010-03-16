/*
main.c

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
#include "globvars.h"
#include "com.h"


void main(void)
{ 
	// make sure PORTA and PORTB are set to 0xFF
	// usefull with the Glitch/Glitch_End assembly routines
	// in order to record the beginning and the end of a function
  	DDRA = 0xFF;
  	PORTA = 0xFF;
  
  	DDRB = 0xFF;
  	PORTB = 0xFF;
    
  	// Init USART at 9600 bps
  	USARTInit(UBBR_DS_9600); 
   
  	MainDispatcher();
}

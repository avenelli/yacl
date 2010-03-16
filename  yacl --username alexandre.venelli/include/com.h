/*
com.h

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
#ifndef _COM_H
#define _COM_H

// For Asynchronous Double Speed mode
// Clock: 1 Mhz
// Baud Rate = 9600 bps => UBBR = 12 
// Clock: 8 Mhz
// Baud Rate = 9600 bps => UBBR = 103 
// Clock: 16 Mhz
// Baud Rate = 9600 bps => UBBR = 207
#define UBBR_DS_2400  832
#define UBBR_DS_4800  416
#define UBBR_DS_9600  103



// Length of the header TAG|DATA|LEN
// 2 bytes = TAG
// 2 bytes = DATA
// 1 byte  = LENGTH
#define HEADERSIZE 5

// Length of the status command returned to the PC
#define STATUSSIZE 2

#define  u1GetCLASS()   u1CLASS
#define  u1GetINS()     u1INS
#define  u1GetP1()      u1P1
#define  u1GetP2()      u1P2
#define  u1GetP3()      u1P3

#define SW_UNKNOWN_INS           0x6D,0x00 // Unknown instruction
#define SW_COMMUNICATION_ERROR   0x65,0xFF // Communication error
#define SW_OK                    0x90,0x00 // End of command


extern void USARTInit(uint16_t);
extern void MainDispatcher(void);

#endif

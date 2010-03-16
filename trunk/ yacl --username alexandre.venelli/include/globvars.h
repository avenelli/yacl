/*
globvars.h

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
#ifndef _GLOBVARS_H
#define _GLOBVARS_H
typedef signed          char      int8_t;
typedef unsigned        char      uint8_t;
typedef signed          short     short_t;
typedef unsigned        short     ushort_t;
typedef signed          int       int16_t;
typedef unsigned        int       uint16_t;
typedef signed    long  int       int32_t;
typedef unsigned  long  int       uint32_t;
typedef signed    long  long int  int64_t;
typedef unsigned  long  long int  uint64_t;


#define MAX_BUFFER_SIZE 256

#define OK  0x00
#define NOK 0xFF


// CLASS not used (for now)

// INS values
#define INS_READRAM   0x10
#define INS_WRITERAM  0x12
#define INS_COMMAND   0x14


// COMMAND values
#define CMD_NULL      0x00
#define CMD_ZPADD     0x01
#define CMD_ZPSUB     0x02
#define CMD_ZPMUL2D   0x03
#define CMD_COPYPAD   0x04
#define CMD_FILL      0x05
#define CMD_SETBYTE   0x06
#define CMD_ZPMULT    0x07
#define CMD_ZPMULT1B  0x08
#define CMD_ZPREDMOD  0x09
#define CMD_ZPINVMOD  0x0A
#define CMD_ZPECADD   0x0B
#define CMD_ZPECDBL   0x0C
#define CMD_ZPSQUARE  0x0D
#define CMD_DESENC	  0x0E
#define CMD_DESDEC	  0x0F

typedef void *pvoid;


#endif

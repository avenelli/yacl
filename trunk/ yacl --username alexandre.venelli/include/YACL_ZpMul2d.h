/*
YACL_ZpMul2d.h

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
#ifndef _YACL_ZPMUL2D_H
#define _YACL_ZPMUL2D_H

typedef struct {
      uint8_t   *pu1Result;
      uint8_t   *pu1ParamX;
      
      ushort_t   u2ExpB;
      ushort_t   u2XLength;
} YACL_ZP_MUL2D_S, *P_YACL_ZP_MUL2D_S;

extern void YACL_ZpMul2d(pvoid);

#endif

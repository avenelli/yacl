/*
LlZpBase.h

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
#ifndef _LLZPBASE_INCLUDED
#define _LLZPBASE_INCLUDED

extern uint8_t LlZpBase_Sub_C(uint8_t*,
                                  uint8_t*,
                                  uint8_t*,
                                  ushort_t);

extern uint8_t LlZpBase_Add_C(uint8_t*,
                                  uint8_t*,
                                  uint8_t*,
                                  ushort_t);

extern uint8_t LlZpBase_Mul_2d_C(uint8_t*,
                                  uint8_t*,
                                  ushort_t,
                                  ushort_t);

extern uint8_t LlZpBase_InvMod_C(uint8_t*,
                          uint8_t*,
                          uint8_t*,
                          ushort_t);

#endif

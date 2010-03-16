/*
LlComba.h

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
#ifndef _LLCOMBA_INCLUDED
#define _LLCOMBA_INCLUDED

extern uint8_t LlComba_Mult_C(uint8_t *,
                                    uint8_t *,
                                    uint8_t *,
                                    ushort_t);

extern uint8_t LlComba_Mult_One_Byte_C(uint8_t *,
                                    uint8_t *,
                                    ushort_t,
                                    ushort_t);

extern uint8_t LlComba_Square_C(uint8_t *,
                                    uint8_t *,
                                    ushort_t);

#endif

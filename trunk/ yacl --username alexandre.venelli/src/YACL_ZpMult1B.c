/*
YACL_ZpMult1B.c

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
#include "globvars.h"
#include "YACL_Headers.h"
#include "LlComba.h"


extern void YACL_ZpMult1B(DEF_PARAM)
{
  LlComba_Mult_One_Byte_C(YACL_ZPMULT1B(pu1Result),
                          YACL_ZPMULT1B(pu1ParamX),
                          YACL_ZPMULT1B(u2OneByte),
                          YACL_ZPMULT1B(u2XLength));
  return;
}

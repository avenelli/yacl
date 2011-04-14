/*
YACL_ZpRedMod.c

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
#include "LlBarrett.h"


extern void YACL_ZpRedMod(DEF_PARAM)
{
  LlBarrett_Reduce_C(YACL_ZPREDMOD(pu1Result),
                 	YACL_ZPREDMOD(pu1ParamX),
                 	YACL_ZPREDMOD(pu1ModBase),
                 	YACL_ZPREDMOD(pu1Cns),
                 	YACL_ZPREDMOD(pu1Quotient),
                 	YACL_ZPREDMOD(u2ModLength));
  return;
}
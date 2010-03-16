/*
YACL_ZpEccDbl.c

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
#include "LlZpEccBase.h"


extern void YACL_ZpEccDbl(DEF_PARAM)
{
  LlZpEccDbl_C(YACL_ZPECCDBL(pu1PointToBeDoubled),
               YACL_ZPECCDBL(u2ModLength),
               YACL_ZPECCDBL(pu1ModBase),
               YACL_ZPECCDBL(pu1Cns),
               YACL_ZPECCDBL(pu1Workspace),
               YACL_ZPECCDBL(pu1AParameterBase));
  return;
}

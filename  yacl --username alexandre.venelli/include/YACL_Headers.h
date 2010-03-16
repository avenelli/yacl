/*
YACL_Headers.h

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
#ifndef _YACL_HEADERS_H
#define _YACL_HEADERS_H

#include "YACL_ZpAdd.h"
#include "YACL_ZpSub.h"
#include "YACL_ZpMul2d.h"
#include "YACL_CopyPad.h"
#include "YACL_Fill.h"
#include "YACL_SetByte.h"
#include "YACL_ZpMult.h"
#include "YACL_ZpSquare.h"
#include "YACL_ZpMult1B.h"
#include "YACL_ZpRedMod.h"
#include "YACL_ZpInvMod.h"
#include "YACL_ZpEccAdd.h"
#include "YACL_ZpEccDbl.h"

typedef struct _yacl_param_s {
  union{
    YACL_ZP_ADD_S       YACL_ZpAdd;
    YACL_ZP_SUB_S       YACL_ZpSub;
    YACL_ZP_MUL2D_S     YACL_ZpMul2d;
    YACL_COPYPAD_S      YACL_CopyPad;
    YACL_FILL_S         YACL_Fill;
    YACL_SETBYTE_S      YACL_SetByte;
    YACL_ZP_MULT_S      YACL_ZpMult;
    YACL_ZP_SQUARE_S    YACL_ZpSquare;
    YACL_ZP_MULT1B_S    YACL_ZpMult1B;
    YACL_ZP_REDMOD_S    YACL_ZpRedMod;
    YACL_ZP_INVMOD_S    YACL_ZpInvMod;
    YACL_ZP_ECCADD_S    YACL_ZpEccAdd;
    YACL_ZP_ECCDBL_S    YACL_ZpEccDbl;
  }S;
} YACL_PARAM_S, *P_YACL_PARAM_S;

#define DEF_PARAM pvoid pYACLParam
#define USE_PARAM (P_YACL_PARAM_S)pYACLParam

#define YACL_ZPADD(a)     (USE_PARAM)->S.YACL_ZpAdd.a
#define YACL_ZPSUB(a)     (USE_PARAM)->S.YACL_ZpSub.a
#define YACL_ZPMUL2D(a)   (USE_PARAM)->S.YACL_ZpMul2d.a
#define YACL_COPYPAD(a)   (USE_PARAM)->S.YACL_CopyPad.a
#define YACL_FILL(a)      (USE_PARAM)->S.YACL_Fill.a
#define YACL_SETBYTE(a)   (USE_PARAM)->S.YACL_SetByte.a
#define YACL_ZPMULT(a)    (USE_PARAM)->S.YACL_ZpMult.a
#define YACL_ZPSQUARE(a)  (USE_PARAM)->S.YACL_ZpSquare.a
#define YACL_ZPMULT1B(a)  (USE_PARAM)->S.YACL_ZpMult1B.a
#define YACL_ZPREDMOD(a)  (USE_PARAM)->S.YACL_ZpRedMod.a
#define YACL_ZPINVMOD(a)  (USE_PARAM)->S.YACL_ZpInvMod.a
#define YACL_ZPECCADD(a)  (USE_PARAM)->S.YACL_ZpEccAdd.a
#define YACL_ZPECCDBL(a)  (USE_PARAM)->S.YACL_ZpEccDbl.a

#endif

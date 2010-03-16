#ifndef _LIBAVR_ZPECCCONV_H
#define _LIBAVR_ZPECCCONV_H

typedef struct {
      uint8_t   *pucPointABase;
      
      ushort_t  usModLength;
      uint8_t   *pucModBase;
      uint8_t   *pucCns;
      uint8_t   *pucWorkspace;
      
} LIBAVR_ZP_ECCCONV_S, *P_LIBAVR_ZP_ECCCONV_S;

extern void LibAVR_ZpEccConvProjToAff(pvoid);
extern void LibAVR_ZpEccConvAffToProj(pvoid);
extern void LibAVR_ZpEccConvRandCoord(pvoid);

#endif

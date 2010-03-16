import sercom
reload(sercom)
import os
from globvars import *
from utils.base import *
from numpy import *
from ParseValuesFile import *
from arith.invmod import *
import logging
import glob

logging.basicConfig(
    filename=os.path.join(DIRLOG,"Test_ZpEccDbl.log"),
    format="%(levelname)-10s %(asctime)s %(message)s",
    level=logging.DEBUG)


# Open RS232 connection
ClassCom = sercom.SERCom()

ValFiles = glob.glob(os.path.join(DIRVAL,"Test_ZpEccDbl*.val"))

for f in ValFiles:
    # Parse values file
    ListStruct = ParseValuesFile(f,"EccDbl")

    logging.info("ECCDBL C = 2*A - %s" % f)
    NbOK = 0
    Idx=1
    # Launch Test : PointA = 2*PointA
    for e in ListStruct:
        
        AdrA    = ADRBASE
        AdrCns  = ClassCom.WriteECCPoint(AdrA,e.PointA)
        AdrMod  = ClassCom.WriteData(AdrCns,e.Cns)
        AdrParamA = ClassCom.WriteData(AdrMod,e.ModBase)
        AdrWork = ClassCom.WriteData(AdrParamA,e.ParamA)
        LaunchZpEccDbl = [0x01,ClassCom.INS_COMMAND,ClassCom.CMD_ZPECDBL,0x00,0x0C]+AdrA+[e.LengthBytes,0x00]+AdrMod+AdrCns+AdrWork+AdrParamA
        ClassCom.SERSend(LaunchZpEccDbl)

        
        LaunchRead = [0x01,ClassCom.INS_READRAM]+AdrA+[3*(e.LengthBytes+4)]
        RecvResult,SW = ClassCom.SERSend(LaunchRead)
        
        
        RecvResultZ = RecvResult[:e.LengthBytes+4]
        RecvResultY = RecvResult[e.LengthBytes+4:2*(e.LengthBytes+4)]
        RecvResultX = RecvResult[2*(e.LengthBytes+4):]
        
        p = ListToInt(e.ModBase) 
        InvZProj = invmod(p,ListToInt(RecvResultZ))
        InvZProj2 = (InvZProj*InvZProj) % p
        InvZProj3 = (InvZProj2*InvZProj) % p
        
        XAff = (ListToInt(RecvResultX) * InvZProj2) % p
        YAff = (ListToInt(RecvResultY) * InvZProj3) % p
        
        ListXAff = intToList(XAff,e.LengthBytes+4)
        ListYAff = intToList(YAff,e.LengthBytes+4)
        ListZAff = intToList(1,e.LengthBytes+4)

        if ListXAff == e.TrueRes[0] and ListYAff == e.TrueRes[1] and ListZAff == e.TrueRes[2]:
            logging.info("%d - OK" % Idx)
            NbOK = NbOK + 1
        else:
            logging.error("%d - ERROR\nRecvX = %s\nTrueX = %s\nRecvY = %s\nTrueY = %s\nRecvZ = %s\nTrueZ = %s"
                          % (Idx,toHexString(ListXAff,2),toHexString(e.TrueRes[0],2),
                             toHexString(ListYAff,2),toHexString(e.TrueRes[1],2),
                             toHexString(ListZAff,2),toHexString(e.TrueRes[2],2),))
        Idx = Idx + 1
    logging.info("%d / %d OK" % (NbOK,len(ListStruct)))

ClassCom.close()

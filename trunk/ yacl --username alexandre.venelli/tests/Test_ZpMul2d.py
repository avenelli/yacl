import sercom
reload(sercom)
import os
from globvars import *
from utils.base import *
from numpy import *
from ParseValuesFile import *
import logging
import glob

logging.basicConfig(
    filename=os.path.join(DIRLOG,"Test_ZpMul2d.log"),
    format="%(levelname)-10s %(asctime)s %(message)s",
    level=logging.DEBUG)

# Open RS232 connection
ClassCom = sercom.SERCom()

ValFiles = glob.glob(os.path.join(DIRVAL,"Test_ZpMul2d*.val"))

for f in ValFiles:
    # Parse values file
    ListStruct = ParseValuesFile(f,"Mul2d")

    logging.info("ZPMUL2D C = A*2^B - %s" % f)
    NbOK = 0
    Idx = 1
    # Launch Test : C = A*2^B
    for e in ListStruct:

        AdrA = ADRBASE
        AdrC = ClassCom.WriteData(AdrA,e.A)
        LaunchMul2d = [0x01,ClassCom.INS_COMMAND,ClassCom.CMD_ZPMUL2D,0x00,0x08]+AdrC+AdrA+[ListToInt(e.B),0x00]+[len(e.A),0x00]
        ClassCom.SERSend(LaunchMul2d)
        
        LaunchRead = [0x01,ClassCom.INS_READRAM]+AdrC+[int((ListToInt(e.B))/8.0)+e.LengthBytes+4]
        RecvResult,SW = ClassCom.SERSend(LaunchRead)
        
        if RecvResult == e.TrueRes:
            logging.info("%d - OK" % Idx)
            NbOK = NbOK + 1
        else:
            logging.error("%d - ERROR\nRecv = %s\nTrue = %s" % (Idx,toHexString(RecvResult,2),toHexString(e.TrueRes,2)))

        Idx = Idx + 1
    logging.info("%d / %d OK" % (NbOK,len(ListStruct)))

ClassCom.close()

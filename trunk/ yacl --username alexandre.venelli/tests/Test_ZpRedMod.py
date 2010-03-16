import sercom
reload(sercom)
import os
from globvars import *
from utils.base import intToList
from numpy import *
from ParseValuesFile import *
import logging
import glob

logging.basicConfig(
    filename=os.path.join(DIRLOG,"Test_ZpRedMod.log"),
    format="%(levelname)-10s %(asctime)s %(message)s",
    level=logging.DEBUG)


# Open RS232 connection
ClassCom = sercom.SERCom()

ValFiles = glob.glob(os.path.join(DIRVAL,"Test_ZpRedMod*.val"))

for f in ValFiles:
    # Parse values file
    ListStruct = ParseValuesFile(f,"RedMod")

    logging.info("ZPREDMOD C = A mod p - %s" % f)
    NbOK = 0
    Idx = 1
    # Launch Test : C = A mod p
    for e in ListStruct:

        AdrC = ADRBASE
        AdrA   = ClassCom.WriteData(AdrC,intToList(0,e.LengthBytes+4))
        AdrMod = ClassCom.WriteData(AdrA,e.A)
        AdrCns = ClassCom.WriteData(AdrMod,e.ModBase)
        AdrQuo = ClassCom.WriteData(AdrCns,e.Cns)
        
        LaunchRedMod = [0x01,ClassCom.INS_COMMAND,ClassCom.CMD_ZPREDMOD,0x00,0x0C]+AdrC+AdrA+AdrMod+AdrCns+AdrQuo+[e.LengthBytes,0x00]
        ClassCom.SERSend(LaunchRedMod)
        
        LaunchRead = [0x01,ClassCom.INS_READRAM]+AdrC+[e.LengthBytes+4]
        RecvResult,SW = ClassCom.SERSend(LaunchRead)
        
        if RecvResult == e.TrueRes:
            logging.info("%d - OK" % Idx)
            NbOK = NbOK + 1
        else:
            logging.error("%d - ERROR\nRecv = %s\nTrue = %s" % (Idx,toHexString(RecvResult,2),toHexString(e.TrueRes,2)))

        Idx = Idx + 1
    logging.info("%d / %d OK" % (NbOK,len(ListStruct)))

ClassCom.close()

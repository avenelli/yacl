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
    filename=os.path.join(DIRLOG,"Test_ZpSub.log"),
    format="%(levelname)-10s %(asctime)s %(message)s",
    level=logging.DEBUG)


# Open RS232 connection
ClassCom = sercom.SERCom()  

ValFiles = glob.glob(os.path.join(DIRVAL,"Test_ZpSub*.val"))

for f in ValFiles:
    # Parse values file
    ListStruct = ParseValuesFile(f,"Sub")

    logging.info("ZPSUB C = A-B - %s" % f)
    NbOK = 0
    Idx = 1
    # Launch Test : C = A-B
    for e in ListStruct:
        
        AdrA = ADRBASE
        AdrB = ClassCom.WriteData(AdrA,e.A)
        AdrC = ClassCom.WriteData(AdrB,e.B)
        LaunchSub = [0x01,ClassCom.INS_COMMAND,ClassCom.CMD_ZPSUB,0x00,0x08]+AdrC+AdrA+AdrB+[len(e.A),0x00]
        ClassCom.SERSend(LaunchSub)
        
        LaunchRead = [0x01,ClassCom.INS_READRAM]+AdrC+[len(e.A)]
        RecvResult,SW = ClassCom.SERSend(LaunchRead)
        
        if RecvResult == e.TrueRes:
            logging.info("%d - OK" % Idx)
            NbOK = NbOK + 1
        else:
            logging.error("%d - ERROR\nRecv = %s\nTrue = %s" % (Idx,toHexString(RecvResult,2),toHexString(e.TrueRes,2)))

        Idx = Idx + 1
    logging.info("%d / %d OK" % (NbOK,len(ListStruct)))

ClassCom.close()

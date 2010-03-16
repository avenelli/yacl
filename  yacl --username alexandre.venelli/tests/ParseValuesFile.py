from numpy import *
from utils.base import fromHex
from utils.base import intToList
from utils.base import toHexString
from utils.base import ListToInt
from time import gmtime, strftime


class structZpBase:
    def __init__(self):
        self.Label = ""
        self.LengthBytes = 0
        self.A = 0
        self.B = 0
        self.ModBase = 0
        self.Cns = 0
        self.TrueRes = 0
    
class structZpEcc:
    def __init__(self):
        self.Label = ""
        self.LengthBytes = 0
        self.PointA = []
        self.PointB = []
        self.ParamA = []
        self.ModBase = 0
        self.Cns = 0
        self.TrueRes =[]
        for i in xrange(3):
            self.PointA.append(0)
            self.PointB.append(0)
            self.TrueRes.append(0)
    def __str__(self):
        print "Label=",
        print self.Label
        print "LengthBytes=",
        print self.LengthBytes
        print "PointA=",
        print self.PointA
        print "PointB=",
        print self.PointB
        print "ParamA=",
        print self.ParamA
        print "ModBase=",
        print self.ModBase
        print "Cns=",
        print self.Cns
        print "TrueRes=",
        print self.TrueRes
        return ""

def FillMultStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B":
        struct.B = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),2*struct.LengthBytes+4)

def FillSquareStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),2*struct.LengthBytes+4)


def FillMul2dStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B":
        struct.B = intToList(fromHex(line[1]),2)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),int((ListToInt(struct.B)/8.0))+struct.LengthBytes+4)
        
def FillAddSubStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B":
        struct.B = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),struct.LengthBytes+4)
        
def FillRedModStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),2*struct.LengthBytes+4)
    elif line[0] == "ModBase":
        struct.ModBase = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "Cns":
        struct.Cns = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),struct.LengthBytes+4)

def FillInvModStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A":
        struct.A = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "ModBase":
        struct.ModBase = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes":
        struct.TrueRes = intToList(fromHex(line[1]),struct.LengthBytes+4)

def FillEccAddStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A_X":
        struct.PointA[0] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "A_Y":
        struct.PointA[1] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "A_Z":
        struct.PointA[2] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B_X":
        struct.PointB[0] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B_Y":
        struct.PointB[1] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "B_Z":
        struct.PointB[2] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "ModBase":
        struct.ModBase = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "Cns":
        struct.Cns = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_X":
        struct.TrueRes[0] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_Y":
        struct.TrueRes[1] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_Z":
        struct.TrueRes[2] = intToList(fromHex(line[1]),struct.LengthBytes+4)

def FillEccDblStruct(struct, line):
    if line[0] == "LengthBytes":
        struct.LengthBytes = fromHex(line[1])
    elif line[0] == "A_X":
        struct.PointA[0] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "A_Y":
        struct.PointA[1] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "A_Z":
        struct.PointA[2] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "ParamA":
        struct.ParamA = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "ModBase":
        struct.ModBase = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "Cns":
        struct.Cns = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_X":
        struct.TrueRes[0] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_Y":
        struct.TrueRes[1] = intToList(fromHex(line[1]),struct.LengthBytes+4)
    elif line[0] == "TrueRes_Z":
        struct.TrueRes[2] = intToList(fromHex(line[1]),struct.LengthBytes+4)
        
        
def ParseValuesFile(filename,operation):
    f = open(filename,"r")
    buf = f.readlines()
    f.close()

    ListStruct=[]
    sTemp = None
    cpt = 0
    while cpt < len(buf):
        line = buf[cpt]
        cpt += 1
        if (line[0] == '#'):
            if sTemp:
                ListStruct.append(sTemp)
            if (operation == "EccAdd") or (operation == "EccDbl"):
                sTemp = structZpEcc()
            else:
                sTemp = structZpBase()
            sTemp.Label = line[1:-1]
            while buf[cpt][0] == '#':
                cpt += 1
        else:
            line2 = line
            # If there is a '\' at the end of a line, read the next and concatenate
            while line2.strip()[-1] == '\\' and cpt < len(buf):
                # Read the next line
                line2 = buf[cpt]
                line = line[:-2] + line2
                cpt += 1

            ltemp = line.split("=")
            ltemp = [e.strip() for e in ltemp]
            
            if operation == "Mult":
                FillMultStruct(sTemp,ltemp)
            elif operation == "Add" or operation == "Sub":
                FillAddSubStruct(sTemp,ltemp)
            elif operation == "Mul2d":
                FillMul2dStruct(sTemp,ltemp)
            elif operation == "Square":
                FillSquareStruct(sTemp,ltemp)
            elif operation == "RedMod":
                FillRedModStruct(sTemp,ltemp)
            elif operation == "InvMod":
                FillInvModStruct(sTemp,ltemp)
            elif operation == "EccAdd":
                FillEccAddStruct(sTemp,ltemp)
            elif operation == "EccDbl":
                FillEccDblStruct(sTemp,ltemp)
            
    ListStruct.append(sTemp)
    return ListStruct

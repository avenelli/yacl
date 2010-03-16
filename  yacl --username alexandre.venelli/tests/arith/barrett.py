from math import *

def GenCns(NumberW, ModulusD, B=256):
    Cns = pow(B,2*NumberW)
    Cns = Cns/ModulusD
    Cns = floor(Cns)
    return int(Cns)
from numpy import *
PACK=1
HEX=2
UPPERCASE=4
COMMA=8

def digitChar(n):
    """return single character for digits with value 0 through 15
    emphasizing each conversion for 10, 11, ... 15"""
    if n < 10:
        return str(n)
    if n == 10:
        return 'A'
    if n == 11:
        return 'B'
    if n == 12:
        return 'C'
    if n == 13:
        return 'D'
    if n == 14:
        return 'E'
    if n == 15:
        return 'F'

def intToBase(i, base):
    """Return a string representing the nonnrgative integer i
    in the specified base, from 2 to 16."""
    i = int(i)  # if i is a string, convert to int
    if i == 0:
        return '0'
    numeral = ""
    while i != 0:
        digit = i % base
        numeral = digitChar(digit) + numeral  # add next digit on LEFT
        i = i/base
    return numeral

def intToList(i, length=0):
    base=256
    lnumeral = []
    while i != 0:
        digit = i%base
        lnumeral.append(digit)
        i = i/base
    l = len(lnumeral)
    if(length!=0):
        while(l<length):
            lnumeral.append(0)
            l = len(lnumeral)
    lnumeral.reverse()
    return lnumeral
    
def toHexString( bytes=[], format=1 ):
    """Returns an hex string representing bytes

        bytes:  a list of bytes to stringify, e.g. [59, 22, 148, 32, 2, 1, 0, 0, 13]
        format: a logical OR of
                COMMA: add a comma between bytes
                HEX: add the 0x chars before bytes
                UPPERCASE: use 0X before bytes (need HEX)
                PACK: remove blanks

        example:
        bytes = [ 0x3B, 0x65, 0x00, 0x00, 0x9C, 0x11, 0x01, 0x01, 0x03 ]

        toHexString( bytes ) returns  3B 65 00 00 9C 11 01 01 03

        toHexString( bytes, COMMA ) returns  3B, 65, 00, 00, 9C, 11, 01, 01, 03
        toHexString( bytes, HEX ) returns  0x3B 0x65 0x00 0x00 0x9C 0x11 0x01 0x01 0x03
        toHexString( bytes, HEX | COMMA ) returns  0x3B, 0x65, 0x00, 0x00, 0x9C, 0x11, 0x01, 0x01, 0x03

        toHexString( bytes, PACK ) returns  3B6500009C11010103

        toHexString( bytes, HEX | UPPERCASE ) returns  0X3B 0X65 0X00 0X00 0X9C 0X11 0X01 0X01 0X03
        toHexString( bytes, HEX | UPPERCASE | COMMA) returns  0X3B, 0X65, 0X00, 0X00, 0X9C, 0X11, 0X01, 0X01, 0X03
    """

    from string import rstrip

    for byte in tuple(bytes):
        pass

    if type(bytes) is not list:
        raise TypeError, 'not a list of bytes'

    if bytes==None or bytes==[]:
        return ""
    else:
        pformat="%-0.2X"
        if COMMA & format:
            pformat = pformat+","
        pformat = pformat+" "
        if PACK & format:
            pformat=rstrip( pformat )
        if HEX & format:
            if UPPERCASE & format:
                pformat = "0X"+pformat
            else:
                pformat = "0x"+pformat
        return rstrip(rstrip(reduce( lambda a, b: a+pformat % ((b+256)%256), [""] + bytes )),',')

def fromHex(HexString):
    Res = 0
    for Ch in HexString:
        if( Ch >= '0' and Ch <= '9' ):
            Res = Res*16 + ord(Ch) - ord('0')
        elif( Ch >= 'A' and Ch <= 'F' ):
            Res = Res*16 + 10 + ord(Ch) - ord('A')
        elif( Ch >= 'a' and Ch <= 'f' ):
            Res = Res*16 + 10 + ord(Ch) - ord('a')
    return Res

def ListToInt(list):
    return fromHex(toHexString(list,PACK))
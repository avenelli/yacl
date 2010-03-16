"""
sercom.py - serial communication protocol with board

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
"""

import time
import serial
import sys

# Print in the terminal the status word of each command 
DEBUG = False

class SERCom(serial.Serial):
    #------------------------------------
    # Class construction, initialisations
    # Default configuration should be ok
    #------------------------------------
    def __init__(self,port='COM1',baudrate=9600,
                 parity=serial.PARITY_NONE,
                 stopbits=serial.STOPBITS_ONE,
                 bytesize=serial.EIGHTBITS,
                 timeout=None,writeTimeout=None):

        serial.Serial.__init__(self,port=port,
                               baudrate=baudrate,
                               parity=parity,
                               stopbits=stopbits,
                               bytesize=bytesize,
                               timeout=timeout,
                               writeTimeout=writeTimeout)
        # Global 
        self.HEADERSIZE = 5
        self.STATUSSIZE = 2

        # Instruction
        self.INS_READRAM   = 0x10
        self.INS_WRITERAM  = 0x12
        self.INS_COMMAND   = 0x14

        # Command
        self.CMD_ZPADD     = 0x01
        self.CMD_ZPSUB     = 0x02
        self.CMD_ZPMUL2D   = 0x03
        self.CMD_COPYPAD   = 0x04
        self.CMD_FILL      = 0x05
        self.CMD_SETBYTE   = 0x06
        self.CMD_ZPMULT    = 0x07
        self.CMD_ZPMULT1B  = 0x08
        self.CMD_ZPREDMOD  = 0x09
        self.CMD_ZPINVMOD  = 0x0A
        self.CMD_ZPECADD   = 0x0B
        self.CMD_ZPECDBL   = 0x0C
        self.CMD_ZPSQUARE  = 0x0D

        # Status Word
        self.SW_UNKNOWN_INS         = [0x6D,0x00]
        self.SW_COMMUNICATION_ERROR = [0x65,0xFF]
        self.SW_OK                  = [0x90,0x00]



    #------------------------------------
    # IsINS(ins)
    # True if ins is a valid instruction
    # otherwise False
    #------------------------------------
    def IsINS(self,ins):
            if ins == self.INS_READRAM:
                    return True
            elif ins == self.INS_WRITERAM:
                    return True
            elif ins == self.INS_COMMAND:
                    return True
            else:
                    return False
                
    #-----------------------------
    # INSToString(ins)
    # Print a string decribing ins
    #-----------------------------
    def INSToString(self,ins):
        if(ins == self.INS_READRAM):
            print "INS: READRAM"
        elif(ins == self.INS_WRITERAM):
            print "INS: WRITERAM"
        elif(ins == self.INS_COMMAND):
            print "INS: COMMAND"

    #-----------------------------
    # CMDToString(cmd)
    # Print a string decribing cmd
    #-----------------------------
    def CMDToString(self,cmd):
        print ""
        if(cmd == self.CMD_ZPADD):
            print "CMD: ZPADD"
        elif(cmd == self.CMD_ZPSUB):
            print "CMD: ZPSUB"
        elif(cmd == self.CMD_ZPMUL2D):
            print "CMD: ZPMUL2D"
        elif(cmd == self.CMD_COPYPAD):
            print "CMD: COPYPAD"
        elif(cmd == self.CMD_FILL):
            print "CMD: FILL"
        elif(cmd == self.CMD_SETBYTE):
            print "CMD: SETBYTE"
        elif(cmd == self.CMD_ZPMULT):
            print "CMD: ZPMULT"
        elif(cmd == self.CMD_ZPMULT1B):
            print "CMD: ZPMUL1B"
        elif(cmd == self.CMD_ZPREDMOD):
            print "CMD: ZPREDMOD"
        elif(cmd == self.CMD_ZPINVMOD):
            print "CMD: ZPINVMOD"
        elif(cmd == self.CMD_ZPECADD):
            print "CMD: ZPECCADD"
        elif(cmd == self.CMD_ZPECDBL):
            print "CMD: ZPECCDBL"
        elif(cmd == self.CMD_ZPSQUARE):
            print "CMD: SQUARE"

    #------------------------------------------
    # SWToString(sw)
    # sw = list of 2 bytes
    #    = 2 bytes of return code
    # Print a string describing the status word
    #------------------------------------------
    def SWToString(self,sw):
            swint = [ord(sw[0]),ord(sw[1])]
            if(swint == self.SW_OK):
                    print "(SW: OK)"
            elif(swint == self.SW_UNKNOWN_INS):
                    print "(SW: Unknown Instruction)"
            elif(swint == self.SW_COMMUNICATION_ERROR):
                    print "(SW: Communication Error)"
            else:
                    print "(ERREUR Status Word Unknown = 0x%02x 0x%02x)" % (swint[0],swint[1])

    #--------------------------------------------------------------------
    # SERSend(CmdData,verbose=False)
    # CmdData = list of data to send to AVR
    # CmdData =
    #       [ CL | INS | P1 | P2 | P3 ]
    # or
    #       [ CL | INS | P1 | P2 | P3 | DATA ] with DATA of size P3 bytes
    #--------------------------------------------------------------------
    def SERSend(self,CmdData,verbose=False):
            INS = CmdData[1]
            CMD = CmdData[2]
            P3  = CmdData[4]
            
            if(P3 != 0):
                    if(INS == self.INS_READRAM):
                            if(DEBUG):
                                self.INSToString(INS)
                            return self.P3NotZeroReception(CmdData[:self.HEADERSIZE],verbose) 
                        
                    elif(INS == self.INS_WRITERAM):
                            if(DEBUG):
                                self.INSToString(INS)
                            return self.P3NotZeroEmission(CmdData[:self.HEADERSIZE],CmdData[self.HEADERSIZE:],verbose)

                    elif(INS == self.INS_COMMAND):
                            if(DEBUG):
                                self.CMDToString(CMD)
                            return self.P3NotZeroEmission(CmdData[:self.HEADERSIZE],CmdData[self.HEADERSIZE:],verbose)

                    else:
                            print "ERROR INS_UNKNOWN"
            else:
                    print "P3 = 0"

                    
    #--------------------------------------
    # P3NotZeroReception(Cmd,verbose=False)
    # P3 != 0
    # Receive data AVR -> PC
    # Cmd = list of size HEADERSIZE
    #--------------------------------------
    def P3NotZeroReception(self,Cmd,verbose=False):
            if verbose:
                    #print command
                    print "comd: ",
                    for c in Cmd: print "0x%02x" % ord(chr(c)),
                    print ""
                
            # send the command
            for s in Cmd:
                    self.write(chr(s))

            NbBytesNeeded = Cmd[-1] + 3 # P3 + 3
        
            out = ''
            First = True
            CptRec = 0
        
            while CptRec < NbBytesNeeded:
                    while self.inWaiting() == 0:
                            pass
                    n = self.inWaiting()
                    out += self.read(n)
                    CptRec += n

                    # Test only the first part of data received
                    if First:
                            # First byte received is INS if the INS sent was correct
                            # otherwise it is a status word error
                            insRec = ord(out[0])
                            if not(self.IsINS(insRec)):
                                    # INS unknown => Receive only the SW
                                    NbBytesNeeded = 2
                            First = False
                        
            data = out[1:-2]
            sw = out[-2:]

            if verbose:
                    print "insRec: 0x%02x" % insRec

            dataint=[]
            if data != []:
                if verbose:
                    print "data: ",
                    for c in data:
                        print "0x%02x" % ord(c),
                        dataint.append(ord(c))
                    print ""
                else:
                    for c in data:
                        dataint.append(ord(c))

            if(DEBUG):
                for c in sw: print "0x%02x" % ord(c),
                self.SWToString(sw)
            return [dataint,sw]

    #------------------------------------------
    # P3NotZeroEmission(Cmd,Data,verbose=False)
    # P3 != 0
    # Send data PC -> AVR
    # Cmd = list of size HEADERSIZE
    # Data = list of size P3
    #------------------------------------------
    def P3NotZeroEmission(self,Cmd,Data,verbose=False):
            if verbose:
                    #print command
                    print "comd: ",
                    for c in Cmd: print "0x%02x" % ord(chr(c)),
                    print ""
                    print "data: ",
                    for c in Data: print "0x%02x" % ord(chr(c)),
                    print ""
                
            # send the command
            for s in Cmd:
                    self.write(chr(s))

            # wait for a byte in the input buffer
            while self.inWaiting() == 0:
                    pass
            n = self.inWaiting()
            out = self.read(n)

            # ERROR SW received
            if n == 2:
                    for c in out: print "0x%02x" % ord(c),
                    self.SWToString(out)
                    return

            # get the instruction
            ins  = ord(out[0])
             
            if verbose:
                    print "inst:  0x%02x" % ins
        
            # send data
            for s in Data:
                    self.write(chr(s))

            # wait until there is 2 bytes (SW) in the input buffer
            while self.inWaiting() != 2:
                    pass
            n = self.inWaiting()
        
            # read n bytes in the input buffer
            sw = self.read(n)
                
            # print status word
            if(DEBUG):
                for c in sw: print "0x%02x" % ord(c),
                self.SWToString(sw)

            return sw
        
    #--------------------------------------------
    # WriteECCPoint(AdrBase,Point,verbose=False)
    # AdrBase = [AdrBaseL,AdrBaseH]
    # P = [X,Y,Z] where X = [MSB,...,LSB], etc
    # Return AdrBase for the next data to be sent
    #--------------------------------------------
    def WriteECCPoint(self,AdrBase,Point,verbose=False):
        AdrBaseH = AdrBase[1]
        AdrBaseL = AdrBase[0]
        if verbose:
            print "AdrBaseH: 0x%02x" % AdrBaseH
            print "AdrBaseL: 0x%02x" % AdrBaseL

            print "POINT"
            for coord in Point:
                for c in coord: print "0x%02x" % c,
                print ""
                
        for coord in Point:
            self.SERSend([0x01,self.INS_WRITERAM,AdrBaseL,AdrBaseH,len(coord)]+coord,verbose)

            Adr = AdrBaseH * 256 + AdrBaseL
            Adr += len(coord)
            AdrBaseH = Adr / 256
            AdrBaseL = Adr % 256

        return [AdrBaseL,AdrBaseH]

    #--------------------------------------------
    # WriteData(AdrBase,Data,verbose=False)
    # AdrBase = [AdrBaseL,AdrBaseH]
    # Data = [MSB,...,LSB]
    # Return AdrBase for the next data to be sent
    #--------------------------------------------
    def WriteData(self,AdrBase,Data,verbose=False):
        AdrBaseH = AdrBase[1]
        AdrBaseL = AdrBase[0]
        if verbose:
            print "WriteData"
            print "AdrBaseH: 0x%02x" % AdrBaseH
            print "AdrBaseL: 0x%02x" % AdrBaseL

            print "DATA"
            for c in Data: print "0x%02x" % c,
            print ""

        self.SERSend([0x01,self.INS_WRITERAM,AdrBaseL,AdrBaseH,len(Data)]+Data,verbose)

        Adr = AdrBaseH * 256 + AdrBaseL
        Adr += len(Data)
        AdrBaseH = Adr / 256
        AdrBaseL = Adr % 256
        
        return [AdrBaseL,AdrBaseH]
    
        
if __name__ == "__main__":

        ser = SERCom()
        
        ser.open()
        
        ser.close()

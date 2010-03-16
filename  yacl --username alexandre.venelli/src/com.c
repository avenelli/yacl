/*
com.c - USART communication and command dispatcher

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
#include <avr/io.h>
#include "globvars.h"
#include "com.h"
#include "YACL_Headers.h"

uint8_t u1CLASS;
uint8_t u1INS;
uint8_t u1P1;
uint8_t u1P2;
uint8_t u1P3;

uint8_t globIOBuffer[HEADERSIZE + MAX_BUFFER_SIZE];

YACL_PARAM_S	YACLParam;
P_YACL_PARAM_S  pYACLParam;


// To insert, if necessary, between the "YACL_xxx(pYACLParam)"
// commands in CommandDispatcher function
// Example: 
//			Glitch();
//			YACL_ZpAdd(pYACLParam);
//			Glitch_End();
//
extern void Glitch(void);
extern void Glitch_End(void);


//This function is used to initialize the USART
//at a given UBRR value
extern void USARTInit(uint16_t ubrr_value)
{
  //Set Baud rate
  UBRR0H = (uint8_t)(ubrr_value>>8);
  UBRR0L = (uint8_t)ubrr_value;

  UCSR0C = 3<<UCSZ00; // char size = 8 bits
  UCSR0A = 1<<U2X0; // Asynchronous Double Speed mode

  UCSR0B = (1<<RXEN0) | (1<<TXEN0); // Enable The receiver and transmiter

}




//This function is used to read the available data
//from USART. This function will wait until data is
//available.
uint8_t USARTReadByte(void)
{
   //Wait until a data is available
   while(!(UCSR0A & (1<<RXC0)));

   //Now USART has got data from host
   return UDR0;
}


//This function writes the given "data" to
//the USART which then transmit it via TX line
void USARTWriteByte(uint8_t data)
{
   //Wait untill the transmitter is ready
   while(!(UCSR0A & (1<<UDRE0)));

   //Now write the data to USART buffer
   UDR0=data;
}

// Writes to the USART Length bytes of IOBuffer
void USARTWriteBuffer(uint8_t *IOBuffer, uint8_t Length)
{
  uint8_t Cpt;
  for(Cpt=0; Cpt<Length; Cpt++)
  {
    USARTWriteByte(IOBuffer[Cpt]);
  }
}

// Reads from USART HEADERSIZE bytes that should correspond
// to a command
uint8_t ReadCommand(uint8_t *IOBuffer)
{
  uint8_t i;
  for(i=0; i<HEADERSIZE; i++)
  {
    IOBuffer[i] = USARTReadByte();
  }
  
  u1CLASS = *IOBuffer; 
  u1INS   = *(IOBuffer + 1); 
  u1P1    = *(IOBuffer + 2); 
  u1P2    = *(IOBuffer + 3);  
  u1P3    = *(IOBuffer + 4);  
  
  return OK;
}

// Reads from USART Length bytes into IOBuffer
uint8_t ReadData(uint8_t *IOBuffer, uint8_t Length)
{
  uint8_t i;
  for(i=0; i<Length; i++)
  {
    IOBuffer[i] = USARTReadByte();
  }
  return OK;
}

// Writes to USART a status byte 
void SendStatus(uint8_t SW1, uint8_t SW2)
{
  globIOBuffer[0] = SW1;
  globIOBuffer[1] = SW2;
  USARTWriteBuffer(globIOBuffer,STATUSSIZE);
}


// Read RAM (swapped = LSB first on the device)
void ReadRAM(void)
{
  uint8_t Cpt;
  uint8_t *pRAMAdresse;
  pRAMAdresse = (uint8_t *)(((u1GetP2() << 8) | u1GetP1()) + u1GetP3() - 1);
  
  USARTWriteByte(u1GetINS());
    
  for(Cpt=0; Cpt<u1GetP3(); Cpt++)
  {
    USARTWriteByte(*((uint8_t *)(pRAMAdresse - Cpt)));
  }
    
  SendStatus(SW_OK);
}

// Write RAM (swapped = LSB first on the device)
void WriteRAM(void)
{
  uint8_t Cpt;
  uint8_t *pRAMAdresse;
  pRAMAdresse = (uint8_t *)(((u1GetP2() << 8) | u1GetP1()) + u1GetP3() - 1);
  
  USARTWriteByte(u1GetINS());
  
  for(Cpt=0; Cpt<u1GetP3(); Cpt++)
  {
    (*(uint8_t *)(pRAMAdresse - Cpt)) = USARTReadByte();
  }
  SendStatus(SW_OK);
}

void CommandDispatcher(void)
{
  pYACLParam = (P_YACL_PARAM_S)&YACLParam;

  switch(u1GetP1())
  {
  case CMD_ZPADD:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpAdd(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPSUB:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpSub(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPMUL2D:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpMul2d(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_COPYPAD:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_CopyPad(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_FILL:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_Fill(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
    
  case CMD_SETBYTE:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_SetByte(pYACLParam);
      SendStatus(SW_OK);
    }
    break;  

  case CMD_ZPMULT:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpMult(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPMULT1B:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpMult1B(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPREDMOD:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpRedMod(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPINVMOD:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpInvMod(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
    
  case CMD_ZPECADD:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpEccAdd(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPECDBL:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpEccDbl(pYACLParam);
      SendStatus(SW_OK);
    }
    break;
  case CMD_ZPSQUARE:
    USARTWriteByte(u1GetINS());
    if(ReadData((uint8_t*)pYACLParam,u1GetP3()) != OK)
    {
      SendStatus(SW_COMMUNICATION_ERROR);
    }
    else
    {
      YACL_ZpSquare(pYACLParam);
      SendStatus(SW_OK);
    }
    break;

  default:
    break;   
  }
}



extern void MainDispatcher(void)
{
  for(;;)
  {
    // Read the command in globIOBuffer
    if(ReadCommand(globIOBuffer) == OK)
    {
      // Do not take care of CLASS byte (for now)
      
      // Dispatch according to INS
      switch(u1GetINS())
      {
      case INS_READRAM:
        ReadRAM();
        break;
      case INS_WRITERAM:
        WriteRAM();
        break;
      case INS_COMMAND:
        CommandDispatcher();
        break;
      default:
        SendStatus(SW_UNKNOWN_INS);
        break;   
      }
    }
    else
    {
      // Send Error: wrong command
      SendStatus(SW_COMMUNICATION_ERROR);
    }
  }
}

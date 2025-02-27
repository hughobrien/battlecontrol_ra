/*
**	Command & Conquer Red Alert(tm)
**	Copyright 2025 Electronic Arts Inc.
**
**	This program is free software: you can redistribute it and/or modify
**	it under the terms of the GNU General Public License as published by
**	the Free Software Foundation, either version 3 of the License, or
**	(at your option) any later version.
**
**	This program is distributed in the hope that it will be useful,
**	but WITHOUT ANY WARRANTY; without even the implied warranty of
**	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**	GNU General Public License for more details.
**
**	You should have received a copy of the GNU General Public License
**	along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

extern "C" {
#include "lpc.h"
#include "types.h"
#include "services.h"
#include "rtq.h"
#include <stdio.h>
#include <mem.h>
};
#include "mplib.h"


#define IDLE_QUEUE    6
#define REC_QUEUE     7
#define SEND_QUEUE    8

void
SetLPCData(LPCData *lpc)
{
   lpc->version = 1;
   lpc->sizeOfArgs = 0;
   lpc->service = LPC_NOSERVICE;
}

void
GetGameDef(void *gameDef, int* len)
{
   RTQ_NODE  *n = MGenGetNode(IDLE_QUEUE);
   LPCData   *p;
   LPCReturn *r;
   
   if (!n) {
      *len = 0;
      return;    // can't get service!
   }

   p = (LPCData *) n->rtqDatum;
   SetLPCData(p);
   p->service = LPC_GENGETGAMEDEF;
   MGenMoveTo(IDLE_QUEUE, SEND_QUEUE);

   // make call
   PostWindowsMessage();

   // wait for return
   while ((n = MGenGetNode(REC_QUEUE)) == 0)
      Yield();

   r = (LPCReturn *) n->rtqDatum;

   if (r->sizeOfReturn > *len || r->error != LPC_NOERROR) {
      *len = 0;
      return;
   }

   *len = r->sizeOfReturn;
   memcpy(gameDef, r->Data, r->sizeOfReturn);

   // get ready for next call
   MGenMoveTo(REC_QUEUE, IDLE_QUEUE);
}

int
LPCGetMPAddr(void)
{
   RTQ_NODE  *n = MGenGetNode(IDLE_QUEUE);
   LPCData   *p;
   LPCReturn *r;
   int       retVal;

   p = (LPCData *) n->rtqDatum;
   SetLPCData(p);
   p->service = LPC_GETMPADDR;
   MGenMoveTo(IDLE_QUEUE, SEND_QUEUE);

   PostWindowsMessage();

   while ((n = MGenGetNode(REC_QUEUE)) == 0)
      Yield();

   r = (LPCReturn *) n->rtqDatum;

   if (r->sizeOfReturn != sizeof(int) || r->error != LPC_NOERROR) {
      return -1;
   }

   retVal = *((int *) r->Data);
   MGenMoveTo(REC_QUEUE, IDLE_QUEUE);
   return retVal;
}

void
NullLPC(void)
{
   RTQ_NODE  *n = MGenGetNode(IDLE_QUEUE);
   LPCData   *p;

   p = (LPCData *) n->rtqDatum;
   SetLPCData(p);
   p->service = LPC_NULLSERVICE;
   MGenMoveTo(IDLE_QUEUE, SEND_QUEUE);

   PostWindowsMessage();

   while ((n = MGenGetNode(REC_QUEUE)) == 0)
      Yield();

   MGenMoveTo(REC_QUEUE, IDLE_QUEUE);
}

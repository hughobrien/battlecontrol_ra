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

/***************************************************************************
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Timer Class Functions                    *
 *                                                                         *
 *                    File Name : TIMER.H                                  *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : July 6, 1994                             *
 *                                                                         *
 *                  Last Update : July 12, 1994   [SKB]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#ifndef TIMER_H
#define TIMER_H

/*=========================================================================*/
/* The following prototypes are for the file: TIMERA.ASM							*/
/*=========================================================================*/

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// Externs /////////////////////////////////////////////
extern BOOL TimerSystemOn;


/*=========================================================================*/
typedef enum BaseTimerEnum {
	BT_SYSTEM,			// System timer (60 / second).
	BT_USER				// User controllable timer (? / second).
} BaseTimerEnum;

class TimerClass {
 	public:
		// Constructor.  Timers set before low level init has been done will not
		// be able to be 'Started' or 'on' until timer system is in place.	
		TimerClass(BaseTimerEnum timer=BT_SYSTEM, BOOL start=FALSE);

		// No destructor.
		~TimerClass(void){}

		// 
		long Set(long value, BOOL start=TRUE);	// Set initial timer value.
		long Stop(void);				// Pause timer.
		long Start(void);				// Resume timer.
		long Reset(BOOL start=TRUE);	// Reset timer to zero.
		long Time(void);				// Fetch current timer value.

	protected:
		long Started;					// Time last started (0 == not paused).
		long Accumulated;				//	Total accumulated ticks.

	private:
		long (*Get_Ticks)(void);	// System timer fetch.
};


inline long TimerClass::Reset(BOOL start)
{
	return(Set(0, start));
}


class CountDownTimerClass : private TimerClass {
	public:
		// Constructor.  Timers set before low level init has been done will not
		// be able to be 'Started' or 'on' until timer system is in place.	
		CountDownTimerClass(BaseTimerEnum timer, long set, int on=FALSE);
		CountDownTimerClass(BaseTimerEnum timer=BT_SYSTEM, int on=FALSE);

		// No destructor.
		~CountDownTimerClass(void){}

		// Public functions
		long Set(long set, BOOL start=TRUE);	// Set count down value.
		long Reset(BOOL start=TRUE);	// Reset timer to zero.
		long Stop(void);			// Pause timer.
		long Start(void);			// Resume timer.
		long Time(void);			// Fetch current count down value.

	protected:
		long DelayTime;			// Ticks remaining before countdown timer expires.
};

inline long CountDownTimerClass::Stop(void)
{
	TimerClass::Stop();
	return(Time());
}

inline long CountDownTimerClass::Start(void)
{
	TimerClass::Start();
	return(Time());
}

inline long CountDownTimerClass::Reset(BOOL start)
{
	return (TimerClass::Reset(start));
}



//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// externs  //////////////////////////////////////////

extern TimerClass					TickCount;
extern CountDownTimerClass		CountDown;

//////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// Prototypes //////////////////////////////////////////

extern "C" {
	long Get_System_Tick_Count(void);
	long Get_User_Tick_Count(void);
	void far Timer_Interrupt_Func(void);
//	long Get_Num_Interrupts(unsigned int realmode);
}

/*=========================================================================*/
/* The following prototypes are for the file: TIMER.CPP							*/
/*=========================================================================*/
BOOL Init_Timer_System(unsigned int freq, int partial = FALSE);
BOOL Remove_Timer_System(VOID);


#endif // TIMER_H



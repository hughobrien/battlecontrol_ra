#ifndef BATTLECONTROL_RA_WIN32_SHIM_MMSYSTEM_H
#define BATTLECONTROL_RA_WIN32_SHIM_MMSYSTEM_H

#include <windows.h>

typedef UINT MMRESULT;
typedef void (CALLBACK *LPTIMECALLBACK)(UINT event_id, UINT reserved, DWORD user, DWORD reserved1, DWORD reserved2);

#ifndef TIME_ONESHOT
#define TIME_ONESHOT 0x0000
#endif
#ifndef TIME_PERIODIC
#define TIME_PERIODIC 0x0001
#endif

#ifdef __cplusplus
extern "C" {
#endif
MMRESULT timeBeginPeriod(UINT period);
MMRESULT timeEndPeriod(UINT period);
MMRESULT timeSetEvent(UINT delay, UINT resolution, LPTIMECALLBACK callback, DWORD user, UINT event);
MMRESULT timeKillEvent(UINT timer_id);
DWORD timeGetTime(void);
#ifdef __cplusplus
}
#endif

#endif

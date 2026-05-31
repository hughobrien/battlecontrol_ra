#ifndef BATTLECONTROL_RA_WIN32_SHIM_PROCESS_H
#define BATTLECONTROL_RA_WIN32_SHIM_PROCESS_H

#include <unistd.h>

#ifndef _getpid
#define _getpid getpid
#endif

#endif

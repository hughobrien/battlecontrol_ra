#ifndef BATTLECONTROL_RA_WIN32_SHIM_DIRECT_H
#define BATTLECONTROL_RA_WIN32_SHIM_DIRECT_H

#include <sys/stat.h>
#include <unistd.h>

#ifndef _chdir
#define _chdir chdir
#endif

#ifndef _getcwd
#define _getcwd getcwd
#endif

#ifndef _mkdir
#define _mkdir(path) mkdir((path), 0777)
#endif

#ifndef _rmdir
#define _rmdir rmdir
#endif

#endif

#ifndef BATTLECONTROL_RA_WIN32_SHIM_DIRECT_H
#define BATTLECONTROL_RA_WIN32_SHIM_DIRECT_H

#include <sys/stat.h>
#include <unistd.h>

#ifndef _MAX_DRIVE
#define _MAX_DRIVE 3
#endif
#ifndef _MAX_DIR
#define _MAX_DIR 256
#endif
#ifndef _MAX_FNAME
#define _MAX_FNAME 256
#endif
#ifndef _MAX_EXT
#define _MAX_EXT 256
#endif
#ifndef _MAX_PATH
#define _MAX_PATH 260
#endif

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

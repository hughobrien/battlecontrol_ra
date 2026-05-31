#ifndef BATTLECONTROL_RA_WIN32_SHIM_IO_H
#define BATTLECONTROL_RA_WIN32_SHIM_IO_H

#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <unistd.h>

#ifndef O_BINARY
#define O_BINARY 0
#endif

#ifndef S_IREAD
#define S_IREAD S_IRUSR
#endif

#ifndef S_IWRITE
#define S_IWRITE S_IWUSR
#endif

static inline long filelength(int handle)
{
    off_t current = lseek(handle, 0, SEEK_CUR);
    if (current == (off_t)-1) {
        return -1;
    }

    off_t end = lseek(handle, 0, SEEK_END);
    if (end == (off_t)-1) {
        return -1;
    }

    if (lseek(handle, current, SEEK_SET) == (off_t)-1) {
        return -1;
    }

    return (long)end;
}

#endif

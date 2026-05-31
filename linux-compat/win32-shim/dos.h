#ifndef BATTLECONTROL_RA_WIN32_SHIM_DOS_H
#define BATTLECONTROL_RA_WIN32_SHIM_DOS_H

#ifndef _HARDERR_FAIL
#define _HARDERR_FAIL 0
#endif

#ifndef _A_SUBDIR
#define _A_SUBDIR 0x10
#endif

#ifndef _MAX_PATH
#define _MAX_PATH 260
#endif

struct find_t {
    unsigned attrib;
    char name[_MAX_PATH];
};

#ifdef __cplusplus
extern "C" {
#endif

int _dos_findfirst(const char *filespec, unsigned attrib, struct find_t *fileinfo);

static inline int _dos_getdrive(unsigned int *drive)
{
    if (drive) {
        *drive = 3;
    }
    return 0;
}

static inline int _dos_setdrive(unsigned int, unsigned int *drives)
{
    if (drives) {
        *drives = 3;
    }
    return 0;
}

#ifdef __cplusplus
}
#endif

#endif

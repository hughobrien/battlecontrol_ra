#ifndef BATTLECONTROL_RA_WIN32_SHIM_DOS_H
#define BATTLECONTROL_RA_WIN32_SHIM_DOS_H

#ifdef __cplusplus
extern "C" {
#endif

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

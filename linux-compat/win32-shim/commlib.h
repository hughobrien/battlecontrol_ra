#ifndef BATTLECONTROL_RA_WIN32_SHIM_COMMLIB_H
#define BATTLECONTROL_RA_WIN32_SHIM_COMMLIB_H

typedef struct PORT {
    int status;
    int count;
} PORT;

enum {
    COM1 = 0,
    COM2,
    COM3,
    COM4,
    COM5,
};

#define ASSUCCESS 0
#define ASBUFREMPTY 1
#define ASUSERABORT -16

#endif

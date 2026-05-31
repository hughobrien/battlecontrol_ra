#ifndef BATTLECONTROL_RA_WIN32_SHIM_DDEML_H
#define BATTLECONTROL_RA_WIN32_SHIM_DDEML_H

#include <windows.h>

typedef void *HCONV;
typedef void *HCONVLIST;
typedef void *HDDEDATA;
typedef void *HSZ;
typedef void *PCONVCONTEXT;

#ifndef APPCLASS_STANDARD
#define APPCLASS_STANDARD 0x00000000u
#endif
#ifndef CBF_FAIL_SELFCONNECTIONS
#define CBF_FAIL_SELFCONNECTIONS 0x00001000u
#endif
#ifndef DMLERR_NO_ERROR
#define DMLERR_NO_ERROR 0
#endif
#ifndef CP_WINANSI
#define CP_WINANSI 1004
#endif
#ifndef SZDDESYS_TOPIC
#define SZDDESYS_TOPIC "System"
#endif
#ifndef DNS_REGISTER
#define DNS_REGISTER 0x0001
#endif
#ifndef CF_TEXT
#define CF_TEXT 1
#endif
#ifndef XTYP_POKE
#define XTYP_POKE 0x4090
#endif
#ifndef XTYP_REGISTER
#define XTYP_REGISTER 0x00A0
#endif
#ifndef XTYP_UNREGISTER
#define XTYP_UNREGISTER 0x00D0
#endif
#ifndef XTYP_ADVDATA
#define XTYP_ADVDATA 0x4010
#endif
#ifndef XTYP_XACT_COMPLETE
#define XTYP_XACT_COMPLETE 0x8080
#endif
#ifndef XTYP_DISCONNECT
#define XTYP_DISCONNECT 0x00C0
#endif
#ifndef XTYP_CONNECT
#define XTYP_CONNECT 0x1062
#endif
#ifndef DDE_FACK
#define DDE_FACK 0x8000
#endif
#ifndef DDE_FNOTPROCESSED
#define DDE_FNOTPROCESSED 0x0000
#endif

#ifdef __cplusplus
extern "C" {
#endif
UINT DdeInitialize(LPDWORD instance, HDDEDATA(CALLBACK *callback)(UINT, UINT, HCONV, HSZ, HSZ, HDDEDATA, DWORD, DWORD), DWORD command, DWORD reserved);
HSZ DdeCreateStringHandle(DWORD instance, LPCSTR string, int code_page);
BOOL DdeUninitialize(DWORD instance);
HDDEDATA DdeNameService(DWORD instance, HSZ service, HSZ reserved, UINT command);
HCONV DdeConnect(DWORD instance, HSZ service, HSZ topic, PCONVCONTEXT context);
BOOL DdeDisconnect(HCONV conversation);
HDDEDATA DdeClientTransaction(LPBYTE data, DWORD data_length, HCONV conversation, HSZ item, UINT format, UINT transaction, DWORD timeout, LPDWORD result);
DWORD DdeQueryString(DWORD instance, HSZ string, LPSTR buffer, DWORD buffer_max, int code_page);
LPBYTE DdeAccessData(HDDEDATA data, LPDWORD data_size);
BOOL DdeUnaccessData(HDDEDATA data);
#ifdef __cplusplus
}
#endif

#endif

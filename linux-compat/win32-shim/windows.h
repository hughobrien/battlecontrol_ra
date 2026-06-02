#ifndef BATTLECONTROL_RA_WIN32_SHIM_WINDOWS_H
#define BATTLECONTROL_RA_WIN32_SHIM_WINDOWS_H

#include <stddef.h>
#include <stdint.h>

#ifndef BOOL
typedef int BOOL;
#endif
typedef unsigned char BOOLEAN;
typedef unsigned char BYTE;
typedef uint16_t WORD;
typedef uint32_t DWORD;
typedef uint64_t DWORD64;
typedef int64_t LONGLONG;
typedef uint64_t ULONGLONG;
typedef long LONG;
typedef unsigned long ULONG;
typedef int INT;
typedef unsigned int UINT;
typedef uintptr_t UINT_PTR;
typedef intptr_t LONG_PTR;
typedef uintptr_t ULONG_PTR;
typedef uintptr_t DWORD_PTR;
typedef wchar_t WCHAR;
#ifndef VOID
typedef void VOID;
#endif

typedef void *HANDLE;
typedef void *HWND;
typedef void *HINSTANCE;
typedef void *HMODULE;
typedef void *FARPROC;
typedef void *HDC;
typedef void *HBITMAP;
typedef void *HCURSOR;
typedef void *HICON;
typedef void *HMENU;
typedef void *HMONITOR;
typedef void *HPALETTE;
typedef void *HHOOK;
typedef void *HKEY;
typedef void *HGDIOBJ;
typedef void *HBRUSH;
typedef UINT_PTR SOCKET;

typedef char *LPSTR;
typedef const char *LPCSTR;
typedef const char *LPCTSTR;
typedef WCHAR *LPWSTR;
typedef const WCHAR *LPCWSTR;
typedef void *LPVOID;
typedef const void *LPCVOID;
typedef BOOL *LPBOOL;
typedef BYTE *LPBYTE;
typedef BYTE *PBYTE;
typedef WORD *LPWORD;
typedef DWORD *LPDWORD;
typedef LONG *LPLONG;

typedef LONG HRESULT;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;
typedef intptr_t INT_PTR;
typedef WORD ATOM;
typedef LONG (*WNDPROC)(HWND, UINT, UINT, LONG);
typedef INT_PTR (*DLGPROC)(HWND, UINT, WPARAM, LPARAM);

typedef struct in_addr {
    union {
        struct {
            BYTE s_b1;
            BYTE s_b2;
            BYTE s_b3;
            BYTE s_b4;
        } S_un_b;
        DWORD S_addr;
    } S_un;
} IN_ADDR;

typedef struct WSAData {
    WORD wVersion;
    WORD wHighVersion;
    char szDescription[257];
    char szSystemStatus[129];
    WORD iMaxSockets;
    WORD iMaxUdpDg;
    char *lpVendorInfo;
} WSADATA, *LPWSADATA;

typedef struct _PROCESS_INFORMATION {
    HANDLE hProcess;
    HANDLE hThread;
    DWORD dwProcessId;
    DWORD dwThreadId;
} PROCESS_INFORMATION, *LPPROCESS_INFORMATION;

typedef struct _SECURITY_ATTRIBUTES {
    DWORD nLength;
    LPVOID lpSecurityDescriptor;
    BOOL bInheritHandle;
} SECURITY_ATTRIBUTES, *LPSECURITY_ATTRIBUTES;

typedef struct _STARTUPINFO {
    DWORD cb;
    LPSTR lpReserved;
    LPSTR lpDesktop;
    LPSTR lpTitle;
    DWORD dwX;
    DWORD dwY;
    DWORD dwXSize;
    DWORD dwYSize;
    DWORD dwXCountChars;
    DWORD dwYCountChars;
    DWORD dwFillAttribute;
    DWORD dwFlags;
    WORD wShowWindow;
    WORD cbReserved2;
    BYTE *lpReserved2;
    HANDLE hStdInput;
    HANDLE hStdOutput;
    HANDLE hStdError;
} STARTUPINFO, *LPSTARTUPINFO;

typedef struct _FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} FILETIME, *LPFILETIME;

typedef struct _SYSTEMTIME {
    WORD wYear;
    WORD wMonth;
    WORD wDayOfWeek;
    WORD wDay;
    WORD wHour;
    WORD wMinute;
    WORD wSecond;
    WORD wMilliseconds;
} SYSTEMTIME, *LPSYSTEMTIME;

typedef struct _BY_HANDLE_FILE_INFORMATION {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD dwVolumeSerialNumber;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD nNumberOfLinks;
    DWORD nFileIndexHigh;
    DWORD nFileIndexLow;
} BY_HANDLE_FILE_INFORMATION, *LPBY_HANDLE_FILE_INFORMATION;

typedef struct _MEMORYSTATUS {
    DWORD dwLength;
    DWORD dwMemoryLoad;
    DWORD dwTotalPhys;
    DWORD dwAvailPhys;
    DWORD dwTotalPageFile;
    DWORD dwAvailPageFile;
    DWORD dwTotalVirtual;
    DWORD dwAvailVirtual;
} MEMORYSTATUS, *LPMEMORYSTATUS;

typedef struct tagRECT {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT, *LPRECT;

typedef struct tagPOINT {
    LONG x;
    LONG y;
} POINT, *LPPOINT;

typedef struct tagSIZE {
    LONG cx;
    LONG cy;
} SIZE, *LPSIZE;

typedef struct tagMSG {
    HWND hwnd;
    UINT message;
    WPARAM wParam;
    LPARAM lParam;
    DWORD time;
    POINT pt;
} MSG, *LPMSG;

typedef struct tagWNDCLASS {
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCSTR lpszMenuName;
    LPCSTR lpszClassName;
} WNDCLASS, *LPWNDCLASS;

typedef union _LARGE_INTEGER {
    struct {
        DWORD LowPart;
        LONG HighPart;
    };
    LONGLONG QuadPart;
} LARGE_INTEGER;

typedef struct _GUID {
    DWORD Data1;
    WORD Data2;
    WORD Data3;
    BYTE Data4[8];
} GUID, IID, CLSID;
typedef GUID *LPGUID;
typedef const GUID *REFGUID;
typedef const IID *REFIID;
typedef const CLSID *REFCLSID;

typedef struct tagPALETTEENTRY {
    BYTE peRed;
    BYTE peGreen;
    BYTE peBlue;
    BYTE peFlags;
} PALETTEENTRY, *LPPALETTEENTRY;

typedef struct _RGNDATA {
    DWORD dwSize;
    BYTE Buffer[1];
} RGNDATA, *LPRGNDATA;

typedef struct _RTL_CRITICAL_SECTION {
    void *DebugInfo;
    int32_t LockCount;
    int32_t RecursionCount;
    HANDLE OwningThread;
    HANDLE LockSemaphore;
    ULONG_PTR SpinCount;
} CRITICAL_SECTION, *PCRITICAL_SECTION, *LPCRITICAL_SECTION;

#ifndef TRUE
#define TRUE 1
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef NULL
#define NULL ((void *)0)
#endif
#ifndef INVALID_HANDLE_VALUE
#define INVALID_HANDLE_VALUE ((HANDLE)(intptr_t)-1)
#endif

#ifndef FAR
#define FAR
#endif
#ifndef far
#define far
#endif
#ifndef NEAR
#define NEAR
#endif
#ifndef near
#define near
#endif
#ifndef PASCAL
#define PASCAL
#endif
#ifndef WINAPI
#define WINAPI
#endif
#ifndef CALLBACK
#define CALLBACK
#endif
#ifndef APIENTRY
#define APIENTRY
#endif
#ifndef __cdecl
#define __cdecl
#endif
#ifndef cdecl
#define cdecl
#endif
#ifndef __stdcall
#define __stdcall
#endif
#ifndef __declspec
#define __declspec(x)
#endif
#ifndef _export
#define _export
#endif
#ifndef __success
#define __success(x)
#endif

#ifndef LOWORD
#define LOWORD(l) ((WORD)((uintptr_t)(l) & 0xffffu))
#endif
#ifndef HIWORD
#define HIWORD(l) ((WORD)((uintptr_t)(l) >> 16))
#endif
#ifndef MAKEINTRESOURCE
#define MAKEINTRESOURCE(i) ((LPCTSTR)(uintptr_t)((WORD)(i)))
#endif

#ifndef MAKE_HRESULT
#define MAKE_HRESULT(sev, fac, code) \
    ((HRESULT)(((uint32_t)(sev) << 31) | ((uint32_t)(fac) << 16) | (uint32_t)(code)))
#endif

#ifndef DEFINE_GUID
#define DEFINE_GUID(name, l, w1, w2, b1, b2, b3, b4, b5, b6, b7, b8) \
    static const GUID name = { (DWORD)(l), (WORD)(w1), (WORD)(w2), { (BYTE)(b1), (BYTE)(b2), (BYTE)(b3), (BYTE)(b4), (BYTE)(b5), (BYTE)(b6), (BYTE)(b7), (BYTE)(b8) } }
#endif

#ifndef DECLARE_HANDLE
#define DECLARE_HANDLE(name) typedef void *name
#endif

#ifndef FAILED
#define FAILED(hr) (((HRESULT)(hr)) < 0)
#endif
#ifndef SUCCEEDED
#define SUCCEEDED(hr) (((HRESULT)(hr)) >= 0)
#endif
#ifndef S_OK
#define S_OK ((HRESULT)0)
#endif
#ifndef ERROR_SUCCESS
#define ERROR_SUCCESS 0
#endif
#ifndef E_FAIL
#define E_FAIL ((HRESULT)0x80004005L)
#endif
#ifndef E_INVALIDARG
#define E_INVALIDARG ((HRESULT)0x80070057L)
#endif
#ifndef E_OUTOFMEMORY
#define E_OUTOFMEMORY ((HRESULT)0x8007000EL)
#endif
#ifndef E_NOTIMPL
#define E_NOTIMPL ((HRESULT)0x80004001L)
#endif

#ifndef MB_OK
#define MB_OK 0x00000000L
#endif
#ifndef MB_ICONSTOP
#define MB_ICONSTOP 0x00000010L
#endif
#ifndef MB_ICONQUESTION
#define MB_ICONQUESTION 0x00000020L
#endif
#ifndef MB_ICONEXCLAMATION
#define MB_ICONEXCLAMATION 0x00000030L
#endif
#ifndef MB_YESNO
#define MB_YESNO 0x00000004L
#endif
#ifndef IDNO
#define IDNO 7
#endif

#ifndef WM_DESTROY
#define WM_DESTROY 0x0002
#endif
#ifndef WM_ACTIVATEAPP
#define WM_ACTIVATEAPP 0x001c
#endif
#ifndef WM_SYSCOMMAND
#define WM_SYSCOMMAND 0x0112
#endif
#ifndef WM_KEYDOWN
#define WM_KEYDOWN 0x0100
#endif
#ifndef WM_KEYUP
#define WM_KEYUP 0x0101
#endif
#ifndef WM_SYSKEYDOWN
#define WM_SYSKEYDOWN 0x0104
#endif
#ifndef WM_SYSKEYUP
#define WM_SYSKEYUP 0x0105
#endif
#ifndef WM_MOUSEMOVE
#define WM_MOUSEMOVE 0x0200
#endif
#ifndef WM_LBUTTONDOWN
#define WM_LBUTTONDOWN 0x0201
#endif
#ifndef WM_LBUTTONUP
#define WM_LBUTTONUP 0x0202
#endif
#ifndef WM_LBUTTONDBLCLK
#define WM_LBUTTONDBLCLK 0x0203
#endif
#ifndef WM_RBUTTONDOWN
#define WM_RBUTTONDOWN 0x0204
#endif
#ifndef WM_RBUTTONUP
#define WM_RBUTTONUP 0x0205
#endif
#ifndef WM_RBUTTONDBLCLK
#define WM_RBUTTONDBLCLK 0x0206
#endif
#ifndef WM_MBUTTONDOWN
#define WM_MBUTTONDOWN 0x0207
#endif
#ifndef WM_MBUTTONUP
#define WM_MBUTTONUP 0x0208
#endif
#ifndef WM_MBUTTONDBLCLK
#define WM_MBUTTONDBLCLK 0x0209
#endif
#ifndef WM_USER
#define WM_USER 0x0400
#endif

#ifndef PM_NOREMOVE
#define PM_NOREMOVE 0x0000
#endif
#ifndef PM_REMOVE
#define PM_REMOVE 0x0001
#endif
#ifndef PM_NOYIELD
#define PM_NOYIELD 0x0002
#endif

#ifndef CS_VREDRAW
#define CS_VREDRAW 0x0001
#endif
#ifndef CS_HREDRAW
#define CS_HREDRAW 0x0002
#endif

#ifndef WS_POPUP
#define WS_POPUP 0x80000000u
#endif
#ifndef WS_EX_TOPMOST
#define WS_EX_TOPMOST 0x00000008u
#endif

#ifndef SM_CXSCREEN
#define SM_CXSCREEN 0
#endif
#ifndef SM_CYSCREEN
#define SM_CYSCREEN 1
#endif

#ifndef SC_SCREENSAVE
#define SC_SCREENSAVE 0xf140
#endif
#ifndef SC_CLOSE
#define SC_CLOSE 0xf060
#endif

#ifndef SW_HIDE
#define SW_HIDE 0
#endif
#ifndef SW_RESTORE
#define SW_RESTORE 9
#endif
#ifndef SW_SHOWMAXIMIZED
#define SW_SHOWMAXIMIZED 3
#endif
#ifndef SW_MINIMIZE
#define SW_MINIMIZE 6
#endif

#ifndef INVALID_SOCKET
#define INVALID_SOCKET ((SOCKET)(UINT_PTR)-1)
#endif
#ifndef SOCKET_ERROR
#define SOCKET_ERROR (-1)
#endif
#ifndef MAXGETHOSTSTRUCT
#define MAXGETHOSTSTRUCT 1024
#endif

#ifndef INVALID_HANDLE_VALUE
#define INVALID_HANDLE_VALUE ((HANDLE)(LONG_PTR)-1)
#endif

#ifndef MAX_PATH
#define MAX_PATH 260
#endif

#ifndef GENERIC_READ
#define GENERIC_READ 0x80000000u
#endif
#ifndef GENERIC_WRITE
#define GENERIC_WRITE 0x40000000u
#endif
#ifndef FILE_SHARE_READ
#define FILE_SHARE_READ 0x00000001u
#endif
#ifndef CREATE_ALWAYS
#define CREATE_ALWAYS 2
#endif
#ifndef OPEN_EXISTING
#define OPEN_EXISTING 3
#endif
#ifndef FILE_ATTRIBUTE_NORMAL
#define FILE_ATTRIBUTE_NORMAL 0x00000080u
#endif
#ifndef FILE_BEGIN
#define FILE_BEGIN 0
#endif
#ifndef FILE_CURRENT
#define FILE_CURRENT 1
#endif
#ifndef FILE_END
#define FILE_END 2
#endif
#ifndef SEM_FAILCRITICALERRORS
#define SEM_FAILCRITICALERRORS 0x0001
#endif
#ifndef SEM_NOOPENFILEERRORBOX
#define SEM_NOOPENFILEERRORBOX 0x8000
#endif
#ifndef DUPLICATE_SAME_ACCESS
#define DUPLICATE_SAME_ACCESS 0x00000002u
#endif

#ifndef HKEY_CLASSES_ROOT
#define HKEY_CLASSES_ROOT ((HKEY)(UINT_PTR)0x80000000u)
#endif
#ifndef HKEY_LOCAL_MACHINE
#define HKEY_LOCAL_MACHINE ((HKEY)(UINT_PTR)0x80000002u)
#endif
#ifndef KEY_READ
#define KEY_READ 0x20019
#endif

#ifndef DRIVE_UNKNOWN
#define DRIVE_UNKNOWN 0
#define DRIVE_NO_ROOT_DIR 1
#define DRIVE_REMOVABLE 2
#define DRIVE_FIXED 3
#define DRIVE_REMOTE 4
#define DRIVE_CDROM 5
#define DRIVE_RAMDISK 6
#endif

#ifdef __cplusplus
extern "C" {
#endif
DWORD GetModuleFileName(HMODULE module, LPSTR filename, DWORD size);
DWORD GetVersion(void);
HINSTANCE LoadLibrary(LPCSTR library_name);
FARPROC GetProcAddress(HMODULE module, LPCSTR procedure_name);
BOOL FreeLibrary(HMODULE module);
HWND FindWindow(LPCSTR class_name, LPCSTR window_name);
BOOL IsWindow(HWND window);
BOOL PostMessage(HWND window, UINT message, WPARAM wparam, LPARAM lparam);
BOOL PeekMessage(LPMSG msg, HWND window, UINT filter_min, UINT filter_max, UINT remove_msg);
BOOL GetMessage(LPMSG msg, HWND window, UINT filter_min, UINT filter_max);
BOOL TranslateMessage(const MSG *msg);
LRESULT DispatchMessage(const MSG *msg);
LRESULT DefWindowProc(HWND window, UINT message, WPARAM wparam, LPARAM lparam);
void PostQuitMessage(int exit_code);
void ExitProcess(UINT exit_code);
BOOL SetForegroundWindow(HWND window);
BOOL ShowWindow(HWND window, int command_show);
HICON LoadIcon(HINSTANCE instance, LPCTSTR icon_name);
ATOM RegisterClass(const WNDCLASS *window_class);
HWND CreateWindowEx(DWORD ex_style, LPCTSTR class_name, LPCTSTR window_name, DWORD style, int x, int y, int width, int height, HWND parent, HMENU menu, HINSTANCE instance, LPVOID param);
int GetSystemMetrics(int index);
BOOL UpdateWindow(HWND window);
HWND SetFocus(HWND window);
BOOL GetCursorPos(LPPOINT point);
BOOL ClipCursor(const RECT *rect);
UINT MapVirtualKey(UINT code, UINT map_type);
int ToAscii(UINT virtual_key, UINT scan_code, PBYTE key_state, LPWORD translated, UINT flags);
short GetKeyState(int key);
short GetAsyncKeyState(int key);
void InitializeCriticalSection(LPCRITICAL_SECTION critical_section);
void DeleteCriticalSection(LPCRITICAL_SECTION critical_section);
void EnterCriticalSection(LPCRITICAL_SECTION critical_section);
void LeaveCriticalSection(LPCRITICAL_SECTION critical_section);
UINT RegisterWindowMessage(LPCTSTR string);
INT_PTR DialogBox(HANDLE instance, LPCTSTR template_name, HWND owner, DLGPROC dialog_proc);
int ShowCursor(BOOL show);
int MessageBox(HWND window, LPCSTR text, LPCSTR caption, UINT type);
LPSTR lstrcpy(LPSTR dest, LPCSTR src);
HANDLE CreateFile(LPCSTR file_name, DWORD desired_access, DWORD share_mode, LPSECURITY_ATTRIBUTES security_attributes, DWORD creation_disposition, DWORD flags_and_attributes, HANDLE template_file);
BOOL ReadFile(HANDLE file, LPVOID buffer, DWORD bytes_to_read, LPDWORD bytes_read, LPVOID overlapped);
BOOL WriteFile(HANDLE file, LPCVOID buffer, DWORD bytes_to_write, LPDWORD bytes_written, LPVOID overlapped);
BOOL CloseHandle(HANDLE object);
DWORD GetFileSize(HANDLE file, LPDWORD file_size_high);
DWORD SetFilePointer(HANDLE file, LONG distance_to_move, LPLONG distance_to_move_high, DWORD move_method);
BOOL DeleteFile(LPCSTR file_name);
DWORD GetLastError(void);
UINT SetErrorMode(UINT mode);
BOOL GetFileInformationByHandle(HANDLE file, BY_HANDLE_FILE_INFORMATION *file_information);
UINT GetDriveType(LPCSTR root_path_name);
BOOL GetVolumeInformation(LPCSTR root_path_name, LPSTR volume_name_buffer, DWORD volume_name_size, LPDWORD volume_serial_number, LPDWORD maximum_component_length, LPDWORD file_system_flags, LPSTR file_system_name_buffer, DWORD file_system_name_size);
BOOL FileTimeToDosDateTime(const FILETIME *file_time, LPWORD fat_date, LPWORD fat_time);
BOOL DosDateTimeToFileTime(WORD fat_date, WORD fat_time, LPFILETIME file_time);
BOOL SetFileTime(HANDLE file, const FILETIME *creation_time, const FILETIME *last_access_time, const FILETIME *last_write_time);
void GlobalMemoryStatus(LPMEMORYSTATUS buffer);
HANDLE GetCurrentProcess(void);
HANDLE GetCurrentThread(void);
BOOL DuplicateHandle(HANDLE source_process, HANDLE source_handle, HANDLE target_process, HANDLE *target_handle, DWORD desired_access, BOOL inherit_handle, DWORD options);
void OutputDebugString(LPCSTR string);
void GetSystemTime(LPSYSTEMTIME system_time);
void GetLocalTime(LPSYSTEMTIME system_time);
LONG RegOpenKeyEx(HKEY key, LPCSTR sub_key, DWORD options, DWORD sam_desired, HKEY *result);
LONG RegQueryValue(HKEY key, LPCSTR sub_key, LPSTR data, LONG *size);
LONG RegQueryValueEx(HKEY key, LPCSTR value_name, LPDWORD reserved, LPDWORD type, LPBYTE data, LPDWORD size);
LONG RegCloseKey(HKEY key);
BOOL CreateProcess(LPCSTR application_name, LPSTR command_line, LPSECURITY_ATTRIBUTES process_attributes, LPSECURITY_ATTRIBUTES thread_attributes, BOOL inherit_handles, DWORD creation_flags, LPVOID environment, LPCSTR current_directory, STARTUPINFO *startup_info, PROCESS_INFORMATION *process_information);
void Sleep(DWORD milliseconds);
DWORD htonl(DWORD hostlong);
DWORD ntohl(DWORD netlong);
WORD htons(WORD hostshort);
WORD ntohs(WORD netshort);
#ifdef __cplusplus
}
#endif

#endif

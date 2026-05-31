#ifndef BATTLECONTROL_RA_WIN32_SHIM_OBJBASE_H
#define BATTLECONTROL_RA_WIN32_SHIM_OBJBASE_H

#include "windows.h"

#ifdef __cplusplus

struct IUnknown {
    virtual HRESULT QueryInterface(REFIID, LPVOID *) = 0;
    virtual ULONG AddRef(void) = 0;
    virtual ULONG Release(void) = 0;
};

#ifndef DECLARE_INTERFACE
#define DECLARE_INTERFACE(iface) struct iface
#endif
#ifndef DECLARE_INTERFACE_
#define DECLARE_INTERFACE_(iface, base) struct iface : public base
#endif
#ifndef STDMETHOD
#define STDMETHOD(method) virtual HRESULT WINAPI method
#endif
#ifndef STDMETHOD_
#define STDMETHOD_(type, method) virtual type WINAPI method
#endif
#ifndef THIS
#define THIS void
#endif
#ifndef THIS_
#define THIS_
#endif
#ifndef PURE
#define PURE = 0
#endif

#else

typedef void IUnknown;

#endif

#endif

#ifndef BATTLECONTROL_RA_LINUX_COMPAT_PHONE_H
#define BATTLECONTROL_RA_LINUX_COMPAT_PHONE_H

#include <cstring>

class PhoneEntryClass
{
public:
    enum PhoneEntryEnum {
        PHONE_MAX_NAME = 21,
        PHONE_MAX_NUM = 21
    };

    PhoneEntryClass(void)
    {
        Name[0] = '\0';
        Number[0] = '\0';
        Settings.Port = 0;
        Settings.IRQ = -1;
        Settings.Baud = -1;
        Settings.DialMethod = DIAL_TOUCH_TONE;
        Settings.InitStringIndex = 0;
        Settings.CallWaitStringIndex = CALL_WAIT_CUSTOM;
        Settings.CallWaitString[0] = '\0';
        Settings.Compression = false;
        Settings.ErrorCorrection = false;
        Settings.HardwareFlowControl = true;
        Settings.ModemName[0] = '\0';
    }

    bool operator==(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) == 0; }
    bool operator!=(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) != 0; }
    bool operator>(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) > 0; }
    bool operator<(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) < 0; }
    bool operator>=(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) >= 0; }
    bool operator<=(const PhoneEntryClass& obj) const { return std::strcmp(Name, obj.Name) <= 0; }

    SerialSettingsType Settings;
    char Name[PHONE_MAX_NAME];
    char Number[PHONE_MAX_NUM];
};

#endif

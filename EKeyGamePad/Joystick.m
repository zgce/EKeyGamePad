//========================================================================
// GLFW 3.0 OS X - www.glfw.org
//------------------------------------------------------------------------
// Copyright (c) 2009-2010 Camilla Berglund <elmindreda@elmindreda.org>
// Copyright (c) 2012 Torsten Walluhn <tw@mad-cad.net>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

//  Joystack.m
//  GamePadEnum
//  手柄发现的连接的代码来自于GLFW，上头是GLFW的声明

#import <mach/mach.h>
#import <mach/mach_error.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDKeys.h>
#import <Kernel/IOKit/hidsystem/IOHIDUsageTables.h>
#import "Joystick.h"

#ifdef __cplusplus
extern "C" {
#endif
    
#define JOY_PRESS 1.0f
#define JOY_RELEASE 0.0f

typedef struct GamePadT {
    bool present;
    char name[256];
    
    IOHIDDeviceInterface** interface;
    
    CFMutableArrayRef axisElements;
    CFMutableArrayRef buttonElements;
    CFMutableArrayRef hatElements;
    
    long nAixCount;
    long nButtonCount;
    float * vAixes;
    float * vButtons;
    
} joy_t;
static joy_t g_joy[JOY_MAX_COUNT];

typedef struct {
    IOHIDElementCookie cookie;
    long min;
    long max;
    
    long minReport;
    long maxReport;
} joyelement_t;

static void removeJoystick(joy_t * joystick) {
    if(!joystick->present) {
        return;
    }
    
    joystick->nAixCount = 0;
    joystick->nButtonCount = 0;
    free(joystick->vAixes);
    free(joystick->vButtons);
    joystick->vAixes = 0;
    joystick->vButtons = 0;
    
    for(int i = 0; i < CFArrayGetCount(joystick->axisElements); ++i) {
        free((void*) CFArrayGetValueAtIndex(joystick->axisElements, i));
    }
    CFArrayRemoveAllValues(joystick->axisElements);
    
    for(int i = 0; i < CFArrayGetCount(joystick->buttonElements); ++i) {
        free((void*) CFArrayGetValueAtIndex(joystick->buttonElements, i));
    }
    CFArrayRemoveAllValues(joystick->buttonElements);
    
   for(int i = 0; i < CFArrayGetCount(joystick->hatElements); ++i) {
        free((void*) CFArrayGetValueAtIndex(joystick->hatElements, i));
    }
    CFArrayRemoveAllValues(joystick->hatElements);
    
    (*(joystick->interface))->close(joystick->interface);
    (*(joystick->interface))->Release(joystick->interface);
}

static void removeCallback(void * target, IOReturn result, void * refcon, void * sender) {
    removeJoystick((joy_t*)refcon);
}

static void getElementCFArrayHandler(void const * value, void * parameter);
    
static void addJoystickElement(joy_t * joystick, CFTypeRef elementRef) {
    long elementType = 0, usagePage = 0, usage = 0;
    CFMutableArrayRef elementsArray = NULL;
    
    CFNumberGetValue(
                     CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementTypeKey)),
                     kCFNumberLongType,
                     &elementType);
    CFNumberGetValue(
                     CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementUsagePageKey)),
                     kCFNumberLongType,
                     &usagePage);
    CFNumberGetValue(
                     CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementUsageKey)),
                     kCFNumberLongType,
                     &usage);
    
    if((elementType == kIOHIDElementTypeInput_Axis)
       || (elementType == kIOHIDElementTypeInput_Button)
       || (elementType == kIOHIDElementTypeInput_Misc))
    {
        switch(usagePage) {
            case kHIDPage_GenericDesktop:
            {
                switch (usage) {
                    case kHIDUsage_GD_X:
                    case kHIDUsage_GD_Y:
                    case kHIDUsage_GD_Z:
                    case kHIDUsage_GD_Rx:
                    case kHIDUsage_GD_Ry:
                    case kHIDUsage_GD_Rz:
                    case kHIDUsage_GD_Slider:
                    case kHIDUsage_GD_Dial:
                    case kHIDUsage_GD_Wheel:
                        elementsArray = joystick->axisElements;
                        break;
                    case kHIDUsage_GD_Hatswitch:
                        elementsArray = joystick->hatElements;
                    default:
                        break;
                }
            }
                break;
            case kHIDPage_Button:
                elementsArray = joystick->buttonElements;
                break;
            default:
                break;
        }
    
        if(elementsArray) {
            long number;
            CFTypeRef numberRef;
            
            joyelement_t * element = calloc(1, sizeof(joyelement_t));
            CFArrayAppendValue(elementsArray, element);
            
            numberRef = CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementCookieKey));
            if(numberRef && CFNumberGetValue(numberRef, kCFNumberLongType, &number)) {
                element->cookie = (IOHIDElementCookie)number;
            }
            
            numberRef = CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementMinKey));
            if(numberRef && CFNumberGetValue(numberRef, kCFNumberLongType, &number)) {
                element->minReport = element->min = number;
            }
            
            numberRef = CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementMaxKey));
            if(numberRef && CFNumberGetValue(numberRef, kCFNumberLongType, &number)) {
                element->maxReport = element->max = number;
            }
        }
    }
    else {
        CFTypeRef array = CFDictionaryGetValue(elementRef, CFSTR(kIOHIDElementKey));
        if(array) {
            if(CFGetTypeID(array) == CFArrayGetTypeID()) {
                CFRange range = {0, CFArrayGetCount(array)};
                CFArrayApplyFunction(array, range, getElementCFArrayHandler, joystick);
            }
        }
    }
}

static void getElementCFArrayHandler(void const * value, void * parameter) {
    if(CFGetTypeID(value) == CFDictionaryGetTypeID()) {
        addJoystickElement((joy_t*) parameter, (CFTypeRef) value);
    }
}

static long getElementValue(joy_t * joystick, joyelement_t * element) {
    IOReturn result = kIOReturnSuccess;
    IOHIDEventStruct hidEvent;
    hidEvent.value = 0;
    
    if(joystick && element && joystick->interface) {
        result = (*(joystick->interface))->getElementValue(joystick->interface,
                                                           element->cookie,
                                                           &hidEvent);
        if(kIOReturnSuccess == result) {
            if(hidEvent.value < element->minReport) {
                element->minReport = hidEvent.value;
            }
            if(hidEvent.value > element->maxReport) {
                element->maxReport = hidEvent.value;
            }
        }
    }
    
    return (long)hidEvent.value;
}

int initJoysticks(void) {
    for(unsigned pos = 0; pos < JOY_MAX_COUNT; ++pos) {
        joy_t * joystick = &(g_joy[pos]);
        memset(joystick->name, 0, sizeof(joystick->name));
        joystick->interface = 0;
        joystick->present = false;
        joystick->vAixes = 0;
        joystick->vButtons = 0;
        joystick->nButtonCount = 0;
        joystick->nAixCount = 0;
    }
    
    mach_port_t masterPort = 0;
    IOReturn result = IOMasterPort(bootstrap_port, &masterPort);
    CFMutableDictionaryRef hidMatchDictionary = IOServiceMatching(kIOHIDDeviceKey);
    if (kIOReturnSuccess != result || !hidMatchDictionary)
    {
        if (hidMatchDictionary)
            CFRelease(hidMatchDictionary);
        
        return false;
    }
 
    io_iterator_t objectIterator = 0;
    result = IOServiceGetMatchingServices(masterPort, hidMatchDictionary, &objectIterator);
    if(kIOReturnSuccess != result) {
        return false;
    }
    if(!objectIterator) {
        return false;
    }
    
    unsigned joyCount = 0;
    io_object_t ioHIDDeviceObject = 0;
    while((joyCount < JOY_MAX_COUNT) && (ioHIDDeviceObject = IOIteratorNext(objectIterator))) {
        CFMutableDictionaryRef propsRef = NULL;
        
        result = IORegistryEntryCreateCFProperties(ioHIDDeviceObject,
                                                   &propsRef,
                                                   kCFAllocatorDefault,
                                                   kNilOptions);
        
        if(kIOReturnSuccess != result) {
            continue;
        }
        
        long usagePage;
        CFTypeRef valueRef = CFDictionaryGetValue(propsRef, CFSTR(kIOHIDPrimaryUsagePageKey));
        if(valueRef) {
            CFNumberGetValue(valueRef, kCFNumberLongType, &usagePage);
            if(kHIDPage_GenericDesktop != usagePage) {
                CFRelease(valueRef);
                continue;
            }
            
            CFRelease(valueRef);
        }
        
        long usage;
        valueRef = CFDictionaryGetValue(propsRef, CFSTR(kIOHIDPrimaryUsageKey));
        if(valueRef) {
            CFNumberGetValue(valueRef, kCFNumberLongType, &usage);
           
            if(usage != kHIDUsage_GD_Joystick
               && usage != kHIDUsage_GD_GamePad
               && usage != kHIDUsage_GD_MultiAxisController)
            {
                CFRelease(valueRef);
                continue;
            }
            
            CFRelease(valueRef);
        }
        
        IOCFPlugInInterface ** ppPlugInInterface = NULL;
        SInt32 score = 0;
        result = IOCreatePlugInInterfaceForService(ioHIDDeviceObject,
                                                   kIOHIDDeviceUserClientTypeID,
                                                   kIOCFPlugInInterfaceID,
                                                   &ppPlugInInterface,
                                                   &score);
        
        if(kIOReturnSuccess != result) {
            return false;
        }
        
        joy_t * joystick = &(g_joy[joyCount]);
        joystick->present = true;
        HRESULT plugInResult = (*ppPlugInInterface)->QueryInterface(
                                                                    ppPlugInInterface,
                                                                    CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID),
                                                                    (void*) &(joystick->interface));
        if(S_OK != plugInResult) {
            return false;
        }
        
        (*ppPlugInInterface)->Release(ppPlugInInterface);
        (*(joystick->interface))->open(joystick->interface, 0);
        (*(joystick->interface))->setRemovalCallback(joystick->interface,
                                                     removeCallback,
                                                     joystick,
                                                     joystick);
        
        valueRef = CFDictionaryGetValue(propsRef, CFSTR(kIOHIDProductKey));
        if(valueRef) {
            CFStringGetCString(valueRef,
                               joystick->name,
                               sizeof(joystick->name),
                               kCFStringEncodingUTF8);
            CFRelease(valueRef);
        }
        
        joystick->axisElements = CFArrayCreateMutable(NULL, 0, NULL);
        joystick->buttonElements = CFArrayCreateMutable(NULL, 0, NULL);
        joystick->hatElements = CFArrayCreateMutable(NULL, 0, NULL);
        
        valueRef = CFDictionaryGetValue(propsRef, CFSTR(kIOHIDElementKey));
        if(CFGetTypeID(valueRef) == CFArrayGetTypeID()) {
            CFRange range = {0, CFArrayGetCount(valueRef)};
            CFArrayApplyFunction(valueRef,
                                 range,
                                 getElementCFArrayHandler,
                                 (void*) joystick);
            CFRelease(valueRef);
        }
        
        joystick->nAixCount = CFArrayGetCount(joystick->axisElements);
        joystick->nButtonCount = CFArrayGetCount(joystick->buttonElements);
        joystick->vAixes = (float*)malloc(joystick->nAixCount * sizeof(float));
        joystick->vButtons = (float*)malloc(joystick->nButtonCount * sizeof(float));
        memset(joystick->vAixes, 0, joystick->nAixCount * sizeof(float));
        memset(joystick->vButtons, 0, joystick->nButtonCount * sizeof(float));
        
        NSLog(@"get GamePad[%d] name[%s] axis[%ld] buttons[%ld]",
              joyCount,
              joystick->name,
              joystick->nAixCount,
              joystick->nButtonCount);
        
        
        joyCount += 1;
    }
    
    return joyCount;
}

void terminateJoysticks(void) {
    for(int pos = 0; pos < JOY_MAX_COUNT; ++pos) {
        joy_t * joystick = &(g_joy[pos]);
        removeJoystick(joystick);
    }
}

joy_t * getJoystick(long n) {
    if((n < JOY_MAX_COUNT) && g_joy[n].present) {
        return &(g_joy[n]);
    }
    else {
        return 0;
    }
}

char const * getJoystickName(joy_t * joystick) {
    return joystick->name;
}

long getJoystickAixCount(joy_t * joystick) {
    return joystick->nAixCount;
}

long getJoystickButtonCount(joy_t * joystick) {
    return joystick->nButtonCount;
}

bool joystickPresent(joy_t * joystick) {
    if(!joystick->present) {
        return false;
    }
    
    int buttonIndex = 0;
    for(CFIndex pos = 0; pos < CFArrayGetCount(joystick->buttonElements); ++pos) {
        joyelement_t * button = (joyelement_t*) CFArrayGetValueAtIndex(joystick->buttonElements, pos);
        if(getElementValue(joystick, button)) {
            joystick->vButtons[buttonIndex++] = JOY_PRESS;
        }
        else {
            joystick->vButtons[buttonIndex++] = JOY_RELEASE;
        }
    }
    
    for(CFIndex pos = 0; pos < CFArrayGetCount(joystick->axisElements); ++pos) {
        joyelement_t * axis = (joyelement_t*)CFArrayGetValueAtIndex(joystick->axisElements, pos);
        
        long value = getElementValue(joystick, axis);
        long readScale = axis->maxReport - axis->minReport;
        
        if(0 == readScale) {
            joystick->vAixes[pos] = value;
        }
        else {
            joystick->vAixes[pos] = (2.0f * (value - axis->minReport) / readScale) - 1.0f;
        }
    }
    
    for(CFIndex pos = 0; pos < CFArrayGetCount(joystick->hatElements); ++pos) {
        joyelement_t * hat = (joyelement_t*)CFArrayGetValueAtIndex(joystick->hatElements, pos);
        // Bit fields of button presses for each direction, including nil
        const int directions[9] = {1, 3, 2, 6, 4, 12, 8, 9, 0};
        
        long value = getElementValue(joystick, hat);
        value = ((value < 0 || value > 8) ? 8 : value);
        
        for(long j = 0; j < 4; ++j) {
            if(directions[value] & (1 << j)) {
                joystick->vButtons[buttonIndex++] = JOY_PRESS;
            }
            else {
                joystick->vButtons[buttonIndex++] = JOY_RELEASE;
            }
        }
    }
    
    return true;
}

float const * getJoystickAixStatus(joy_t * joystick, long * nAixCount) {
    if(nAixCount) {
        *nAixCount = joystick->nAixCount;
    }
    return joystick->vAixes;
}

float const * getJoystickButtonStatus(joy_t * joystick, long * nButtonCount) {
    if(nButtonCount) {
        *nButtonCount = joystick->nButtonCount;
    }
    
    return joystick->vButtons;
}

#ifdef __cplusplus
}
#endif
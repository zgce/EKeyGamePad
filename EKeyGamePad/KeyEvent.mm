#include  <string>
#include  "JoyConvertKey.hpp"
#include  "Joystick.h"
#include  "KeyEvent.h"

KeyEventGuard::KeyEventGuard(unsigned short _ch)
    : ch_(_ch)
{
    generatorKeyDownEvent(ch_);
}

KeyEventGuard::~KeyEventGuard() throw() {
    generatorKeyUpEvent(ch_);
}

unsigned short const & KeyEventGuard::keyValue(void) const {
    return ch_;
}

void KeyEventGuard::generatorKeyDownEvent(unsigned short ch) const {
    sendEvent(ch, true);
    NSLog(@"send key down event %d", ch);
}

void KeyEventGuard::generatorKeyUpEvent(unsigned short ch) const {
    sendEvent(ch, false);
    NSLog(@"send key up event %d", ch);
}

void KeyEventGuard::sendEvent(unsigned short ch, bool flag) const {
    CGEventRef keyevent;
    keyevent = CGEventCreateKeyboardEvent(NULL, (CGKeyCode)ch, flag);
    CGEventPost(kCGHIDEventTap, keyevent);
    CFRelease(keyevent);
}

void resetKeyVector(KeyEventVector & guards, long n) {
    for(KeyEventVector::iterator it = guards.begin();
        it != guards.end();
        ++it)
    {
        delete (*it);
    }
    
    guards.resize(n, 0);
}

static void process_key_event(KeyEventVector& vbuf, long pos, std::vector<unsigned short> const & vp) {
    KeyEventGuard *ke = vbuf[pos];
    if(0 == vbuf[pos] && 0 != vp[pos]) {
        vbuf[pos] = new KeyEventGuard(vp[pos]);
    }
    
    if(0 != vbuf[pos]) {
        if(0 == vp[pos]) {
            delete ke;
            vbuf[pos] = 0;
        }
        else if(vbuf[pos]->keyValue() != vp[pos]) {
            delete ke;
            vbuf[pos] = new KeyEventGuard(vp[pos]);
        }
    }
}

void process_key_event(long nJoyPos, JoyConvertKey const & convertor, KeyEventVector & aixKeys, KeyEventVector & buttonKeys) {
    if(-1 != nJoyPos && nJoyPos < JOY_MAX_COUNT) {
        joy_t *joy = getJoystick(nJoyPos);
        long nAixCount = 0, nButtonCount = 0;
        joystickPresent(joy);
        float const * aixes = getJoystickAixStatus(joy, &nAixCount);
        float const * buttons = getJoystickButtonStatus(joy, &nButtonCount);
        
        std::vector<unsigned short> vp, bp;
        convertor.convertAixes(aixes, nAixCount, vp);
        for(long pos = 0; pos < nAixCount; ++pos) {
            
            if(aixKeys.size() == nAixCount) {
                process_key_event(aixKeys,  pos, vp);
            }
        }
        
        convertor.convertButtons(buttons, nButtonCount, bp);
        for(long pos = 0; pos < nButtonCount; ++pos) {
            if(buttonKeys.size() == nButtonCount) {
                process_key_event(buttonKeys,  pos, bp);
            }
        }
    }
}

std::string macBundlePath(void) {
    char path[1024];
    CFBundleRef mainBundle = CFBundleGetMainBundle();
    assert(mainBundle);
    
    CFURLRef mainBundleURL = CFBundleCopyBundleURL(mainBundle);
    assert(mainBundleURL);
    
    CFStringRef cfStringRef = CFURLCopyFileSystemPath(mainBundleURL, kCFURLPOSIXPathStyle);
    assert(cfStringRef);
    
    CFStringGetCString(cfStringRef, path, sizeof(path), kCFStringEncodingASCII);
    
    CFRelease(mainBundleURL);
    CFRelease(cfStringRef);
    
    return std::string(path);
}
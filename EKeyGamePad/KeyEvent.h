#pragma once
#ifndef _GAMEPADENUM_KEYEVENT_H_INCLUDE_
#define _GAMEPADENUM_KEYEVENT_H_INCLUDE_

#include <vector>

class KeyEventGuard {
public:
    KeyEventGuard(unsigned short _ch);
    
    ~KeyEventGuard() throw();
    unsigned short const & keyValue(void) const;
    
private:
    void generatorKeyDownEvent(unsigned short ch) const;
    
    void generatorKeyUpEvent(unsigned short ch) const;
    void sendEvent(unsigned short ch, bool flag) const;
private:
    unsigned short ch_;
};
typedef std::vector<KeyEventGuard*> KeyEventVector;

std::string macBundlePath();
void resetKeyVector(KeyEventVector & guards, long n);

class JoyConvertKey;
void process_key_event(long nJoyPos, JoyConvertKey const & convertor, KeyEventVector & aixKeys, KeyEventVector & buttonKeys);

#endif //_GAMEPADENUM_KEYEVENT_H_INCLUDE_

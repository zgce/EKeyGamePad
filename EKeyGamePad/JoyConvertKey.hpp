#pragma once
#ifndef _GAMEPADENUM_JOYCONVERTKEY_INCLUDE_HPP_
#define _GAMEPADENUM_JOYCONVERTKEY_INCLUDE_HPP_
#include <vector>
#include <map>

struct ConvertKey {
    long num;
    float value;
    std::string keyname;
};

class JoyConvertKey {
public:
    typedef std::map<std::string, unsigned short> KeyCodeContainer;
    typedef std::vector<ConvertKey> ConvertKeyContainer;
    
    JoyConvertKey(void);
    
    ~JoyConvertKey() throw();
    
    bool convertAixes(float const * vAixes, long nAixesCount, std::vector<unsigned short> & vp) const;
    bool convertButtons(float const * vButtons, long nButtonsCount, std::vector<unsigned short> & vp) const;
    
    void copyAixesConvertor(ConvertKeyContainer & aixes) const;
    void copyButtonConvertor(ConvertKeyContainer & buttons) const;
    
    bool loadConvert(std::string const & configFile);
    bool isLoad(void) const;
    
private:
    ConvertKeyContainer::const_iterator find_convert(ConvertKeyContainer const & cons, long num, float value) const;
    
    ConvertKeyContainer aixconvert_;
    ConvertKeyContainer buttonconvert_;
    KeyCodeContainer keycodes_;
};

#endif //_GAMEPADENUM_JOYCONVERTKEY_INCLUDE_HPP_

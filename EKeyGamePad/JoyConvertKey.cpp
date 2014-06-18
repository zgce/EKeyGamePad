#include <boost/filesystem.hpp>
#include <boost/property_tree/xml_parser.hpp>
#include <boost/typeof/typeof.hpp>
#include "JoyConvertKey.hpp"
#include "KeyEvent.h"

JoyConvertKey::JoyConvertKey(void)
{
    std::string codefile = macBundlePath() + "/Contents/Resources/keycode.xml";
    boost::property_tree::ptree xmlpt;
    boost::property_tree::xml_parser::read_xml(codefile, xmlpt);
    boost::property_tree::ptree codept = xmlpt.get_child("keycode");
    for(BOOST_AUTO(pos,codept.begin()); pos != codept.end(); ++pos) {
        std::stringstream ss;
        ss << std::hex << pos->second.get<std::string>("<xmlattr>.code");
        unsigned short code = 0;
        ss >> code;
        keycodes_.insert(std::make_pair(pos->second.get<std::string>("<xmlattr>.name"), code));
    }
}

bool JoyConvertKey::loadConvert(std::string const & _configFile) {
    if(!boost::filesystem::exists(_configFile)) {
        return false;
    }
    //确保函数可以反复调用
    aixconvert_.clear();
    buttonconvert_.clear();
    
    boost::property_tree::ptree pt;
    boost::property_tree::xml_parser::read_xml(
        _configFile, pt, boost::property_tree::xml_parser::trim_whitespace | boost::property_tree::xml_parser::no_comments);
    
    boost::property_tree::ptree aixpt = pt.get_child("ConvertKey.Aixes");
    for(BOOST_AUTO(pos,aixpt.begin()); pos != aixpt.end(); ++pos) {
        ConvertKey tk;
        tk.num = pos->second.get<long>("<xmlattr>.num");
        tk.value = pos->second.get<float>("<xmlattr>.value");
        tk.keyname = pos->second.get<std::string>("<xmlattr>.key");
        aixconvert_.push_back(tk);
    }
    
    boost::property_tree::ptree buttonpt = pt.get_child("ConvertKey.Buttons");
    for(BOOST_AUTO(pos,buttonpt.begin()); pos != buttonpt.end(); ++pos) {
        ConvertKey tk;
        tk.num = pos->second.get<long>("<xmlattr>.num");
        tk.value = pos->second.get<float>("<xmlattr>.value");
        tk.keyname = pos->second.get<std::string>("<xmlattr>.key");
        buttonconvert_.push_back(tk);
    }
    
    return true;
}

JoyConvertKey::~JoyConvertKey() throw() {
}

JoyConvertKey::ConvertKeyContainer::const_iterator
JoyConvertKey::find_convert(ConvertKeyContainer const & cons, long num, float value) const {
    bool bFound = false;
    ConvertKeyContainer::const_iterator it = cons.begin();
    for(; !bFound && it != cons.end(); ++it) {
        if((it->num == num) && (it->value == value)) {
            bFound = true;
        }
    }
    
    return bFound ? it : cons.end();
}

bool JoyConvertKey::convertAixes(float const * vAixes, long nAixesCount, std::vector<unsigned short> & vp) const {
    vp.resize(nAixesCount, 0);
    for(long pos = 0; pos < nAixesCount; ++pos) {
        ConvertKey tk;
        tk.num = pos;
        tk.value = vAixes[pos];
        
        ConvertKeyContainer::const_iterator it = find_convert(aixconvert_, pos, vAixes[pos]);
        if(it != aixconvert_.end()) {
            KeyCodeContainer::const_iterator iter = keycodes_.find(it->keyname);
            
            if(iter != keycodes_.end()) {
                vp[pos] = iter->second;
            }
        }
    }
    return true;
}

bool JoyConvertKey::convertButtons(float const * vButtons, long nButtonsCount, std::vector<unsigned short> & vp) const {
    vp.resize(nButtonsCount, 0);
    for(long pos = 0; pos < nButtonsCount; ++pos) {
        ConvertKey tk;
        tk.num = pos;
        tk.value = vButtons[pos];
        
        ConvertKeyContainer::const_iterator it = find_convert(buttonconvert_, pos, vButtons[pos]);
        if(it != buttonconvert_.end()) {
            KeyCodeContainer::const_iterator iter = keycodes_.find(it->keyname);
            
            if(iter != keycodes_.end()) {
                vp[pos] = iter->second;
            }
        }
    }
    
    return true;
}

bool JoyConvertKey::isLoad(void) const {
    return (!aixconvert_.empty());
}

void JoyConvertKey::copyAixesConvertor(ConvertKeyContainer & aixes) const {
    for(ConvertKeyContainer::const_iterator it = aixconvert_.begin();
        it != aixconvert_.end();
        ++it)
    {
        aixes.push_back(*it);
    }
}

void JoyConvertKey::copyButtonConvertor(ConvertKeyContainer & buttons) const {
    for(ConvertKeyContainer::const_iterator it = buttonconvert_.begin();
        it != buttonconvert_.end();
        ++it)
    {
        buttons.push_back(*it);
    }
}
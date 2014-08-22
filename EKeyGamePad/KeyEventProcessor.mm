#import <string>
#import <boost/filesystem.hpp>
#import "KeyEventProcessor.h"
#import "Joystick.h"
#import "KeyEvent.h"
#import "JoyConvertKey.hpp"

struct KeyProcessWrapper{
    KeyEventVector aixKeys;
    KeyEventVector buttonKeys;
    JoyConvertKey convertor;
    long joyNum;
    
    void check_key(void) {
        process_key_event(joyNum, convertor, aixKeys, buttonKeys);
    }
};

static std::string keyConvertFile(void) {
    return macBundlePath() + "/Contents/Resources/convertkey.xml";
}

@implementation KeyEventProcessor

- (void)doCheckJoyKey {
    processor->check_key();
}

- (id)init {
    self = [super init];
    
    if(self) {
        processor = new KeyProcessWrapper;
        processor->convertor.loadConvert(keyConvertFile());
        convertfile = [NSString stringWithUTF8String: keyConvertFile().c_str()];
    }
    
    return self;
}

- (void)dealloc {
    [self stop];
    delete processor;
}

- (bool)start:(long)nCurJoyNum {
    if(!processor->convertor.isLoad()) {
        return false;
    }
    
    processor->joyNum = nCurJoyNum;
    ekjoy_t * joysitck = getJoystick(nCurJoyNum);
    
    resetKeyVector(processor->aixKeys, getJoystickAixCount(joysitck));
    resetKeyVector(processor->buttonKeys, getJoystickButtonCount(joysitck));
    
#ifdef MAC_OS_X_VERSION_10_9
    //下面这句是为了阻止APP NAP 这是10.9新引入的省电特性 害了我好久
    self.activity = [[NSProcessInfo processInfo]
                        beginActivityWithOptions:NSActivityUserInitiatedAllowingIdleSystemSleep reason:@"good news"];
#endif
    if(nil == timer) {
        timer = [NSTimer
                    timerWithTimeInterval:1.0/50
                    target:self
                    selector:@selector(doCheckJoyKey)
                    userInfo:nil
                    repeats:YES];
    }
    
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    NSLog(@"process key timer start!");
    
    return true;
}

- (void)stop {
    if(nil != timer) {
        [timer invalidate];
        timer = nil;
        NSLog(@"process key timer stop!");
    }
    
#ifdef MAC_OS_X_VERSION_10_9
    [[NSProcessInfo processInfo] endActivity:[self activity]]; //再把NAP给打开
    self.activity = nil;
#endif
}

- (bool)getAixValue:(float const *)vAixes AixCount:(NSInteger)nAixCount AixValue:(unichar*)vp
{
    std::vector<unichar> tvp(nAixCount, 0);
    bool ret = processor->convertor.convertAixes(vAixes, nAixCount, tvp);
    memcpy(vp, &(tvp[0]), nAixCount* sizeof(unichar));
    
    return ret;
}

- (bool)getButtonValue:(float const *)vButtons ButtonCount:(NSInteger)nButtonCount ButtonValue:(unichar*)vp
{
    std::vector<unichar> tvp(nButtonCount, 0);
    bool ret = processor->convertor.convertButtons(vButtons, nButtonCount, tvp);
    memcpy(vp, &(tvp[0]), nButtonCount * sizeof(unichar));
    
    return ret;
}

- (bool)loadConvertFile:(NSString*)fileName {
    convertfile = [NSString stringWithString: fileName];
    
    std::string str([fileName UTF8String]);
    return processor->convertor.loadConvert(str);
}

- (NSString*)convertFile {
    std::string str([convertfile UTF8String]);
    
    boost::filesystem::path fullname(str);
    std::string filename = fullname.filename().string();
    
    return [NSString stringWithUTF8String: filename.c_str()];
}

- (NSArray*)getKeyMapInfos {
    NSMutableArray * result = [[NSMutableArray alloc] init];
    
    JoyConvertKey::ConvertKeyContainer aixes;
    processor->convertor.copyAixesConvertor(aixes);
    for(JoyConvertKey::ConvertKeyContainer::iterator it = aixes.begin();
        it != aixes.end();
        ++it)
    {
        KeyMapInfo * info = [[KeyMapInfo alloc] init];
        
        [info setJType: [NSString stringWithFormat:@"Aix_%ld", it->num]
              setJValue: it->value
              setKName: [NSString stringWithUTF8String: it->keyname.c_str()]];
        
        [result addObject:info];
    }
    
    JoyConvertKey::ConvertKeyContainer buttons;
    processor->convertor.copyButtonConvertor(buttons);
    for(JoyConvertKey::ConvertKeyContainer::iterator it = buttons.begin();
        it != buttons.end();
        ++it)
    {
        KeyMapInfo * info = [[KeyMapInfo alloc] init];
        [info setJType: [NSString stringWithFormat:@"Button_%ld", it->num]
              setJValue: it->value
              setKName: [NSString stringWithUTF8String: it->keyname.c_str()]];
        
        [result addObject:info];
    }
    
    return result;
}

@end

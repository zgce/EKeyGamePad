//
//  KeyMapInfo.m
//  EKeyGamePad
//
//  Created by 余 翔 on 14-6-8.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//

#import "KeyMapInfo.h"

@implementation KeyMapInfo

- (void)setJType:(NSString*)jt setJValue:(float)jv setKName:(NSString*)kn {
    joytype = [NSString stringWithString: jt];
    value = jv;
    keyname = [NSString stringWithString: kn];
}

- (NSString*)jtype {
    return joytype;
}

- (float)jValue {
    return value;
}

- (NSString*)kName {
    return keyname;
}

@end

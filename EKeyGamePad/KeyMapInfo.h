//
//  KeyMapInfo.h
//  EKeyGamePad
//
//  Created by 余 翔 on 14-6-8.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KeyMapInfo : NSObject
{
    NSString * joytype;
    float value;
    NSString * keyname;
}

- (void)setJType:(NSString*)jtype setJValue:(float)jvalue setKName:(NSString*)kName;

- (NSString*)jtype;
- (float)jValue;
- (NSString*)kName;

@end

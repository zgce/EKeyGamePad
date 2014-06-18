//
//  KeyEventProcessor.h
//  EKeyGamePad
//
//  Created by 余 翔 on 14-5-25.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//  这个文件是为了隔离C++与Objc之间的头文件依赖

#import <Foundation/Foundation.h>
#import "KeyMapInfo.h"

@interface KeyEventProcessor : NSObject
{
    struct KeyProcessWrapper;
    struct KeyProcessWrapper* processor;
    
    NSTimer * timer;
    NSString * convertfile;
}

@property (strong) id activity;

- (id)init;
- (void)dealloc;

- (void)doCheckJoyKey;

- (bool)start:(long)nCurJoyNum;
- (void)stop;

- (bool)getAixValue:(float const *)vAixes AixCount:(NSInteger)nAixCount AixValue:(unichar*)vp;
- (bool)getButtonValue:(float const *)vButtons ButtonCount:(NSInteger)nButtonCount ButtonValue:(unichar*)vp;

- (bool)loadConvertFile:(NSString*)fileName;
- (NSString*)convertFile;

- (NSArray*)getKeyMapInfos;

@end

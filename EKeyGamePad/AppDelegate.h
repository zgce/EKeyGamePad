//
//  AppDelegate.h
//  EKeyGamePad
//
//  Created by 余 翔 on 14-5-25.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyEventProcessor.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    NSMutableArray *joyEKeys;
    NSString * curConfigFileName;
    NSInteger nCurJoyNum;
    
    KeyEventProcessor * keyprocessor;
    
    unichar* vp;
    unichar* bp;
}

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSComboBox *cmbGamepad;
@property (weak) IBOutlet NSButton *btnSelConf;
@property (weak) IBOutlet NSTextField *labConfigFilePath;
@property (weak) IBOutlet NSTextField *labJoyStatus;
@property (weak) IBOutlet NSTextField *labEKeyStatus;
@property (weak) IBOutlet NSArrayController *tabJoyEKey;

- (IBAction)selectGamePad:(id)sender;
- (IBAction)selectConvertor:(id)sender;

- (void)onStatusTimer:(NSTimer*)timer;

- (void) setJoyLabelText:(long)nJoyNum
               AixValues:(float const *)aixes
                AixCount:(long)nAixCount
            ButtonValues:(float const *)buttons
             ButtonCount:(long)nButtonCount;

- (void) setKeyLabelText:(long)nJoyNum
               AixValues:(float const *)aixes
                AixCount:(long)nAixCount
            ButtonValues:(float const *)buttons
             ButtonCount:(long)nButtonCount;

- (void) setKeyMapInfo;

@end

//
//  AppDelegate.m
//  EKeyGamePad
//
//  Created by 余 翔 on 14-5-25.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//

#import "AppDelegate.h"
#import "Joystick.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSLog(@"appdelegate applicationDidFinishLaunching");
    
    nCurJoyNum = -1;
    int const joyCount = initJoysticks();
    if(0 == joyCount) {
        NSLog(@"no gamepad has being found!");
    }
    
    for(unsigned pos = 0; pos < joyCount; ++pos) {
        [[self cmbGamepad] addItemWithObjectValue:
            [NSString stringWithFormat:@"%d %s", (pos+1), getJoystickName(getJoystick(pos))]];
    }
    
    keyprocessor = [[KeyEventProcessor alloc] init];
    
    NSTimer * timer = [NSTimer
                           timerWithTimeInterval:1.0/30
                           target:self
                           selector:@selector(onStatusTimer:)
                           userInfo:nil
                           repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    [[self window] makeFirstResponder:[self cmbGamepad]];
    [[self btnSelConf] setEnabled: NO];
    joyEKeys = [[NSMutableArray alloc] init];
    
    vp = 0, bp = 0;
}

- (IBAction)selectGamePad:(id)sender {
    nCurJoyNum = [[self cmbGamepad] indexOfSelectedItem];
    [keyprocessor stop];
    
    if(vp) {
        free(vp);
        vp = 0;
    }
    
    if(bp) {
        free(bp);
        bp = 0;
    }
    
    NSLog(@"select index: %ld %ld", nCurJoyNum, [[self cmbGamepad] numberOfItems]);
    if(-1 != nCurJoyNum && nCurJoyNum < [[self cmbGamepad] numberOfItems]) {
        [keyprocessor start:nCurJoyNum];
        joy_t *joy = getJoystick(nCurJoyNum);
        vp = (unichar*)malloc(getJoystickAixCount(joy) * sizeof(unichar));
        bp = (unichar*)malloc(getJoystickButtonCount(joy) * sizeof(unichar));
        [[self window] makeFirstResponder:[self btnSelConf]];
        
        [self setKeyMapInfo];
        [[self labConfigFilePath] setStringValue: [keyprocessor convertFile]];
        [[self btnSelConf] setEnabled: YES];
    }
}

- (IBAction)selectConvertor:(id)sender {
    NSOpenPanel * openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles: YES];
    [openDlg setCanChooseDirectories: YES];
    [openDlg setAllowsMultipleSelection: NO];
    
    if( [openDlg runModal] == NSOKButton ) {
        NSArray * files = [openDlg URLs];
        NSString * fileName = [files objectAtIndex: 0];
        NSLog(@"open convert file %@", fileName);
        
        [keyprocessor loadConvertFile: fileName];
        [self setKeyMapInfo];
        [[self labConfigFilePath] setStringValue: [keyprocessor convertFile]];
    }
}

- (void)onStatusTimer:(NSTimer*)timer {
    if(-1 != nCurJoyNum && nCurJoyNum < [[self cmbGamepad] numberOfItems]) {
        joy_t *joy = getJoystick(nCurJoyNum);
        
        long nAixCount = 0, nButtonCount = 0;
        float const * aixes = getJoystickAixStatus(joy, &nAixCount);
        float const * buttons = getJoystickButtonStatus(joy, &nButtonCount);
        
        [self setJoyLabelText:nCurJoyNum
                    AixValues:aixes
                     AixCount:nAixCount
                 ButtonValues:buttons
                  ButtonCount:nButtonCount];
        
        [self setKeyLabelText:nCurJoyNum
                    AixValues:aixes
                     AixCount:nAixCount
                 ButtonValues:buttons
                  ButtonCount:nButtonCount];
    }
}

- (void) setJoyLabelText:(long)nJoyNum
               AixValues:(float const *)aixes
                AixCount:(long)nAixCount
            ButtonValues:(float const *)buttons
             ButtonCount:(long)nButtonCount
{
    joy_t * joy = getJoystick(nJoyNum);
    NSMutableString *txt = [NSMutableString stringWithFormat:@"Select GamePad[%s]", getJoystickName(joy)];
    [txt appendString:[NSString stringWithFormat:@"\n\tAix[%ld]\t", nAixCount]];
    for(long pos = 0; pos < nAixCount; ++pos) {
        [txt appendString:[NSString stringWithFormat:@" [%.2f]", aixes[pos]] ];
    }
    
    [txt appendString:[NSString stringWithFormat:@"\n\tButton[%ld]\t", nButtonCount]];
    
    for(long pos = 0; pos < nButtonCount; ++pos) {
        [txt appendString:[NSString stringWithFormat:@" [%.1f]", buttons[pos]] ];
    }
    
    [[self labJoyStatus] setStringValue:txt];
}

- (void) setKeyLabelText:(long)nJoyNum
               AixValues:(float const *)aixes
                AixCount:(long)nAixCount
            ButtonValues:(float const *)buttons
             ButtonCount:(long)nButtonCount
{
    NSMutableString * txt = [NSMutableString stringWithFormat:@"key press:\t"];
    
    [keyprocessor getAixValue:aixes AixCount:nAixCount AixValue:vp];
    for(long pos = 0; pos < nAixCount; ++pos) {
        [txt appendString:[NSString stringWithFormat:@" [%d]", vp[pos]]];
    }
    
    [keyprocessor getButtonValue:buttons ButtonCount:nButtonCount ButtonValue:bp];
    [txt appendString:[NSString stringWithFormat:@"\nButton:\t"]];
    for(long pos = 0; pos < nButtonCount; ++pos) {
        [txt appendString:[NSString stringWithFormat:@" [%d]", bp[pos]]];
    }
    
    [[self labEKeyStatus] setStringValue:txt];
}

- (void) setKeyMapInfo {
    NSArray * ar = [keyprocessor getKeyMapInfos];
    
    [[self tabJoyEKey] removeObjects: joyEKeys];
    [joyEKeys removeAllObjects];
    for(unsigned pos = 0; pos < [ar count]; ++pos) {
        KeyMapInfo * info = [ar objectAtIndex: pos];
        [joyEKeys addObject: [NSMutableDictionary dictionaryWithObjectsAndKeys:
                              [info jtype], @"GamePadItem",
                              [NSString stringWithFormat: @"%.0f", [info jValue]], @"GamePadValue",
                              [info kName], @"EnumKey",
                              nil]];
    }
    [[self tabJoyEKey] addObjects: joyEKeys];
    [[self tabJoyEKey] setSelectionIndex:0];
}

@end

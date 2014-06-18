//
//  Joystick.h
//  EKeyGamePad
//
//  Created by 余 翔 on 14-4-26.
//  Copyright (c) 2014年 余 翔. All rights reserved.
//

#ifndef _JOYSTICK_H_INCLUDE_
#define _JOYSTICK_H_INCLUDE_

#ifdef __cplusplus
extern "C" {
#endif
    
#define JOY_MAX_COUNT 10 //手柄最多10个，一般不会超过这个数吧

struct GamePadT;
typedef struct GamePadT joy_t;

int initJoysticks(void); //这个返回值表示当前初始化了多少个GamePad
void terminateJoysticks(void);

joy_t * getJoystick(long n); //如果第n个GamePad没有被初始化，则会返回0

char const * getJoystickName(joy_t * joystick);
long getJoystickAixCount(joy_t * joystick);
long getJoystickButtonCount(joy_t * joystick);

bool joystickPresent(joy_t * joystick);

float const * getJoystickAixStatus(joy_t * joystick, long * nAixCount);
float const * getJoystickButtonStatus(joy_t * joystick, long * nButtonCount);

#ifdef __cplusplus
}
#endif


#endif //_JOYSTICK_H_INCLUDE_
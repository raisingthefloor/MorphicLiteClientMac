//
//  KeyEvents.m
//  MorphicSettings
//
//  Created by Owen Shaw on 6/27/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

#import "KeyEvents.h"

@implementation KeyEvents

+ (BOOL)sendSystemWideKeyChar:(CGCharCode)charCode keyCode:(CGKeyCode)keyCode isDown:(BOOL)isDown{
    AXError result = AXUIElementPostKeyboardEvent(AXUIElementCreateSystemWide(), charCode, keyCode, isDown);
    return result == kAXErrorSuccess;
}

@end

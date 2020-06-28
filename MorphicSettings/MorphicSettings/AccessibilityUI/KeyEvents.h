//
//  KeyEvents.h
//  MorphicSettings
//
//  Created by Owen Shaw on 6/27/20.
//  Copyright © 2020 Raising the Floor. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KeyEvents : NSObject

+ (BOOL)sendSystemWideKeyChar:(CGCharCode)charCode keyCode:(CGKeyCode)keyCode isDown:(BOOL)isDown;

@end

NS_ASSUME_NONNULL_END

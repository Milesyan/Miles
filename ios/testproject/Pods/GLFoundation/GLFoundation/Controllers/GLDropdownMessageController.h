//
//  DropdownMessageController.h
//  emma
//
//  Created by Ryan Ye on 4/2/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLDropdownMessageController : UIViewController
- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval
    inWindow:(UIView *)parentWindow;
- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval inView:(UIView *)parentView;
- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval position:(CGFloat)posY inView:(UIView *)parentView;
- (void)clearMessage;
+ (GLDropdownMessageController *)sharedInstance;
@end
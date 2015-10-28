//
//  AlertContainerViewController.h
//  emma
//
//  Created by ltebean on 15-1-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLSlidingViewController.h"

@interface AlertContainerViewController : GLSlidingViewController
- (void)selectNotificationsTabWithAnimation :(BOOL)needsAnimation;
- (void)selectAppointmentsTabWithAnimation:(BOOL)needsAnimation;
- (void)selectRemindersTabWithAnimation:(BOOL)needsAnimation;
@end

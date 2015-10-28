//
//  networkLoadingView.h
//  emma
//
//  Created by Jirong Wang on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLNetworkLoadingView : UIView

+ (GLNetworkLoadingView *)getInstance;
+ (void)show;
+ (void)showWithoutAutoClose;
+ (void)showInWindow:(UIWindow *)window;
+ (void)showWithoutAutoCloseInWindow:(UIWindow *)window;
+ (void)showWithDelay:(CGFloat)delay;
+ (void)showWithDelay:(CGFloat)delay inWindow:(UIWindow *)window;
+ (void)hide;

@end

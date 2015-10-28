//
//  networkLoadingView.h
//  emma
//
//  Created by Jirong Wang on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NetworkLoadingView : UIView

+ (NetworkLoadingView *)getInstance;
+ (void)show;
+ (void)showWithoutAutoClose;
+ (void)showWithDelay:(CGFloat)delay;
+ (void)hide;

@end

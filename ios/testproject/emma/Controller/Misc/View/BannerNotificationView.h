//
//  BannerNotificationView.h
//  emma
//
//  Created by Peng Gu on 7/8/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^TapAction)();

@interface BannerNotificationView : UIView

@property (copy, nonatomic) TapAction tapAction;

+ (BOOL)isShowingNotification;

- (instancetype)initFromNib;
- (instancetype)initFromNibWithTapAction:(TapAction)action;
- (instancetype)initWithImage:(UIImage *)image message:(NSString *)message actionTitle:(NSString *)action;

- (BOOL)show;
- (void)dismissWithDelay:(NSTimeInterval)delayInSeconds duration:(NSTimeInterval)duration;

@end

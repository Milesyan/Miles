//
//  StatusBarOverlay.h
//  emma
//
//  Created by Ryan Ye on 3/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define StatusBarShowSpinner 1
#define StatusBarGlowing 2
#define StatusBarHighlighted 4
#define StatusBarShowProgressBar 8
#define StatusBarHideBackground 16

@interface StatusBarOverlay : UIWindow

+ (StatusBarOverlay *)sharedInstance;
- (void)postMessage:(NSString *)text;
- (void)postMessage:(NSString *)text duration:(CGFloat)duration;
- (void)postMessage:(NSString *)text options:(int)options;
- (void)postMessage:(NSString *)text options:(int)options duration:(CGFloat)duration;
- (void)clearText:(NSTimeInterval)delay;

- (void)setProgress:(float)progress animated:(BOOL)animated;
- (void)setProgress:(float)progress animated:(BOOL)animated duration:(NSTimeInterval)duration;
@end

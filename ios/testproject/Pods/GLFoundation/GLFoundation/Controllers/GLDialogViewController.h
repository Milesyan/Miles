//
//  DialogViewController.h
//  emma
//
//  Created by Ryan Ye on 3/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

// Dialog Events
#define EVENT_DIALOG_CLOSE_BUTTON_CLICKED @"dialog_close_button_clicked"
#define EVENT_DIALOG_DISMISSED @"dialog_dismissed"

typedef void (^GLFlipAnimationBlock)(void);

@interface GLDialogViewController : UIViewController
@property (nonatomic, strong)IBOutlet UIView *dialogView;
@property (nonatomic) BOOL shouldDismissByTappingOutside;
- (void)presentWithContentController:(UIViewController*)controller;
- (void)presentWithContentController:(UIViewController*)controller canClose:(BOOL)canClose;
- (void)close;
- (BOOL)isOpened;
+ (GLDialogViewController *)sharedInstance;
- (void)flipWithBlock:(GLFlipAnimationBlock)block;
- (void)sizeToFit;
@end

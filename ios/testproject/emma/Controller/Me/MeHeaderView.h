//
//  MeHeaderView.h
//  emma
//
//  Created by Peng Gu on 10/9/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define kTagProfileImage        1001
#define kTagBackgroundImage     1002

@class User;

@interface MeHeaderView : UIView

@property (assign, nonatomic) NSInteger tagWaitingImage;
@property (strong, nonatomic) User *model;
@property (weak, nonatomic) UIViewController *viewController;
@property (weak, nonatomic) IBOutlet UIView *backgroundMask;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundView;

- (void)updateProfileCell;
- (void)loadBackgroundImage;
- (void)updateBackgroundFrameWithOffset:(CGFloat)y;
- (void)setBackgroundImage:(UIImage *)image;

- (void)addMotionEffect;
- (void)removeMotionEffect;

@end

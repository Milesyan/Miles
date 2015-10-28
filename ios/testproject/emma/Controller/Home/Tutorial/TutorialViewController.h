//
//  TutorialViewController.h
//  emma
//
//  Created by Ryan Ye on 4/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TutorialViewController : UIViewController
@property (nonatomic, retain) IBOutlet UIView *containerView;
- (void)start;
- (void)pullDownWithDistance:(CGFloat)distance maxValue:(CGFloat)maxValue;
- (void)hideAllGestures;
- (void)showAllGestures;
@end

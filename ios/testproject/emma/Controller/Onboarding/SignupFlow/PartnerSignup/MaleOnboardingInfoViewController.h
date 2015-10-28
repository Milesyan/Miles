//
//  OnboardingInfoViewController.h
//  emma
//
//  Created by Peng Gu on 3/20/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MaleOnboardingInfoViewController : UIViewController

@property (nonatomic, copy) NSString *email;
@property (nonatomic, strong) NSNumber *isFemale;
@property (nonatomic, strong) NSNumber *weight;
@property (nonatomic, strong) NSNumber *height;

@end

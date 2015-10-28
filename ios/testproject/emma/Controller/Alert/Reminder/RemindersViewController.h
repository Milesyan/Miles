//
//  RemindersViewController.h
//  emma
//
//  Created by Eric Xu on 7/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeniusChildViewController.h"

@interface RemindersViewController : UIViewController
@property (nonatomic) BOOL inAppointment;
+ (RemindersViewController *)getInstance;
@end

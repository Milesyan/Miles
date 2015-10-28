//
//  GLLogsStatusViewController.h
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLLogsStatusViewController : UIViewController

+ (instancetype)viewController;
- (void)presentForDate:(NSDate *)date;

@end

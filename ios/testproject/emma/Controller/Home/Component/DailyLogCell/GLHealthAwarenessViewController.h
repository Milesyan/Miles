//
//  GLHealthAwarenessViewController.h
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#define EVENT_GO_TO_LOG_REQUESTED @"event_go_to_log_requested"

@interface GLHealthAwarenessViewController : UIViewController

@property (nonatomic, strong) NSDictionary *awarenessScores;

+ (instancetype)viewController;
- (void)presentForDate:(NSDate *)date;

@end

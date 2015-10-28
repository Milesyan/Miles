//
//  GLInsightPopupsViewController.h
//  kaylee
//
//  Created by Bob on 14-9-4.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLInsightPopupsViewController : UIViewController
@property (nonatomic, retain) NSArray *insights;
@property (nonatomic) CGRect leaveShrinkToRect;

+ (instancetype)instance;
- (void)present;

@end

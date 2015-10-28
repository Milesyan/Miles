//
//  GLPeriodCalendarViewController.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLPeriodEditorChildViewController.h"

@interface GLPeriodCalendarViewController : GLPeriodEditorChildViewController
@property (nonatomic) BOOL hideBottomBar;
@property (nonatomic, copy) NSDate *firstDate;
@property (nonatomic, copy) NSDate *lastDate;
@end

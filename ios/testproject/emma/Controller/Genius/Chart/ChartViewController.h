//
//  ChartViewController.h
//  emma
//
//  Created by Xin Zhao on 13-7-4.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GeniusChildViewController.h"
#import "ChartSegmentView.h"
#import "DayPointerEdgeView.h"
#import "ChartInfoVIew.h"

@interface ChartViewController : GeniusChildViewController <UIScrollViewDelegate>
@property (nonatomic) NSInteger chartDataType;
@property (nonatomic) BOOL isFertility;
@property (readonly) ChartSegmentView *segView;

@property (readonly) BOOL needCorrectFrameAfterRotation;

@end

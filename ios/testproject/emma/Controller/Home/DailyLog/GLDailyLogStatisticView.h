//
//  GLDailyLogStatisticView.h
//  kaylee
//
//  Created by Eric Xu on 11/18/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLMeterView.h"
#import <DACircularProgress/DACircularProgressView.h>

#define EVENT_GO_PHYSICAL @"event_go_physical"
#define EVENT_GO_EMOTIONAL @"event_go_emotional"
#define EVENT_GO_FERTILITY @"event_go_fertility"

@interface GLDailyLogStatisticView : UIView

@property (strong, nonatomic) IBOutlet UIImageView *shadow;
@property (strong, nonatomic) IBOutlet UIView *container;
@property (strong, nonatomic) IBOutlet UIView *itemsContainer;

@property (strong, nonatomic) IBOutlet GLMeterView *overallView;
@property (strong, nonatomic) IBOutlet UILabel *overallValueLabel;

@property (strong, nonatomic) IBOutlet DACircularProgressView *physicalView;
@property (strong, nonatomic) IBOutlet UILabel *physicalValueLabel;

@property (strong, nonatomic) IBOutlet DACircularProgressView *emotionalView;
@property (strong, nonatomic) IBOutlet UILabel *emotionalValueLabel;

@property (strong, nonatomic) IBOutlet DACircularProgressView *fertilityView;
@property (strong, nonatomic) IBOutlet UILabel *fertilityValueLabel;

- (void)reloadWithDailyData:(NSDictionary *)data;
- (void)setupTintColor;

@end

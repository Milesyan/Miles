//
//  WalkThroughFlowController.m
//  emma
//
//  Created by Peng Gu on 8/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalkThroughFlowController.h"
#import "WalkThroughViewController.h"
#import "WalkThroughA.h"
#import "WalkThroughB.h"
#import "WalkThroughC.h"

#define kWalkThroughFlow @"kWalkThroughFlow"

@implementation WalkThroughFlowController

- (instancetype)initWithParentViewController:(UIViewController *)parentViewController
{
    self = [super init];
    if (self) {
        self.parentViewController = parentViewController;
    }
    return self;
}


- (void)setupWalkThroughFlow
{
    // we only use flow C
    self.walkThrough = [[WalkThroughC alloc] initWithParentViewController:self.parentViewController];
    return;
    
    NSNumber *flow = [[NSUserDefaults standardUserDefaults] objectForKey:kWalkThroughFlow];
    
    // if the first time lanuch, we pick flow out of A/B and log the flow
    if (!flow) {
        flow = [NSNumber numberWithInt:arc4random() % 2];
        
        NSDictionary *eventData = @{@"flow_type": flow,
                                    @"ab_test_type": AB_TYPE_IOS_LANDING_V1};
        [Logging syncLog:AB_TEST_USE_CLIENT eventData:eventData];
        
        [[NSUserDefaults standardUserDefaults] setObject:flow forKey:kWalkThroughFlow];
    }
    
    if (flow.integerValue == 0) {
        self.walkThrough = [[WalkThroughA alloc] initWithParentViewController:self.parentViewController];
    }
    else {
        self.walkThrough = [[WalkThroughB alloc] initWithParentViewController:self.parentViewController];
    }
}


- (WalkThroughFlowType)flowType
{
    return [self.walkThrough isKindOfClass:[WalkThroughA class]] ? WalkThroughFlowTypeA : WalkThroughFlowTypeB;
}


@end

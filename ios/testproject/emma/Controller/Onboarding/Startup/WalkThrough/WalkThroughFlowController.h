//
//  WalkThroughFlowController.h
//  emma
//
//  Created by Peng Gu on 8/27/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WalkThroughFlowType) {
    WalkThroughFlowTypeA,
    WalkThroughFlowTypeB
};


@class WalkThrough;

@interface WalkThroughFlowController : NSObject

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic, strong) WalkThrough *walkThrough;
@property (nonatomic, assign, readonly) WalkThroughFlowType flowType;

- (instancetype)initWithParentViewController:(UIViewController *)parentViewController;

- (void)setupWalkThroughFlow;

@end

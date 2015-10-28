//
//  WalkThroughNew.h
//  emma
//
//  Created by Peng Gu on 8/26/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WalkThroughViewController.h"


@interface WalkThrough : NSObject <WalkThroughViewControllerDelegate, WalkThroughViewControllerDataSource>

@property (nonatomic, strong) NSArray *walkThroughViews;
@property (nonatomic, strong) NSArray *backgroundViews;
@property (nonatomic, strong) WalkThroughViewController *walkThroughViewController;

@property (nonatomic, weak) UIViewController *parentViewController;

- (instancetype)initWithParentViewController:(UIViewController *)parentViewController;
- (void)setupViews;

@end

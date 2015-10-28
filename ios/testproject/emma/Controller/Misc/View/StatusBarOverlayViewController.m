//
//  StatusBarOverlayViewController.m
//  emma
//
//  Created by Peng Gu on 8/17/15.
//  Copyright © 2015 Upward Labs. All rights reserved.
//

#import "StatusBarOverlayViewController.h"

@implementation StatusBarOverlayViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.hidden = YES;
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, 20);
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

@end

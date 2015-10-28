//
//  GeniusInsightsChildViewController.h
//  emma
//
//  Created by Jirong Wang on 8/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Insight.h"

@interface GeniusInsightsChildViewController : UIViewController

- (void)setInsight:(Insight *)insight;
- (void)showThumbView;
- (void)showFullView;
- (void)calculateViewsToFit;
- (void)replaceViewsToFit;

@end

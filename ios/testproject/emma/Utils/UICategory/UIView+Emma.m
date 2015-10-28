//
//  UIView+Emma.m
//  emma
//
//  Created by Peng Gu on 11/19/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UIView+Emma.h"

@implementation UIView (Emma)

- (void)addDefaultBorder
{
    self.layer.borderColor = [UIColor colorFromWebHexValue:@"e2e2e2"].CGColor;
    self.layer.borderWidth = 0.5;
    self.layer.cornerRadius = 2;
    self.layer.masksToBounds = YES;
    
//    self.layer.shadowOpacity = 0.6;
//    self.layer.shadowOffset = CGSizeMake(1.0, 1.0);
//    self.layer.shadowColor = [UIColor colorFromWebHexValue:@"e2e2e2"].CGColor;
}

@end


@implementation UITableViewCell (Emma)

- (UITableView *)tableView
{
    id view = self.superview;
    
    while (view && ![view isKindOfClass:[UITableView class]]) {
        view = [view superview];
    }
    
    return (UITableView *)view;
}

@end

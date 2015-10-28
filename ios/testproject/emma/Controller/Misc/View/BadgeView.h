//
//  BadgeView.h
//  emma
//
//  Created by Ryan Ye on 4/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BadgeView : UIView {
    UILabel *label;
}

@property (nonatomic) NSInteger count;

- (UILabel *)getLabel;

@end

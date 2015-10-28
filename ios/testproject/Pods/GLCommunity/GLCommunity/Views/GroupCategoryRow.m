//
//  GroupCategoryRow.m
//  emma
//
//  Created by Xin Zhao on 7/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GroupCategoryRow.h"

@implementation GroupCategoryRow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWithColor:(UIColor *)color name:(NSString *)name
{
    self.colorCircle.layer.cornerRadius = self.colorCircle.frame.size.height / 2;
    self.colorCircle.clipsToBounds = YES;
    self.colorCircle.backgroundColor = color;
    self.title.text = name;
}
@end

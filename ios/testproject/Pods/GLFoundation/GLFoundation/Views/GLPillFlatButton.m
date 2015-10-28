//
//  PillFlatButton.m
//  emma
//
//  Created by Ryan Ye on 8/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLPillFlatButton.h"

@implementation GLPillFlatButton

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        UIColor *buttonColor = [self titleColorForState:UIControlStateNormal];
        [self setupColorWithNoBorder:buttonColor toColor:buttonColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
    return self;
}

@end

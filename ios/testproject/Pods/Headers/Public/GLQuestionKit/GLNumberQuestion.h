//
//  GLOptionsQuestion.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLQuestion.h"

typedef NS_ENUM(NSInteger, PAD_TYPE) {
    NUMBER_PAD = 0,
    DECIMAL_PAD = 1,
};

@interface GLNumberQuestion : GLQuestion
@property (nonatomic) PAD_TYPE padType;
@property (nonatomic) CGFloat maximumValue;
@end

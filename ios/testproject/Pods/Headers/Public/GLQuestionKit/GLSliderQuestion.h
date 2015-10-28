//
//  GSliderQuestion.h
//  GLQuestionKit
//
//  Created by ltebean on 15/7/21.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestion.h"

@interface GLSliderQuestion : GLQuestion
@property (nonatomic, copy) NSString *leftTip;
@property (nonatomic, copy) NSString *middleTip;
@property (nonatomic, copy) NSString *rightTip;
@property (nonatomic) CGFloat minimumValue;
@property (nonatomic) CGFloat maximumValue;
@end

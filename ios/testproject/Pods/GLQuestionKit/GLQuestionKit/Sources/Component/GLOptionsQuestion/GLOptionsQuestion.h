//
//  GLOptionsQuestion.h
//  GLQuestionKit
//
//  Created by ltebean on 15/8/23.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestion.h"

@interface GLOptionsQuestion : GLQuestion

@property (nonatomic, strong) NSArray *optionTitles;
@property (nonatomic, strong) NSArray *optionValues;
@end

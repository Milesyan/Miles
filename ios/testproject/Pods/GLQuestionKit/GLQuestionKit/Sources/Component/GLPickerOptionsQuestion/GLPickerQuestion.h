//
//  GLPickerOptionsQuestion.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLQuestion.h"

@interface GLPickerQuestion : GLQuestion
@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic, strong) NSArray *optionTitles;
@property (nonatomic, strong) NSArray *optionValues;
@end

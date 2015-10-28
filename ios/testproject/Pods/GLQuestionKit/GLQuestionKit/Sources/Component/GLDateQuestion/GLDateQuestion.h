//
//  GLDateQuestion.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/19.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLQuestion.h"

typedef NS_ENUM(NSInteger, PICKER_MODE) {
    MODE_DATE = 0,
    MODE_DATE_AND_TIME = 1,
    MODE_TIME = 2,
};

@interface GLDateQuestion : GLQuestion

@property (nonatomic, copy) NSString *pickerTitle;
@property (nonatomic) PICKER_MODE pickerMode;
@property (nonatomic, copy) NSDate *minimumDate;
@property (nonatomic, copy) NSDate *maximumDate;

@property (nonatomic, assign) BOOL showInfoButton;

@end

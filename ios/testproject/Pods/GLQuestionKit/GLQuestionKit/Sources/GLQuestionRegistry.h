//
//  GLQuestionRegistry.h
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLQuestion.h"

@interface GLQuestionRegistry : NSObject
+ (instancetype)sharedInstance;
- (void)registerQuestion:(Class)questionClass;
- (NSArray *)registeredQuestionClasses;
@end

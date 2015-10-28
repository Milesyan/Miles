//
//  GLQuestionRegistry.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/17.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestionRegistry.h"
#import "GLPickerQuestion.h"
#import "GLYesOrNoQuestion.h"
#import "GLNumberQuestion.h"
#import "GLDateQuestion.h"
#import "GLSliderQuestion.h"
#import "GLOptionsQuestion.h"
#import "GLTextInputQuestion.h"

@interface GLQuestionRegistry()
@property (nonatomic, strong) NSMutableArray *questionClasses;
@end

@implementation GLQuestionRegistry

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.questionClasses = [NSMutableArray array];
        [self registerQuestion:[GLYesOrNoQuestion class]];
        [self registerQuestion:[GLPickerQuestion class]];
        [self registerQuestion:[GLNumberQuestion class]];
        [self registerQuestion:[GLDateQuestion class]];
        [self registerQuestion:[GLSliderQuestion class]];
        [self registerQuestion:[GLOptionsQuestion class]];
        [self registerQuestion:[GLTextInputQuestion class]];
    }
    return self;
}

- (void)registerQuestion:(Class)questionClass
{
    [self.questionClasses addObject:questionClass];
}

- (NSArray *)registeredQuestionClasses
{
    return self.questionClasses;
}

@end

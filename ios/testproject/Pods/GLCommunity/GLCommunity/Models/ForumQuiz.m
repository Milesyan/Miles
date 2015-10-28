//
//  ForumQuiz.m
//  GLCommunity
//
//  Created by Allen Hsu on 8/10/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/NSDictionary+Accessors.h>
#import "ForumQuiz.h"

@implementation ForumQuiz

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict intForKey:@"id"];
            _title = [dict stringForKey:@"title"];
            _image = [dict stringForKey:@"image"];
            _content = [dict stringForKey:@"content"];
            NSArray *questionsData = [dict arrayForKey:@"questions"];
            NSMutableArray *questions = [NSMutableArray arrayWithCapacity:questionsData.count];
            for (NSDictionary *qDict in questionsData) {
                ForumQuizQuestion *q = [[ForumQuizQuestion alloc] initWithDictionary:qDict];
                if (q) {
                    [questions addObject:q];
                }
            }
            _questions = questions;
            NSArray *resultsData = [dict arrayForKey:@"results"];
            NSMutableArray *results = [NSMutableArray arrayWithCapacity:resultsData.count];
            for (NSDictionary *rDict in resultsData) {
                ForumQuizResult *r = [[ForumQuizResult alloc] initWithDictionary:rDict];
                if (r) {
                    [results addObject:r];
                }
            }
            _results = results;
        }
    }
    return self;
}

@end

@implementation ForumQuizQuestion

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict intForKey:@"id"];
            _title = [dict stringForKey:@"title"];
            _image = [dict stringForKey:@"image"];
            NSArray *optionsData = [dict arrayForKey:@"options"];
            NSMutableArray *options = [NSMutableArray arrayWithCapacity:optionsData.count];
            for (NSDictionary *oDict in optionsData) {
                ForumQuizOption *o = [[ForumQuizOption alloc] initWithDictionary:oDict];
                if (o) {
                    [options addObject:o];
                }
            }
            _options = options;
        }
    }
    return self;
}

- (BOOL)isImageOption {
    for (ForumQuizOption *option in self.options) {
        if (option.image.length > 0) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation ForumQuizOption

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict intForKey:@"id"];
            _title = [dict stringForKey:@"title"];
            _image = [dict stringForKey:@"image"];
            _points = [dict intForKey:@"points"];
        }
    }
    return self;
}

@end

@implementation ForumQuizResult

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict intForKey:@"id"];
            _title = [dict stringForKey:@"title"];
            _image = [dict stringForKey:@"image"];
            _content = [dict stringForKey:@"content"];
            _minPoints = [dict intForKey:@"min_points"];
            _maxPoints = [dict intForKey:@"max_points"];
        }
    }
    return self;
}

@end

@implementation ForumQuizAnswer

- (id)initWithDictionary:(NSDictionary *)dict {
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            _identifier = [dict unsignedLongLongForKey:@"id"];
            _userId = [dict intForKey:@"user_id"];
            _points = [dict intForKey:@"points"];
            _quizId = [dict intForKey:@"quiz_id"];
            _resultId = [dict intForKey:@"result_id"];
            _sourceResultId = [dict unsignedLongLongForKey:@"source_result_id"];
            _commentId = [dict unsignedLongLongForKey:@"comment_id"];
            _selectedOptions = [dict stringForKey:@"selected_options"];
            _timeCreated = [dict unsignedLongLongForKey:@"time_created"];
            _timeModified = [dict unsignedLongLongForKey:@"time_modified"];
            _timeRemoved = [dict unsignedLongLongForKey:@"time_removed"];
        }
    }
    return self;
}

@end

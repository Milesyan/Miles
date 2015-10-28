//
//  ForumQuiz.h
//  GLCommunity
//
//  Created by Allen Hsu on 8/10/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ForumQuiz : NSObject

@property (assign, nonatomic) int identifier;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *image;
@property (copy, nonatomic) NSString *content;
@property (copy, nonatomic) NSArray *questions;
@property (copy, nonatomic) NSArray *results;

- (id)initWithDictionary:(NSDictionary *)dict;

@end

@interface ForumQuizQuestion : NSObject

@property (assign, nonatomic) int identifier;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *image;
@property (copy, nonatomic) NSArray *options;

- (BOOL)isImageOption;
- (id)initWithDictionary:(NSDictionary *)dict;

@end

@interface ForumQuizOption : NSObject

@property (assign, nonatomic) int identifier;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *image;
@property (assign, nonatomic) int points;

- (id)initWithDictionary:(NSDictionary *)dict;

@end

@interface ForumQuizResult : NSObject

@property (assign, nonatomic) int identifier;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *image;
@property (copy, nonatomic) NSString *content;
@property (assign, nonatomic) int minPoints;
@property (assign, nonatomic) int maxPoints;

- (id)initWithDictionary:(NSDictionary *)dict;

@end

@interface ForumQuizAnswer : NSObject

@property (assign, nonatomic) uint64_t identifier;
@property (assign, nonatomic) int userId;
@property (assign, nonatomic) int points;
@property (assign, nonatomic) int quizId;
@property (assign, nonatomic) int resultId;
@property (assign, nonatomic) uint64_t sourceResultId;
@property (assign, nonatomic) uint64_t commentId;
@property (copy, nonatomic) NSString *selectedOptions;
@property (assign, nonatomic) uint64_t timeCreated;
@property (assign, nonatomic) uint64_t timeModified;
@property (assign, nonatomic) uint64_t timeRemoved;

- (id)initWithDictionary:(NSDictionary *)dict;

@end
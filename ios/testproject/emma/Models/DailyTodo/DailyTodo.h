//
//  DailyTodo.h
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "BaseModel.h"
#import "User.h"

#define EVENT_DAILY_TODO_UPDATED_FROM_SERVER @"event_daily_todo_updated_from_server"
#define EVENT_DAILY_TODO_CHECKED @"event_daily_todo_checked"

@interface DailyTodo : BaseModel
@property (nonatomic) uint64_t topicId;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *title;
@property (nonatomic) uint64_t todoId;
@property (nonatomic) uint64_t likes;
@property (nonatomic) uint64_t comments;
@property (nonatomic) BOOL checked;
@property (nonatomic) BOOL removed;

@property (nonatomic, strong) User *user;

+ (NSArray *)todosAtDate:(NSString *)date forUser:(User *)user;
+ (NSArray *)todosFromDate:(NSString *)starteDate toDate:(NSString *)endDate forUser:(User *)user;
+ (NSArray *)todosByTopicId:(uint64_t)topicId forUser:(User *)user;
+ (NSArray *)modifiedTodosForUser:(User *)user;
+ (NSArray *)dateLabelsForTodosInMonth:(NSDate *)date forUser:(User *)user;
+ (BOOL)hasCheckedTodosOnDate:(NSString *)date forUser:(User *)user;
+ (void)updateWithServerData:(NSArray *)serverData onDate:(NSString *)date forUser:(User *)user;
- (void)updateChecked:(BOOL)checked;
@end

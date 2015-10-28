//
//  DailyTodo.m
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyTodo.h"

@implementation DailyTodo
@dynamic topicId;
@dynamic date;
@dynamic title;
@dynamic likes;
@dynamic comments;
@dynamic user;
@dynamic todoId;
@dynamic checked;
@dynamic removed;

- (NSDictionary *)attrMapper {
    return @{
             @"id"              : @"todoId",
             @"title"           : @"title",
             @"date"            : @"date",
             @"topic_id"        : @"topicId",
             @"likes"           : @"likes",
             @"comments"        : @"comments",
             @"checked"         : @"checked"
             };
}

+ (NSArray *)todosAtDate:(NSString *)date forUser:(User *)user
{
    if (!user) {
        return nil;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and date == %@ and removed == NO", user.id, date];
    NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"todoId" ascending:NO];
    fetchRequest.sortDescriptors = @[sortDesc];
    
    return [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
}

+ (DailyTodo *)todoAtDate:(NSString *)date todoId:(uint64_t)todoId forUser:(User *)user
{
    return [self fetchObject:@{@"user.id": user.id, @"date": date, @"todoId": @(todoId), @"removed": @(NO)} dataStore:user.dataStore];
}

+ (NSArray *)todosFromDate:(NSString *)starteDate toDate:(NSString *)endDate forUser:(User *)user
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and date >= %@ and date <= %@ and removed == NO", user.id, starteDate, endDate];
    return [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
}

+ (NSArray *)todosByTopicId:(uint64_t)topicId forUser:(User *)user
{
    if (!user) {
        return nil;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and topicId == %@ and removed == NO", user.id, @(topicId)];
    return [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
}

+ (BOOL)hasCheckedTodosOnDate:(NSString *)date forUser:(User *)user
{
    if (!user) {
        return NO;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and date == %@ and checked == 1 and removed == NO", user.id, date];
    fetchRequest.fetchLimit = 1;
    NSArray *result = [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
    return result && result.count > 0;
}

+ (NSArray *)dateLabelsForTodosInMonth:(NSDate *)date forUser:(User *)user
{
    NSString *dateLable = [[Utils dailyDataDateLabel:date] substringToIndex:7];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"user.id == %@ and date BEGINSWITH %@ and removed == NO", user.id, dateLable];
    NSArray *result = [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
    return [result valueForKeyPath:@"date"];
}


+ (void)updateWithServerData:(NSArray *)serverData onDate:(NSString *)date forUser:(User *)user;
{
    if (!serverData || serverData.count == 0) {
        return;
    }
    NSArray *todos = [self todosAtDate:date forUser:user];
    NSMutableSet *todoIdsFromServer = [NSMutableSet set];
    
    for (NSDictionary *data in serverData) {
        DailyTodo *todo = [self todoAtDate:date todoId:[data[@"id"] integerValue] forUser:user];
        if (!todo) {
            todo = [DailyTodo newInstance:user.dataStore];
            todo.date = date;
            todo.user = user;
        }
        [todo updateAttrsFromDictionary:data];
        todo.removed = NO;
        [todoIdsFromServer addObject:@(todo.todoId)];
    }
    
    for (DailyTodo *todo in todos) {
        if (![todoIdsFromServer containsObject:@(todo.todoId)]) {
            todo.removed = YES;
        }
    }
    [user publish:EVENT_DAILY_TODO_UPDATED_FROM_SERVER data:date];
}

+ (NSArray *)modifiedTodosForUser:(User *)user;
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"DailyTodo"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"objState == %d and removed == NO", EMMA_OBJ_STATE_DIRTY];
    return [user.dataStore.context executeFetchRequest:fetchRequest error:nil];
}

- (NSMutableDictionary *)createPushRequest
{
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    request[@"date"] = self.date;
    request[@"id"] = @(self.todoId);
    request[@"checked"] = self.checked ? @(1) : @(0);
    return request;
}

- (void)updateChecked:(BOOL)checked
{
    self.checked = checked;
    self.dirty = YES;
    self.user.dirty = YES;
    [self publish:EVENT_DAILY_TODO_CHECKED data:self.date];
}


- (void)updateAttrsFromDictionary:(NSDictionary *)dict
{
    for (NSString *attr in self.attrMapper) {
        NSObject *remoteVal = [dict objectForKey:attr];
        if (remoteVal) {
            NSString *clientAttr = [self.attrMapper valueForKey:attr];
            [self convertAndSetValue:remoteVal forAttr:clientAttr];
        }
    }
}


- (void)clearState {
    self.dirty = NO;
}

@end

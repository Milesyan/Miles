//
//  NotesManager.m
//  emma
//
//  Created by Jirong Wang on 10/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "NotesManager.h"
#import "User.h"
#import "UserDailyData.h"
#import "Events.h"

@interface NotesManager() {
    
}

@end

@implementation NotesManager

static BOOL noteEditing = NO;
static int noteEditIndex = -1;

+ (void)startEdit:(int)index {
    noteEditing = YES;
    noteEditIndex = index;
}

+ (BOOL)canEdit:(int)selfIndex {
    if (noteEditing && noteEditIndex != selfIndex)
        return NO;
    else
        return YES;
}

+ (void)endEdit {
    noteEditing = NO;
    noteEditIndex = -1;
}

+ (UserDailyData *)curDailyData:(NSString *)dateLabel {
    return [UserDailyData getUserDailyData:dateLabel forUser:[User currentUser]];
}

+ (NSArray *)getNotesForDate:(NSString *)dateLabel {
    UserDailyData * dailydata = [self curDailyData:dateLabel];
    if ([Utils isEmptyString:dailydata.notes])
        return @[];
    else
        return (NSArray *)[Utils jsonParse:dailydata.notes];
}

+ (NSString *)getNoteForDate:(NSString *)dateLabel atIndex:(NSInteger)index {
    NSArray * notesList = [self getNotesForDate:dateLabel];
    if (notesList.count <= index) {
        // out of range
        return @"";
    } else {
        return (NSString *)[notesList objectAtIndex:index];
    }
}

+ (NSInteger)notesCountForDate:(NSString *)dateLabel {
    return [self getNotesForDate:dateLabel].count;
}

+ (NSString *)latestNoteForDate:(NSString *)dateLabel {
    NSArray * notesList = [self getNotesForDate:dateLabel];
    if ([notesList count] > 0) {
        return notesList.lastObject;
    }
    return nil;
}

+ (void)removeNoteForDate:(NSString *)dateLabel atIndex:(NSInteger)index {
    NSMutableArray * notesList = [NSMutableArray arrayWithArray:[self getNotesForDate:dateLabel]];
    if (notesList.count <= index) {
        // out of range, return
        return;
    }
    [notesList removeObjectAtIndex:index];
    User * user = [User currentUser];
    UserDailyData * dailydata = [UserDailyData tset:dateLabel forUser:user];
    [dailydata update:@"notes" value:notesList];
    [user save];
}

+ (void)tsetNote:(NSString *)note forDate:(NSString *)dateLabel atIndex:(NSInteger)index {
    NSMutableArray * notesList = [NSMutableArray arrayWithArray:[self getNotesForDate:dateLabel]];
    if (notesList.count > index) {
        // update
        [notesList setObject:note atIndexedSubscript:index];
    } else {
        // insert
        [notesList addObject:note];
    }
    User * user = [User currentUser];
    UserDailyData * dailydata = [UserDailyData tset:dateLabel forUser:user];
    [dailydata update:@"notes" value:notesList];
    [user save];
}

+ (void)saveNotes:(NSArray *)notes forDate:(NSString *)dateLabel {
    NSArray *savedNoted = [self getNotesForDate:dateLabel];
    if ([notes isEqualToArray:savedNoted]) {
        return;
    }
    User * user = [User currentUser];
    UserDailyData * dailydata = [UserDailyData tset:dateLabel forUser:user];
    [dailydata update:@"notes" value:notes];
    [user save];
}

@end

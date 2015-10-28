//
//  NotesManager.h
//  emma
//
//  Created by Jirong Wang on 10/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UserDailyData.h"

@interface NotesManager : NSObject

@property (nonatomic) UserDailyData *dailydata;

+ (void)startEdit:(int)index;
+ (BOOL)canEdit:(int)selfIndex;
+ (void)endEdit;

+ (NSArray *)getNotesForDate:(NSString *)dateLabel;
+ (NSString *)getNoteForDate:(NSString *)dateLabel atIndex:(NSInteger)index;
+ (NSInteger)notesCountForDate:(NSString *)dateLabel;
+ (NSString *)latestNoteForDate:(NSString *)dateLabel;
+ (void)removeNoteForDate:(NSString *)dateLabel atIndex:(NSInteger)index;
+ (void)tsetNote:(NSString *)note forDate:(NSString *)dateLabel atIndex:(NSInteger)index;
+ (void)saveNotes:(NSArray *)notes forDate:(NSString *)dateLabel;

@end

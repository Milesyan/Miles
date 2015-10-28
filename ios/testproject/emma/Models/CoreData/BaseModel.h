//
//  BaseModel.h
//  emma
//
//  Created by Ryan Ye on 2/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "DataStore.h"

#define EMMA_OBJ_STATE_CLEAN    0
#define EMMA_OBJ_STATE_DIRTY    1

#define EVENT_DATA_SAVED @"event_data_saved"
#define EVENT_DATA_ROLLBACK @"event_data_rollback"
#define EVENT_DATA_UNLOCKED_BY_SERVER @"event_data_unlocked_by_server"

@interface BaseModel : NSManagedObject

@property (nonatomic, retain) NSSet *changedAttributes;
@property (nonatomic, retain) DataStore *dataStore;
@property (nonatomic) BOOL dirty;
@property (nonatomic, assign) int16_t objState;
@property (readonly) NSSet *emptyAttrs;

+ (id)newInstance:(DataStore *)ds;
+ (void)deleteInstance:(BaseModel *)obj;
+ (id)upsertWithServerData:(NSDictionary *)data dataStore:(DataStore *)ds;
+ (id)fetchObject:where dataStore:(DataStore *)ds;
+ (void)lockByServer;
+ (void)unlockByServer;
- (void)updateAttrsFromServerData:(NSDictionary *)data;
- (NSDictionary *)toDictionaryWithServerAttrs;
- (NSString *)className;
- (NSDictionary *)attrMapper;
- (void)clearState;
- (void)convertAndSetValue:(NSObject *)val forAttr:(NSString *)attr;
- (NSMutableDictionary *)createPushRequest;
- (void)update:(NSString *)attr value:(NSObject *)val;
- (void)update:(NSString *)attr intValue:(NSInteger)val;
- (void)update:(NSString *)attr boolValue:(NSInteger)val;
- (void)update:(NSString *)attr floatValue:(NSInteger)val;
- (void)remove:(NSString *)attr;
- (BaseModel *)makeThreadSafeCopy;
- (BOOL)save;
- (BOOL)rollback;
@end

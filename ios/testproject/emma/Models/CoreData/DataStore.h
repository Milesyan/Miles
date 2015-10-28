//
//  DataStore.h
//  emma
//
//  Created by Ryan Ye on 2/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BaseModel;
@interface DataStore : NSObject

@property (readonly) NSManagedObjectContext *context;
@property (nonatomic, strong) NSString *name;

+ (DataStore *)defaultStore;
+ (DataStore *)storeWithName:(NSString *)name;
+ (void)deleteDBFile:(NSString *)storeName;
+ (NSString *)getDBFilePath:(NSString *)storeName;
- (id)initWithParentStore:(DataStore *)parentStore;
- (void)clearAll;
- (void)clearAllExceptObjs:(NSArray *)exceptObjs;
- (BaseModel *)objectWithID:(NSManagedObjectID *)objId;
- (BaseModel *)objectWithURI:(NSURL *)uri;
- (BaseModel *)fetchObject:(NSDictionary *)where forClass:(NSString *)className;
- (void)initContext;

@end

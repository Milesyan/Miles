//
//  DataStore.m
//  emma
//
//  Created by Ryan Ye on 2/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DataStore.h"
#import "BaseModel.h"

@interface DataStore() {
    NSManagedObjectModel *mom;
    NSPersistentStoreCoordinator *psc;
}
@end

@implementation DataStore

static NSMutableDictionary *_stores = nil;

+ (DataStore *)defaultStore {
    return [self storeWithName:@"default"];
}

+ (DataStore *)storeWithName:(NSString *)name {
    if (!_stores) {
        _stores = [[NSMutableDictionary alloc] init];
    }
    if (![_stores objectForKey:name]) {
        DataStore *ds = [[DataStore alloc] initWithName:name];
        [_stores setObject:ds forKey:name];
    }
    return [_stores objectForKey:name];
}

# pragma mark Public Methods
- (id)initWithName:(NSString *)name {
    if (self = [super init]) {
        self.name = name;
        NSArray *bundles = [NSArray arrayWithObject:[NSBundle bundleForClass:[self class]]];
        mom = [NSManagedObjectModel mergedModelFromBundles:bundles];
        psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
        
        NSError *err = nil;
        NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                                 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        
        [psc addPersistentStoreWithType:EMMA_DATA_STORE_TYPE configuration:nil
                                    URL:[NSURL fileURLWithPath:[DataStore getDBFilePath:self.name]]
                            options:options
                              error:&err];

        GLLog(@"Persistent store error: %@", err);
        [self initContext];
    }
    return self;
}

- (id)initWithParentStore:(DataStore *)parentStore {
    if (self = [super init]) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _context.parentContext = parentStore.context;
    }
    return self;
}

- (void)initContext {
    if ([NSThread isMainThread]) {
        _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
//        [_context setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
        _context.persistentStoreCoordinator = psc;
    } else {
        [NSException raise:@"NotInMainQueueException" format:@"Create a main-context in a non-main queue thread."];
    }
}

- (BaseModel *)fetchObject:(NSDictionary *)where forClass:(NSString *)className {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSMutableArray *preds = [[NSMutableArray alloc] init];
    for (NSString* key in where) {
        [preds addObject:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ == %%@", key], [where valueForKey:key]]];
    }
    fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:preds];
    NSArray *fetchedResult = [self.context executeFetchRequest:fetchRequest error:nil];
    if ([fetchedResult count] > 0) {
        BaseModel *obj = [fetchedResult lastObject];
        obj.dataStore = self;
        return obj;
    } else {
        return nil;
    }
}

- (BaseModel *)objectWithID:(NSManagedObjectID *)objId {
    if (objId == nil) {
        return nil;
    }
    return (BaseModel *)[self.context existingObjectWithID:objId error:nil];
}

- (BaseModel *)objectWithURI:(NSURL *)uri {
    NSManagedObjectID *objId = [psc managedObjectIDForURIRepresentation:uri];
    return [self objectWithID:objId];
}

- (void)clearAll {
    for (NSEntityDescription *entityDesc in mom.entities) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDesc.name];
        NSArray *fetchedResult = [self.context executeFetchRequest:fetchRequest error:nil];
        for (BaseModel *obj in fetchedResult) {
            [self.context deleteObject:obj];
        }
    }
    NSError *err = nil;
    [self.context save:&err];
}

- (void)clearAllExceptObjs:(NSArray *)exceptObjs {
    for (NSEntityDescription *entityDesc in mom.entities) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityDesc.name];
        NSArray *fetchedResult = [self.context executeFetchRequest:fetchRequest error:nil];
        for (BaseModel *obj in fetchedResult) {
            if ([exceptObjs indexOfObject:obj] == NSNotFound) {
                [self.context deleteObject:obj];
            }
        }
    }
    NSError *err = nil;
    [self.context save:&err];
}

+ (void) deleteDBFile:(NSString *)storeName {
    [[NSFileManager defaultManager] removeItemAtPath:[self getDBFilePath:storeName] error:nil];
}

# pragma mark Private Methods
+ (NSString *)tsetAppSupportDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *appSupportDirectory = [paths lastObject]; 
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:appSupportDirectory]) {
        NSError *error = nil;
        [fm createDirectoryAtPath:appSupportDirectory withIntermediateDirectories:NO attributes:nil error:&error];
        if (error) GLLog(@"Create directory error: %@", error);
    }
    return appSupportDirectory;
}

+ (NSString *)getDBFilePath:(NSString *)storeName {
    NSString *storeFileName = [NSString stringWithFormat:@"%@.db", storeName];
    return [NSString pathWithComponents:@[[self tsetAppSupportDirectory], storeFileName]];
}
@end

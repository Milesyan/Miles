//
//  BaseModel.m
//  emma
//
//  Created by Ryan Ye on 2/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BaseModel.h"

@interface BaseModel() {
    NSMutableDictionary *pendingChanges;
}
- (void)convertAndSetValue:(NSObject *)val forAttr:(NSString *)attr;
@end

@implementation BaseModel
@synthesize dataStore;
@dynamic objState;
@dynamic changedAttributes;

+ (id)newInstance:(DataStore *)ds {
    @synchronized(self)
    {
        if (!ds)
        {
            return nil;
        }
        BaseModel *obj = (BaseModel *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(self) inManagedObjectContext:ds.context];
        obj.dataStore = ds;
        return obj;
    }
}

+ (void)deleteInstance:(BaseModel *)obj {
    GLLog(@"deleting instance: %@", obj);
    [obj unsubscribeAll];
    [obj.managedObjectContext deleteObject:obj];
}

+ (id)upsertWithServerData:(NSDictionary *)data dataStore:(DataStore *)ds {
    id obj = [self fetchObject:@{@"id" : [data objectForKey:@"id"]} dataStore:ds];
    if (!obj) {
        obj = [self newInstance:ds];
    }
    [obj updateAttrsFromServerData:data];
    return obj;
}

+ (id)fetchObject:where dataStore:(DataStore *)ds {
    return [ds fetchObject:where forClass:NSStringFromClass(self)];
}

static BOOL serverLock = NO;
static NSObject *unlockEventPublisher = nil;
+ (void)lockByServer {
    GLLog(@"debug: lock");
    serverLock = YES;
}

+ (void)unlockByServer {
    GLLog(@"debug: unlock");
    serverLock = NO;
    if (!unlockEventPublisher) {
        unlockEventPublisher = [[NSObject alloc] init];
    }
    [unlockEventPublisher publish:EVENT_DATA_UNLOCKED_BY_SERVER];
}

- (void)updateAttrsFromServerData:(NSDictionary *)data {
    for (NSString *attr in self.attrMapper) {
        NSObject *remoteVal = [data objectForKey:attr];
        if (remoteVal) {
            NSString *clientAttr = [self.attrMapper valueForKey:attr];
            [self convertAndSetValue:remoteVal forAttr:clientAttr];
        }
    }
    [self clearState];
}

- (NSDictionary *)toDictionaryWithServerAttrs {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (NSString *clientAttr in self.attrMapper) {
        id val = [self valueForKey:self.attrMapper[clientAttr]];
        if (nil == val) {
            val = [NSNull null];
        }
        if ([val isKindOfClass:[NSDate class]]) {
            val = (val == [NSNull null]) ? val
                    : [NSNumber numberWithInteger:[((NSDate*)val) toDateIndex]];
        }
        result[clientAttr] = val;
    }
    return result;
}

- (BOOL)dirty {
    return self.objState == EMMA_OBJ_STATE_DIRTY;
}

- (void)setDirty:(BOOL)val {
    self.objState = val ? EMMA_OBJ_STATE_DIRTY : EMMA_OBJ_STATE_CLEAN;
}

- (NSSet *)emptyAttrs {
    NSMutableSet *emptyAttrs = [[NSMutableSet alloc] init];
    for (NSString *attr in self.attrMapper.allValues) {
        if ([self valueForKey:attr] == nil) {
            [emptyAttrs addObject:attr];
        }
    }
    return emptyAttrs;
}

- (void)onUnlocked:(Event *)evt {
    GLLog(@"debug: onUnlocked: %@", pendingChanges);
    for (NSString *attr in pendingChanges) {
        [self updateAndSetDirty:attr value:pendingChanges[attr]];
    }
    pendingChanges = nil;
}

- (void)update:(NSString *)attr value:(NSObject *)val {
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"%@ update %@, value %@", NSStringFromClass([self class]), attr, val]];
    // When locked by server, we don't update changedAttributes and dirty flag until unlocked.
    if (serverLock) {
        [self setValue:val forKey:attr];
        if (!pendingChanges) {
            pendingChanges = [[NSMutableDictionary alloc] init];
            [self subscribeOnce:EVENT_DATA_UNLOCKED_BY_SERVER selector:@selector(onUnlocked:)];
        }
        pendingChanges[attr] = val;
        return;
    }
    [self updateAndSetDirty:attr value:val];
}


- (void)updateAndSetDirty:(NSString *)attr value:(NSObject *)val {
    [self setValue:val forKey:attr];
    if (self.changedAttributes == nil) {
        self.changedAttributes = [[NSMutableSet alloc] initWithObjects:attr, nil];
    } else if (![self.changedAttributes containsObject:attr]) {
        NSMutableSet *changedAttrs = [self.changedAttributes mutableCopy];
        [changedAttrs addObject:attr];
        self.changedAttributes = changedAttrs;
    }
    self.dirty = YES;
}

- (void)update:(NSString *)attr intValue:(NSInteger)val {
    [self update:attr value:[NSNumber numberWithInteger:val]];
}

- (void)update:(NSString *)attr boolValue:(NSInteger)val {
    [self update:attr value:[NSNumber numberWithBool:val]];
}

- (void)update:(NSString *)attr floatValue:(NSInteger)val {
    [self update:attr value:[NSNumber numberWithFloat:val]];
}

- (void)remove:(NSString *)attr {
    [self update:attr value:nil];
}

- (void)clearState {
    self.dirty = NO;
    self.changedAttributes = nil;
}

- (NSDictionary *)attrMapper {
    return @{};
}

- (NSAttributeType)getAttributeType:(NSString *)attrName {
    return [[self.entity.attributesByName valueForKey:attrName] attributeType];
}

- (NSString *)className {
    return NSStringFromClass([self class]);
}

- (void)convertAndSetValue:(NSObject *)val forAttr:(NSString *)attr {
    if (val == [NSNull null]) {
        [self setValue:nil forKey:attr];
        return;
    }
    NSAttributeType attrType = [self getAttributeType:attr];
    if (attrType == NSDateAttributeType)
        val = [NSDate dateWithTimeIntervalSince1970:[(NSNumber *)val doubleValue]];
    [self setValue:val forKey:attr];
}

- (NSMutableDictionary *)createPushRequest {
    NSMutableDictionary *request = [[NSMutableDictionary alloc] init];
    NSDictionary *inverseAttrMap = [Utils inverseDict:self.attrMapper];

    for (NSString *attr in self.changedAttributes) {
        NSAttributeType attrType = [self getAttributeType:attr];
        NSObject *val = [self valueForKey:attr];
        if (nil == val) {
            val = [NSNull null];
        }
//        GLLog(@"attr:%@ type:%d val:%@", attr, attrType, val);
        if (attrType == NSDateAttributeType || [val isKindOfClass:[NSDate class]]) {
            val = [NSNumber numberWithInt:(val == [NSNull null]) ? 0 : [(NSDate *)val timeIntervalSince1970]];
//            GLLog(@"val:%@", val);
        }
        
        [request setObject:val forKey:[inverseAttrMap valueForKey:attr]];
    }
    return request;
}

- (BaseModel *)makeThreadSafeCopy {
    DataStore *tmpDs = [[DataStore alloc] initWithParentStore:self.dataStore];
    BaseModel *newObj = (BaseModel *)[tmpDs.context objectWithID:[self objectID]];
    newObj.dataStore = tmpDs;
    return newObj;
}

- (BOOL)save {
    [CrashReport leaveBreadcrumb:@"CoreData save context"];
    NSManagedObjectContext *context = self.managedObjectContext;
    if (!context.persistentStoreCoordinator) {
        return NO;
    }
    
    if ([NSThread isMainThread]) {
        NSError *err = nil;
        if (![context save:&err]) {
            [self displayValidationError:err];
            return NO;
        }
        [self publish:EVENT_DATA_SAVED];
    } else {
        // non-main thread save
        [context performBlockAndWait:^{
            // save to parent (main-moc)
            NSError *err = nil;
            if (![context save:&err]) {
                return;
            }
            if ([context parentContext]) {
                // save parent to disk asynchronously
                [[context parentContext] performBlockAndWait:^{
                    NSError *err = nil;
                    if (![[context parentContext] save:&err]) {
                        return;
                    }
                }];
            }
            [self publish:EVENT_DATA_SAVED];
        }];
    }
    // Invalid hasLocalChanges cache
    return YES;
}


- (void)displayValidationError:(NSError *)anError {
    if (anError && [[anError domain] isEqualToString:@"NSCocoaErrorDomain"]) {
        NSArray *errors = nil;
        
        // multiple errors?
        if ([anError code] == NSValidationMultipleErrorsError) {
            errors = [[anError userInfo] objectForKey:NSDetailedErrorsKey];
        } else {
            errors = [NSArray arrayWithObject:anError];
        }
        
        if (errors && [errors count] > 0) {
            NSString *messages = @"Because\n";
            
            for (NSError * error in errors) {
                NSString *entityName = [[[[error userInfo] objectForKey:@"NSValidationErrorObject"] entity] name];
                NSString *attributeName = [[error userInfo] objectForKey:@"NSValidationErrorKey"];
                NSString *msg;
                switch ([error code]) {
                    case NSManagedObjectValidationError:
                        msg = @"Generic validation error.";
                        break;
                    case NSValidationMissingMandatoryPropertyError:
                        msg = [NSString stringWithFormat:@"The field '%@' mustn't be empty.", attributeName];
                        break;
                    case NSValidationRelationshipLacksMinimumCountError:
                        msg = [NSString stringWithFormat:@"The relationship '%@' doesn't have enough entries.", attributeName];
                        break;
                    case NSValidationRelationshipExceedsMaximumCountError:
                        msg = [NSString stringWithFormat:@"The relationship '%@' has too many entries.", attributeName];
                        break;
                    case NSValidationRelationshipDeniedDeleteError:
                        msg = [NSString stringWithFormat:@"To delete, the relationship '%@' must be empty.", attributeName];
                        break;
                    case NSValidationNumberTooLargeError:
                        msg = [NSString stringWithFormat:@"The number of the attribute '%@' is too large.", attributeName];
                        break;
                    case NSValidationNumberTooSmallError:
                        msg = [NSString stringWithFormat:@"The number of the attribute '%@' is too small.", attributeName];
                        break;
                    case NSValidationDateTooLateError:
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is too late.", attributeName];
                        break;
                    case NSValidationDateTooSoonError:
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is too soon.", attributeName];
                        break;
                    case NSValidationInvalidDateError:
                        msg = [NSString stringWithFormat:@"The date of the attribute '%@' is invalid.", attributeName];
                        break;
                    case NSValidationStringTooLongError:
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' is too long.", attributeName];
                        break;
                    case NSValidationStringTooShortError:
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' is too short.", attributeName];
                        break;
                    case NSValidationStringPatternMatchingError:
                        msg = [NSString stringWithFormat:@"The text of the attribute '%@' doesn't match the required pattern.", attributeName];
                        break;
                    default:
                        msg = [NSString stringWithFormat:@"%@", error];
                        break;
                }
                
                messages = [messages stringByAppendingFormat:@"%@%@%@\n", (entityName?:@""),(entityName?@": ":@""),msg];
                GLLog(@"validation error desc in save: %@", messages);
            }
        }
    }
}

- (BOOL)rollback {
    [self.managedObjectContext rollback];
    [self publish:EVENT_DATA_ROLLBACK];
    return YES;
}

- (NSString *)description
{
    NSMutableString *result = [NSMutableString string];
    for (NSString *key in [self.attrMapper allValues]) {
        if ([self respondsToSelector:NSSelectorFromString(key)]) {
            [result appendFormat:@"%@ = %@\n", key, [self valueForKey:key]];
        }
    }
    return result;
}
@end


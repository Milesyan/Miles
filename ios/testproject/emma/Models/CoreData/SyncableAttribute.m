//
//  SyncableAttribute.m
//  emma
//
//  Created by Xin Zhao on 13-6-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ClinicsManager.h"
#import "SyncableAttribute.h"
#import "JsInterpreter.h"
#import "Interpreter.h"
#import "User.h"
#import "MedManager.h"


@implementation SyncableAttribute

@dynamic stringifiedAttribute;
@dynamic signature;
@dynamic name;

static NSDictionary *attrMapper = nil;
- (NSDictionary *)attrMapper {
    if (!attrMapper) {
        attrMapper = @{@"stringified_attribute": @"stringifiedAttribute",
                       @"signature": @"signature",
                       };
    }
    return attrMapper;
}

static NSArray *allSyncableAttrNames = nil;
+ (NSArray *)getAllSyncableAttrNames {
    if (!allSyncableAttrNames) {
        allSyncableAttrNames = @[ATTRIBUTE_TODOS,
                                 ATTRIBUTE_ACTIVITY_RULES,
                                 ATTRIBUTE_CLINICS,
                                 ATTRIBUTE_DRUGS,
                                 ATTRIBUTE_FERTILE_SCORE,
                                 ATTRIBUTE_PREDICT_RULES,
                                 ATTRIBUTE_HEALTH_RULES,
                                 ];
    }
    return allSyncableAttrNames;
}

+ (void)handlerWhenUpsertedFromServerCompleteWithName:(NSString *)name syncable:(SyncableAttribute*)newSyncableAttr{
    if ([name isEqualToString:ATTRIBUTE_ACTIVITY_RULES]) {
        [RULES_INTERPRETER setActivityRuleJsNeedsInterpret];
    } else if ([name isEqualToString:ATTRIBUTE_PREDICT_RULES]) {
        [RULES_INTERPRETER setPredictionJsNeedsInterpret];
    } else if ([name isEqualToString:ATTRIBUTE_DRUGS]) {
        [MedManager writeDrugs:newSyncableAttr.stringifiedAttribute];
    } else if ([name isEqualToString:ATTRIBUTE_CLINICS]) {
        [ClinicsManager writeClinics:newSyncableAttr.stringifiedAttribute];
    } else if ([name isEqualToString:ATTRIBUTE_FERTILE_SCORE]) {
        [RULES_INTERPRETER setFertileScoreJsNeedsInterpret];
    }
}

+ (id)tsetWithName:(NSString *)name inDataStore:(DataStore*)ds {
    SyncableAttribute *syncableAttr = (SyncableAttribute *)[self fetchObject:@{
                                                            @"name" : name
                                                            } dataStore:ds];
    if (!syncableAttr) {
        syncableAttr = [SyncableAttribute newInstance:ds];
        syncableAttr.name = name;
    }
    if (!syncableAttr.stringifiedAttribute || !syncableAttr.signature) {
        [Utils readStringResources:name complete:^(NSString *content) {
            NSArray *contentArray = [content componentsSeparatedByString:@"\n"];
            [syncableAttr update:@"signature" value:[contentArray objectAtIndex:0]];
            [syncableAttr update:@"stringifiedAttribute" value:[contentArray objectAtIndex:1]];
        }];
    }
    return syncableAttr;
}

+ (id)tsetWithName:(NSString *)name {
    DataStore *ds = [User currentUser].dataStore;
    SyncableAttribute *syncableAttr = (SyncableAttribute *)[self fetchObject:@{
                                                            @"name" : name
                                                            } dataStore:ds];
    if (!syncableAttr) {
        syncableAttr = [SyncableAttribute newInstance:ds];
        syncableAttr.name = name;
    }
    if (!syncableAttr.stringifiedAttribute || !syncableAttr.signature) {
        [Utils readStringResources:name complete:^(NSString *content) {
            NSArray *contentArray = [content componentsSeparatedByString:@"\n"];
            [syncableAttr update:@"signature" value:[contentArray objectAtIndex:0]];
            [syncableAttr update:@"stringifiedAttribute" value:[contentArray objectAtIndex:1]];
        }];
    }
    return syncableAttr;
}

+ (id)upsertWithName:(NSString *)name WithServerData:(NSDictionary *)data inDataStore:(DataStore*)ds {
    SyncableAttribute *syncableAttr = [self tsetWithName:name inDataStore:ds];
    [syncableAttr updateAttrsFromServerData:data];
    [self handlerWhenUpsertedFromServerCompleteWithName:name syncable:syncableAttr];
    
    return syncableAttr;
}
+ (NSString *)getAllSyncableAttributeSignatures {
    NSMutableArray *signaturePairs = [NSMutableArray array];
    for (NSString *syncableAttrNames in [self getAllSyncableAttrNames]) {
        SyncableAttribute *syncableAttr = [self tsetWithName:syncableAttrNames];
        [signaturePairs addObject:[NSString stringWithFormat:@"%@:%@", syncableAttrNames, syncableAttr.signature ? syncableAttr.signature : @""]];
    }
    return [signaturePairs componentsJoinedByString:@"|"];
}

@end

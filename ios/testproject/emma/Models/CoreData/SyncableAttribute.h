//
//  SyncableAttribute.h
//  emma
//
//  Created by Xin Zhao on 13-6-3.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "BaseModel.h"

#define ATTRIBUTE_TODOS @"todos"
#define ATTRIBUTE_ACTIVITY_RULES @"activity_rules"
#define ATTRIBUTE_CLINICS @"clinics"
#define ATTRIBUTE_DRUGS @"drugs"
#define ATTRIBUTE_FERTILE_SCORE_COEF @"fertile_score_coef"
#define ATTRIBUTE_FERTILE_SCORE @"fertile_score"
#define ATTRIBUTE_PREDICT_RULES @"predict_rules"
#define ATTRIBUTE_HEALTH_RULES @"health_rules"
#define ATTRIBUTE_READABILITY @"readability"

@class BaseModel;

@interface SyncableAttribute : BaseModel

@property (nonatomic, retain) id stringifiedAttribute;
@property (nonatomic, retain) NSString * signature;
@property (nonatomic, retain) NSString * name;

+ (NSString *)getAllSyncableAttributeSignatures;
+ (id)upsertWithName:(NSString *)name WithServerData:(NSDictionary *)data inDataStore:(DataStore*)ds;
+ (id)tsetWithName:(NSString *)name;
+ (id)tsetWithName:(NSString *)name inDataStore:(DataStore*)ds;

@end

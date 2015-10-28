//
//  UserMigration.m
//  emma
//
//  Created by Xin Zhao on 13-10-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

// TO BE DELETED

#import "UserMigration.h"
#import "User.h"
#import "Predictor.h"

@implementation UserMigration

static NSString *sharedOldAppVersion = nil;
static NSString *sharedNewAppVersion = nil;
static NSDictionary *versionMigrationMap = nil;

+(void)migrateFromAppVersion:(NSString *)old toVersion:(NSString *)new forUser:(User *)user {
    if ([old isEqualToString:new]) {
        return;
    }
    sharedOldAppVersion = old;
    sharedNewAppVersion = new;
    NSArray *versionsNeedsMigration = [self versionsSkippedFrom:old to:new];
    for (NSString *v in versionsNeedsMigration) {
        SEL migrationMethodSelector = NSSelectorFromString([self migrationMethodNameWithAppVersion:v]);
        [UserMigration performSelector:migrationMethodSelector withObject:user];
    }
    
    sharedOldAppVersion = nil;
    sharedNewAppVersion = nil;
}

+ (NSArray *)versionsSkippedFrom:(NSString *)old to:(NSString *)new {
    NSMutableArray *result = [NSMutableArray array];
    NSInteger oldVersionNumber = !old ? 0 : [Utils versionToNumber:old];
    NSInteger newVersionNumber = [Utils versionToNumber:new];
    for (NSString *v in [self allVersionsWithMigrationInAscendingOrder]) {
        NSInteger versionNumber = [Utils versionToNumber:v];
        if (versionNumber > oldVersionNumber && versionNumber <= newVersionNumber) {
            [result addObject:v];
        }
        if (versionNumber >= newVersionNumber) {
            break;
        }
    }
    return result;
}

+ (NSString *)migrationMethodNameWithAppVersion:(NSString *)version {
    if (!versionMigrationMap) {
        versionMigrationMap = @{@"2.2.0" : @"migration2_2:"};
    }
    return versionMigrationMap[version];
}

+ (NSArray *)allVersionsWithMigrationInAscendingOrder {
    return @[@"2.2.0"];
}

+ (void)migration2_2:(User *)user {
    [user.predictor jsPredictAround:DEFAULT_PB_LABEL];
    [UserDailyData enforcePeriod:user.prediction forUser:user];
}

@end

//
//  MedicalRecordsDataManager.m
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "MedicalRecordsDataManager.h"
#import "Network.h"
#import "User.h"
#import "NSDictionary+Accessors.h"

#define USER_DEFAULTS_KEY_MEDICAL_RECORDS_SUMMARY @"user_defaults_key_medical_records_summary"
#define USER_DEFAULTS_KEY_HUMANAPI_CONNECT_STATUS @"user_defaults_key_humanapi_connect_status"

@implementation MedicalRecordsDataManager

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}

- (void)saveSummaryData:(NSDictionary *)summaryData
{
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_MEDICAL_RECORDS_SUMMARY withValue:summaryData];
}

- (NSDictionary *)summaryData
{
    return [Utils getDefaultsForKey:USER_DEFAULTS_KEY_MEDICAL_RECORDS_SUMMARY];
}

- (NSDictionary *)mockSummaryData;
{
    return @{TYPE_ALLERGIES:@3,TYPE_IMMUNIZATIONS:@5,TYPE_MEDICATIONS:@7};
}

- (void)fetchSummaryData
{
    [self fetchSummaryDataWithCompletionHandler:^(BOOL success) {
        [self publish:EVENT_HUMAN_API_SUMMARY_DATA_UPDATED];
    }];
}

- (void)fetchSummaryDataWithCompletionHandler:(void (^)(BOOL))completionHandler
{
    User *user = [User currentUser];
    if (!user.encryptedToken) {
        return;
    }
    
    NSString  *url = [Utils apiUrl:@"users/humanapi_summary_data" query:@{@"ut":user.encryptedToken}];
    [[Network sharedNetwork] get:url completionHandler:^(NSDictionary *response, NSError *err) {
        if (err) {
            completionHandler(NO);
            return;
        }
        // check rc code
        NSInteger rc = [response integerForKey:@"rc"];
        if (rc != RC_SUCCESS) {
            completionHandler(NO);
            return;
        }
        
        // check if connect status
        BOOL connected = [response boolForKey:@"connected"];
        if (connected) {
            [Utils setDefaultsForKey:USER_DEFAULTS_KEY_HUMANAPI_CONNECT_STATUS withValue:@(ConnectStatusConnected)];
            [self saveSummaryData:response[@"data"]];
        } else {
            [Utils setDefaultsForKey:USER_DEFAULTS_KEY_HUMANAPI_CONNECT_STATUS withValue:@(ConnectStatusNotConnected)];
        }
        completionHandler(YES);
    }];
}

- (ConnectStatus)connectStatus
{
    NSNumber *status = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_HUMANAPI_CONNECT_STATUS];
    if (!status) {
        return ConnectStatusUnKnown;
    }
    if ([status isEqualToNumber:@(ConnectStatusConnected)]) {
        return ConnectStatusConnected;
    } else {
        return ConnectStatusNotConnected;
    }
}

- (void)clearData
{
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_MEDICAL_RECORDS_SUMMARY withValue:nil];
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_HUMANAPI_CONNECT_STATUS withValue:nil];
}

@end

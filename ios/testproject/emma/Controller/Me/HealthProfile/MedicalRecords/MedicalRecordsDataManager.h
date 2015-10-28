//
//  MedicalRecordsDataManager.h
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TYPE_ALLERGIES @"allergies"
#define TYPE_IMMUNIZATIONS @"immunizations"
#define TYPE_MEDICATIONS @"medications"

typedef NS_ENUM(NSInteger, ConnectStatus) {
    ConnectStatusUnKnown = 0,
    ConnectStatusConnected = 1,
    ConnectStatusNotConnected = 2,
};

@interface MedicalRecordsDataManager : NSObject
+ (instancetype)sharedInstance;
- (NSDictionary *)summaryData;
- (NSDictionary *)mockSummaryData;
- (void)fetchSummaryData;
- (void)fetchSummaryDataWithCompletionHandler:(void(^)(BOOL))completionHandler;
- (void)clearData;
- (ConnectStatus)connectStatus;
@end

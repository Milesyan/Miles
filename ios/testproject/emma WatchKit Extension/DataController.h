//
//  DataController.h
//  emma
//
//  Created by Peng Gu on 5/11/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define kWormholeDirectory @"wormhole"

#define kWormholeWatchData @"kWormholeWatchData"

#define kNoUserAvailable @"kNoUserAvailable"

#define kRequestType @"actionType"
#define kTodayData @"todayData"
#define kPredictionData @"predictionData"
#define kGlanceData @"glanceData"

#define kButtonType @"buttonType"
#define kCirclesData @"circlesData"

#define kCircleTitle @"title"
#define kCircleText @"text"
#define kCircleBackgroundColor @"backgroundColor"

#define kPredictionColor @"predictionColor"
#define kPredictionText @"predictionText"

#define kGlanceCircleColor @"glanceCircleColor"
#define kGlanceTitle @"glanceTitle"
#define kGlanceSubtitle @"glanceSubtitle"
#define kGlanceText @"glanceText"

#define kNotificationWatchDataUpdated @"kNotificationWatchDataUpdated"

typedef void(^ReplyCallback)(NSDictionary *replyInfo, NSError *error);

typedef NS_ENUM (NSInteger, ButtonType) {
    ButtonTypeMyPeriodIsLate = 1,
    ButtonTypeMyPeriodStartedToday = 2,
    ButtonTypeNone = 0
};


typedef NS_ENUM(NSUInteger, RequestType) {
    RequestTypeRefreshWatchData = 1,
    RequestTypePeriodIsLate = 2,
    RequestTypePeriodStartedToday = 3,
    RequestTypeLogTodayPage = 4,
    RequestTypeLogPredictionPage = 5,
    RequestTypeLogGlancePage = 6,
    RequestTypeLogNotificationPage = 7
};


@interface DataController : NSObject

@property (nonatomic, assign) BOOL noUserAvailable;

@property (nonatomic, strong, readonly) NSDictionary *todayData;
@property (nonatomic, strong, readonly) NSArray *predictionData;
@property (nonatomic, strong, readonly) NSDictionary *glanceData;

+ (instancetype)sharedInstance;
- (void)sendRequestToParentApp:(RequestType)requestType reply:(ReplyCallback)reply;

@end

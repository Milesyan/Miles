//
//  HealthAwareness.h
//  emma
//
//  Created by Jirong Wang on 12/5/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DailyLogConstants.h"
#import "UserDailyData.h"

#define AWARENESS_SCORE_NO_ANSWER    0
#define AWARENESS_SCORE_ANSWERED     1
#define AWARENESS_SCORE_HALF         0.5

#define kHealthAwareness    @"healthAwareness"
#define kPhysicalAwareness  @"physicalAwareness"
#define kEmotionalAwareness @"emotionalAwareness"
#define kFertilityAwareness @"fertilityAwareness"

@interface DailyLogAwareness : NSObject

@property (nonatomic) NSArray * required;
@property (nonatomic) NSArray * optional;

@end

@interface PhysicalAwareness : DailyLogAwareness
@end

@interface EmotionalAwareness : DailyLogAwareness
@end

@interface FertilityAwareness : DailyLogAwareness
@end


@interface HealthAwareness : NSObject
+ (NSDictionary *)allScoreForUserDailyData:(UserDailyData *)dailyData;
+ (NSDictionary *)allScore:(NSDictionary *)dailyData;

@end

//
//  HealthAwareness.m
//  emma
//
//  Created by Jirong Wang on 12/5/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "HealthAwareness.h"
#import "DailyLogConstants.h"
#import "User+DailyData.h"

@implementation DailyLogAwareness

- (NSArray *)answerOrNotLog {
    // if not answered, 0
    // if answered,  > 0
    return @[
        DAILY_LOG_ITEM_BBT,
        DAILY_LOG_ITEM_OVTEST,
        DAILY_LOG_ITEM_CERVICAL_POSITION,
        DAILY_LOG_ITEM_SLEEP,
        DAILY_LOG_ITEM_WEIGHT,
        DAILY_LOG_ITEM_PREGNANCY_TEST,
        DAILY_LOG_ITEM_ERECTION
    ];
}

- (NSArray *)standardedExpandLog {
    // if not answered, 0
    // if answered no,  1
    // if answered yes, 2
    //     plus any option value
    return @[
        DAILY_LOG_ITEM_INTERCOURSE,
        DAILY_LOG_ITEM_SPOTTING,
        DAILY_LOG_ITEM_EXERCISE,
        DAILY_LOG_ITEM_STRESS_LEVEL,
        DAILY_LOG_ITEM_SMOKE,
        DAILY_LOG_ITEM_ALCOHOL,
        DAILY_LOG_ITEM_MASTURBATION,
        DAILY_LOG_ITEM_HEAT_SOURCE,
        DAILY_LOG_ITEM_FEVER
    ];
}

- (float)score:(NSString *)key fromDaily:(NSDictionary *)dailyData {
    NSNumber * value = [dailyData objectForKey:key];
    if (!value || [value isEqual:[NSNull null]]) {
        return AWARENESS_SCORE_NO_ANSWER;
    }
    if ([[self answerOrNotLog] indexOfObject:key] != NSNotFound) {
        return ([value unsignedLongLongValue] > DAILY_LOG_VAL_NONE) ? AWARENESS_SCORE_ANSWERED : AWARENESS_SCORE_NO_ANSWER;
    } else if ([[self standardedExpandLog] indexOfObject:key] != NSNotFound) {
        int64_t t = [value unsignedLongLongValue];
        if (t == DAILY_LOG_VAL_NONE) {
            return AWARENESS_SCORE_NO_ANSWER;
        } else if (t == DAILY_LOG_VAL_NO) {
            return AWARENESS_SCORE_ANSWERED;
        } else if (t == DAILY_LOG_VAL_YES) {
            return AWARENESS_SCORE_HALF;
        } else {
            return AWARENESS_SCORE_ANSWERED;
        }
    }
    return AWARENESS_SCORE_NO_ANSWER;
}

- (float)score:(NSDictionary *)dailyData {
    int total   = 0;
    float score = 0;
    // required first
    for (NSString * key in self.required) {
        score += [self score:key fromDaily:dailyData];
        total += 1;
    }
    // optional
    for (NSString * key in self.optional) {
        float s = [self score:key fromDaily:dailyData];
        if (s > DAILY_LOG_VAL_NONE) {
            score += s;
            total += 1;
        }
    }
    return total == 0 ? 0 : (score / (float)total);
}

@end

@implementation PhysicalAwareness

- (id)init {
    self = [super init];
    if (self) {
        self.required = @[
            DAILY_LOG_ITEM_PHYSICAL_SYMPTOM,
            DAILY_LOG_ITEM_SLEEP,
            DAILY_LOG_ITEM_EXERCISE,
            DAILY_LOG_ITEM_SMOKE,
            DAILY_LOG_ITEM_ALCOHOL
        ];
        self.optional = @[
            DAILY_LOG_ITEM_WEIGHT,
            // DAILY_LOG_ITEM_MEDICATION
        ];
    }
    return self;
}

- (float)score:(NSString *)key fromDaily:(NSDictionary *)dailyData {
    NSNumber * value = [dailyData objectForKey:key];
    if ((value == nil) || ([value isKindOfClass:[NSNull class]])) {
        return AWARENESS_SCORE_NO_ANSWER;
    }
    if ([key isEqualToString:DAILY_LOG_ITEM_PHYSICAL_SYMPTOM]) {
        // physical symptom
        int64_t t = [value unsignedLongLongValue];
        if (t == DAILY_LOG_VAL_NONE) {
            return AWARENESS_SCORE_NO_ANSWER;
        } else if (t == DAILY_LOG_VAL_NO) {
            return AWARENESS_SCORE_ANSWERED;
        } else if (t >= DAILY_LOG_VAL_YES) {
            NSNumber * v1 = [dailyData objectForKey:PHYSICAL_SYMPTOM_ONE_KEY];
            NSNumber * v2 = [dailyData objectForKey:PHYSICAL_SYMPTOM_TWO_KEY];
            if ((!isNSNull(v1) && [v1 unsignedLongLongValue] > 0) || (!isNSNull(v2) && [v2 unsignedLongLongValue] > 0)) {
                return AWARENESS_SCORE_ANSWERED;
            } else {
                return AWARENESS_SCORE_HALF;
            }
        }
        
    } else {
        return [super score:key fromDaily:dailyData];
    }
    return AWARENESS_SCORE_NO_ANSWER;
}

@end

@implementation EmotionalAwareness

- (id)init {
    self = [super init];
    if (self) {
        self.required = @[
            DAILY_LOG_ITEM_EMOTION_SYMPTOM,
            DAILY_LOG_ITEM_STRESS_LEVEL
        ];
        self.optional = @[];
    }
    return self;
}

- (float)score:(NSString *)key fromDaily:(NSDictionary *)dailyData {
    NSNumber * value = [dailyData objectForKey:key];
    if ((value == nil) || ([value isKindOfClass:[NSNull class]])) {
        return AWARENESS_SCORE_NO_ANSWER;
    }
    if ([key isEqualToString:DAILY_LOG_ITEM_EMOTION_SYMPTOM]) {
        // emotion symptom
        int64_t t = [value unsignedLongLongValue];
        if (t == DAILY_LOG_VAL_NONE) {
            return AWARENESS_SCORE_NO_ANSWER;
        } else if (t == DAILY_LOG_VAL_NO) {
            return AWARENESS_SCORE_ANSWERED;
        } else if (t >= DAILY_LOG_VAL_YES) {
            NSNumber * v1 = [dailyData objectForKey:EMOTIONAL_SYMPTOM_ONE_KEY];
            NSNumber * v2 = [dailyData objectForKey:EMOTIONAL_SYMPTOM_TWO_KEY];
            if ((!isNSNull(v1) && [v1 unsignedLongLongValue] > 0) || (!isNSNull(v2) && [v2 unsignedLongLongValue] > 0)) {
                return AWARENESS_SCORE_ANSWERED;
            } else {
                return AWARENESS_SCORE_HALF;
            }
        }
    } else {
        return [super score:key fromDaily:dailyData];
    }
    return AWARENESS_SCORE_NO_ANSWER;
}

@end

@implementation FertilityAwareness

- (id)init {
    self = [super init];
    if (self) {
        if ([User currentUser].isFemale) {
            self.required = @[
                              DAILY_LOG_ITEM_INTERCOURSE,
                              DAILY_LOG_ITEM_SPOTTING,
                              DAILY_LOG_ITEM_CERVICAL_MUCUS,
                              DAILY_LOG_ITEM_BBT
                              ];
            self.optional = @[
                              DAILY_LOG_ITEM_CERVICAL_POSITION,
                              DAILY_LOG_ITEM_OVTEST,
                              DAILY_LOG_ITEM_PREGNANCY_TEST
                              ];

        } else {
            self.required = @[
                              DAILY_LOG_ITEM_INTERCOURSE,
                              DAILY_LOG_ITEM_FEVER,
                              DAILY_LOG_ITEM_MASTURBATION,
                              DAILY_LOG_ITEM_HEAT_SOURCE,
                              DAILY_LOG_ITEM_ERECTION
                              ];
            self.optional = @[];
        }
        
            }
    return self;
}

- (float)score:(NSString *)key fromDaily:(NSDictionary *)dailyData {
    NSNumber * value = [dailyData objectForKey:key];
    if ((value == nil) || ([value isKindOfClass:[NSNull class]])) {
        return AWARENESS_SCORE_NO_ANSWER;
    }
    if ([key isEqualToString:DAILY_LOG_ITEM_CERVICAL_MUCUS]) {
        // Performed CM check
        int64_t t = [value unsignedLongLongValue];
        if (t == DAILY_LOG_VAL_NONE) {
            return AWARENESS_SCORE_NO_ANSWER;
        } else if (t == CM_SELECT_NO) {
            return AWARENESS_SCORE_ANSWERED;
        } else if ((t == (0 + (CM_WETNESS_NO << 8))) || (t == (CM_TEXTURE_NO + (CM_WETNESS_NO << 8)))) {
            return AWARENESS_SCORE_HALF;
        } else {
            return AWARENESS_SCORE_ANSWERED;
        }
    } else {
        return [super score:key fromDaily:dailyData];
    }
    return AWARENESS_SCORE_NO_ANSWER;
}


@end

@interface HealthAwareness()

@property (nonatomic, strong) PhysicalAwareness  * pAwareness;
@property (nonatomic, strong) EmotionalAwareness * eAwareness;
@property (nonatomic, strong) FertilityAwareness * fAwareness;

@end

@implementation HealthAwareness

+ (HealthAwareness *)sharedInstance
{
    static HealthAwareness *_awarenessInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _awarenessInstance = [[HealthAwareness alloc] init];
    });
    return _awarenessInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
        [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(setup)];
        [self subscribe:EVENT_PURPOSE_CHANGED selector:@selector(setup)];
    }
    return self;
}

- (void)dealloc
{
    [self unsubscribeAll];
}

- (void)setup
{
    self.pAwareness = [[PhysicalAwareness alloc] init];
    self.eAwareness = [[EmotionalAwareness alloc] init];
    self.fAwareness = [[FertilityAwareness alloc] init];
}

+ (NSDictionary *)allScore:(NSDictionary *)dailyData
{
    HealthAwareness * ha = [HealthAwareness sharedInstance];
    float pScore = [ha.pAwareness score:dailyData];
    float eScore = [ha.eAwareness score:dailyData];
    float fScore = [ha.fAwareness score:dailyData];
    float score  = (pScore + eScore + fScore) / 3.0;
    return @{
        kHealthAwareness:    @(score),
        kPhysicalAwareness:  @(pScore),
        kEmotionalAwareness: @(eScore),
        kFertilityAwareness: @(fScore)
    };
}

+ (NSDictionary *)allScoreForUserDailyData:(UserDailyData *)dailyData
{
    return [self allScore:[dailyData toDictionary]];
}


@end

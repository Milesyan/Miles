//
//  VariousPurposesConstants.h
//  emma
//
//  Created by Xin Zhao on 13-11-20.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#ifndef emma_VariousPurposesConstants_h
#define emma_VariousPurposesConstants_h


#define AppPurposesEnumStart 0
#define AppPurposesEnumEnd 5
typedef NS_ENUM(NSInteger, AppPurposes) {
    AppPurposesTTC = 0,
    AppPurposesNormalTrack = 1,
    AppPurposesAlreadyPregnant = 2,
    AppPurposesAvoidPregnant = 3,
    AppPurposesTTCWithTreatment = 4,
};

#define EVENT_PURPOSE_CHANGED @"event_purpose_changed"

#endif

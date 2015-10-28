//
//  FundActiveLevel.h
//  emma
//
//  Created by Eric Xu on 5/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ACTIVITY_INACTIVE        1
#define ACTIVITY_OCCASIONALLY    2
#define ACTIVITY_MODERATELY      3
#define ACTIVITY_VERY_ACTIVE     4

@interface ActivityLevel : NSObject {
}

@property (nonatomic, strong) NSString *monthLabel;
@property (nonatomic) int activeLevel;
@property (nonatomic) float activeScore;

- (void)setMonth:(NSDate *)newMonth;
- (NSDate *)getMonth;
- (void)setActiveScore:(float)score;
- (NSString *)activityDescription;
//- (void)setActiveLevel:(enum ACTIVE_LEVEL)newActiveLevel;
@end

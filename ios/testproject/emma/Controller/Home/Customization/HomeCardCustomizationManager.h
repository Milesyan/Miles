//
//  HomeCardCustomizationManager.h
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#define CARD_MEDICAL_LOG @"card_medical_log"
#define CARD_DAILY_LOG @"card_daily_log"

#define CARD_PARTNER_SUMMARY @"card_partner_summary"
#define CARD_HEALTH_TIPS @"card_health_tips"
#define CARD_IMPORTANT_TASK @"card_important_task"
#define CARD_DAILY_POLL @"card_daily_poll"
#define CARD_NOTES @"card_notes"
#define CARD_RATING @"card_rating"
#define CARD_RUBY_RECOMMENDATION @"card_ruby_recommendation"
#define CARD_CUSTOMIZATION @"card_customization"

@interface HomeCardCustomizationManager : NSObject
+ (instancetype)sharedInstance;
- (BOOL)needsDisplayCard:(NSString *)cardType;
- (void)setNeedsDisplayCard:(NSString *)cardType display:(BOOL)display;
- (NSArray *)orderOfCards;
- (void)setOrderOfCards:(NSArray *)orderOfCards;
@end

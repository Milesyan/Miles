//
//  HomeCardCustomizationManager.m
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//
#define USER_DEFAULTS_KEY_DISPLAY @"home_card_customization_display"
#define USER_DEFAULTS_KEY_ORDER @"home_card_customization_order"

#import "HomeCardCustomizationManager.h"
@interface HomeCardCustomizationManager()
@property (nonatomic, strong) NSMutableDictionary *displayConfig;
@property (nonatomic, strong) NSArray *orderConfig;
@end

@implementation HomeCardCustomizationManager
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // display
        NSDictionary *configInUserDefaults = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_DISPLAY];
        if (configInUserDefaults) {
            self.displayConfig = [configInUserDefaults mutableCopy];
        } else {
            self.displayConfig = [NSMutableDictionary dictionary];
            [self.displayConfig setValue:@(YES) forKey:CARD_MEDICAL_LOG];
            [self.displayConfig setValue:@(YES) forKey:CARD_DAILY_LOG];
            [self.displayConfig setValue:@(YES) forKey:CARD_PARTNER_SUMMARY];
            [self.displayConfig setValue:@(YES) forKey:CARD_HEALTH_TIPS];
            [self.displayConfig setValue:@(YES) forKey:CARD_DAILY_POLL];
            [self.displayConfig setValue:@(YES) forKey:CARD_RATING];
            [self.displayConfig setValue:@(YES) forKey:CARD_RUBY_RECOMMENDATION];
            [self.displayConfig setValue:@(YES) forKey:CARD_IMPORTANT_TASK];
            [self.displayConfig setValue:@(YES) forKey:CARD_NOTES];
            [self.displayConfig setValue:@(YES) forKey:CARD_CUSTOMIZATION];
            [Utils setDefaultsForKey:USER_DEFAULTS_KEY_DISPLAY withValue:self.displayConfig];
        }
        self.orderConfig = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_ORDER];
        if (!self.orderConfig) {
            self.orderConfig = @[
                                  CARD_MEDICAL_LOG,
                                  CARD_DAILY_LOG,
                                  CARD_PARTNER_SUMMARY,
                                  CARD_RATING,
                                  CARD_RUBY_RECOMMENDATION,
                                  CARD_IMPORTANT_TASK,
                                  CARD_DAILY_POLL,
                                  CARD_HEALTH_TIPS,
                                  CARD_NOTES,
                                  CARD_CUSTOMIZATION
                                  ];
            [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ORDER withValue:self.orderConfig];
        }
        
        // add ruby card config
        [self.displayConfig setValue:@(YES) forKey:CARD_RUBY_RECOMMENDATION];
        if ([self.orderConfig indexOfObject:CARD_RUBY_RECOMMENDATION] == NSNotFound) {
            NSMutableArray *orderConfig = [self.orderConfig mutableCopy];
            [orderConfig insertObject:CARD_RUBY_RECOMMENDATION atIndex:[self.orderConfig indexOfObject:CARD_RATING]];
            [self setOrderOfCards:orderConfig];
        }
   
    }
    return self;
}

- (BOOL)needsDisplayCard:(NSString *)cardType
{
    return [self.displayConfig[cardType] boolValue];
}

- (void)setNeedsDisplayCard:(NSString *)cardType display:(BOOL)display
{
    self.displayConfig[cardType] = @(display);
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_DISPLAY withValue:self.displayConfig];
}

- (NSArray *)orderOfCards
{
    return self.orderConfig;
}

- (void)setOrderOfCards:(NSArray *)orderOfCards
{
    self.orderConfig = orderOfCards;
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ORDER withValue:self.orderConfig];
}

@end

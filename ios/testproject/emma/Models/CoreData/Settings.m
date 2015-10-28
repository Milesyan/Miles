//
//  Settings.m
//  emma
//
//  Created by Ryan Ye on 2/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Settings.h"
#import "User.h"
#import "UIImage+Resize.h"
#import "Network.h"
#import "SDWebImageManager.h"
#import "SDImageCache.h"
#import "StatusBarOverlay.h"
#import <GLCommunity/ForumEvents.h>

@implementation Settings

@dynamic pushToCalendar;
@dynamic notificationFlags;
@dynamic periodCycle;
@dynamic periodLength;
@dynamic timeZone;
@dynamic childrenNumber;
@dynamic height;
@dynamic weight;
@dynamic exercise;
@dynamic firstPb;
@dynamic user;
@dynamic currentStatus;
@dynamic allowFollowUp;
@dynamic receivePushNotification;
@dynamic hasSeenShareDialog;
@synthesize backgroundImage;
@dynamic ttcStart;
@dynamic timePlanedConceive;
@dynamic backgroundImageUrl;
@dynamic meds;
@dynamic bio;
@dynamic location;
@dynamic mfpActivityFactor;
@dynamic mfpActivityLevel;
@dynamic mfpDailyCalorieGoal;
@dynamic mfpDiaryPrivacySetting;
@dynamic lastPregnantDate;

@dynamic taxId;
@dynamic shippingStreet;
@dynamic shippingCity;
@dynamic shippingState;
@dynamic shippingZip;
@dynamic phoneNumber;
@dynamic birthControl;

@synthesize birthControlStart = _birthControlStart;
@dynamic cycleRegularity;
@dynamic diagnosedConditions;
@dynamic liveBirthNumber;
@dynamic miscarriageNumber;
@dynamic tubalPregnancyNumber;
@dynamic abortionNumber;
@dynamic stillbirthNumber;
@dynamic relationshipStatus;
@dynamic partnerErection;
@dynamic occupation;
@dynamic insurance;
@dynamic fertilityTreatment;
@dynamic treatmentStartdate;
@dynamic treatmentEnddate;
@dynamic sameSexCouple;
@dynamic ethnicity;
@dynamic infertilityDiagnosis;
@dynamic previousStatus;
@dynamic spermOrEggDonation;
@dynamic waist;
@dynamic testerone;
@dynamic underwearType;
@dynamic householdIncome;
@dynamic homeZipcode;
@dynamic hidePosts;
@dynamic predictionSwitch;

static NSDictionary *attrMap;
+ (NSDictionary *)attrMapper {
    if (!attrMap) {
        attrMap = @{
                    @"push_to_calendar"          : @"pushToCalendar",
                    @"notification_flags"        : @"notificationFlags",
                    @"period_cycle"              : @"periodCycle",
                    @"period_length"             : @"periodLength",
                    @"time_zone"                 : @"timeZone",
                    @"children_number"           : @"childrenNumber",
                    @"first_pb_date"             : @"firstPb",
                    @"height"                    : @"height",
                    @"current_status"            : @"currentStatus",
                    @"allow_follow_up"           : @"allowFollowUp",
                    @"receive_push_notification" : @"receivePushNotification",
                    @"has_seen_share_dialog"     : @"hasSeenShareDialog",
                    @"exercise"                  : @"exercise",
                    @"weight"                    : @"weight",
                    @"considering"               : @"timePlanedConceive",
                    @"ttc_start"                 : @"ttcStart",
                    @"background_image"          : @"backgroundImageUrl",
                    @"meds"                      : @"meds",
                    @"bio"                       : @"bio",
                    @"location"                  : @"location",
                    @"tax_id"                    : @"taxId",
                    @"mfp_activity_level"        : @"mfpActivityLevel",
                    @"mfp_activity_factor"       : @"mfpActivityFactor",
                    @"mfp_daily_calorie_goal"    : @"mfpDailyCalorieGoal",
                    @"mfp_diary_privacy_setting" : @"mfpDiaryPrivacySetting",
                    @"last_pregnant_date"        : @"lastPregnantDate",
                    @"shipping_street"           : @"shippingStreet",
                    @"shipping_city"             : @"shippingCity",
                    @"shipping_state"            : @"shippingState",
                    @"shipping_zip"              : @"shippingZip",
                    @"phone_number"              : @"phoneNumber",
                    @"birth_control"             : @"birthControl",
                    
                    @"birth_control_start"       : 	@"birthControlStart",
                    @"cycle_regularity"          : 	@"cycleRegularity",
                    @"diagnosed_conditions"      : 	@"diagnosedConditions",
                    @"live_birth_number"         : 	@"liveBirthNumber",
                    @"miscarriage_number"        : 	@"miscarriageNumber",
                    @"tubal_pregnancy_number"    : 	@"tubalPregnancyNumber",
                    @"abortion_number"           :  @"abortionNumber",
                    @"stillbirth_number"         :  @"stillbirthNumber",
                    @"relationship_status"       : 	@"relationshipStatus",
                    @"partner_erection"          : 	@"partnerErection",
                    @"occupation"                : 	@"occupation",
                    @"insurance"                 : 	@"insurance",
                    @"fertility_treatment"       : 	@"fertilityTreatment",
                    @"treatment_startdate"       :  @"treatmentStartdate",
                    @"treatment_enddate"         :  @"treatmentEnddate",
                    @"same_sex_couple"           :  @"sameSexCouple",
                    @"infertility_diagnosis"     : 	@"infertilityDiagnosis",
                    @"sperm_egg_donation"        :  @"spermOrEggDonation",
                    @"previous_status"           :  @"previousStatus",
                    @"ethnicity"                 :  @"ethnicity",
                    
                    @"waist"                     : @"waist",
                    @"testerone"                 : @"testerone",
                    @"underwear_type"            : @"underwearType",
                    @"household_income"          : @"householdIncome",
                    @"home_zipcode"              : @"homeZipcode",
                    
                    @"hide_posts"                : @"hidePosts",
                    @"prediction_switch"         : @"predictionSwitch"
            };
    }
    return attrMap;
}

- (NSDictionary *)attrMapper {
    return [Settings attrMapper];
}

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    DataStore *ds = user.dataStore;
    Settings *settings = user.settings;
    if (!settings) {
        settings = [Settings newInstance:ds];
    }
    [settings updateAttrsFromServerData:data];

    user.settings = settings;
    return settings;
}

+ (NSDictionary*)createPushRequestForNewUserWith:(NSDictionary*)onboardingData {
    // add all the new settings property used in onboarding here
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    NSDictionary *inverseAttrMap = [Utils inverseDict:self.attrMapper];
    for (NSString *attr in [onboardingData allKeys]) {
        if (inverseAttrMap[attr]) {
            id val = onboardingData[attr];
            if (nil == val) {
                val = [NSNull null];
            }
            if ([val isKindOfClass:[NSDate class]]) {
                val = [NSNumber numberWithInteger:(val == [NSNull null]) ? 0 : [(NSDate*)val timeIntervalSince1970]];
            }
            request[inverseAttrMap[attr]] = val;
        }
    }
    NSDictionary *addsflyerInstallData = [Utils getDefaultsForKey:
        DEFAULTS_ADSFLYER_INSTALL];
    if (addsflyerInstallData) {
        request[@"addsflyer_install_data"] = addsflyerInstallData;
    }
    return @{@"settings": request};
}

//+ (void)removeStatusRelatedProperties:(NSMutableDictionary *)dictionary
//{
//    [dictionary removeObjectForKey:@"fertility_treatment"];
//    [dictionary removeObjectForKey:@"treatment_enddate"];
//    [dictionary removeObjectForKey:@"treatment_startdate"];
//    [dictionary removeObjectForKey:@"current_status"];
//
//}
- (NSMutableDictionary *)createPushRequest
{
    NSMutableDictionary *request = [super createPushRequest];
    return request;
}


- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val) {
        self.user.dirty = YES;
    }
}


- (NSDate *)birthControlStart
{
    NSDate *date = _birthControlStart;
    if (date && [date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]]) {
        date = nil;
    }
    return date;
}

- (void)didSave
{
    [super didSave];
    self.backgroundImage = nil;
//    [self publish:EVENT_BACKGROUND_IMAGE_CHANGED];
}

- (void)updateBackgroundImage:(UIImage *)originImage {
    [CrashReport leaveBreadcrumb:@"updateBackgroundImage"];
    UIImage *image = [originImage resizeToBackgroundImage];
    self.backgroundImage = image;
    
    if (image) {
        [self publish:EVENT_BACKGROUND_IMAGE_CHANGED data:@{@"image": image}];
        
        [[StatusBarOverlay sharedInstance] postMessage:@"Uploading background image..." options:StatusBarShowProgressBar];
        [[StatusBarOverlay sharedInstance] setProgress:0.8 animated:YES];
        NSString *url = @"users/update_background_image";
        [[Network sharedNetwork] post:url data:[self.user postRequest:@{}] requireLogin:YES images:@{@"background_image": image} completionHandler:^(NSDictionary *result, NSError *err) {
            GLLog(@"uploadBackgroundImage:%@ err:%@", result, err);
            NSString *url = [result objectForKey:@"url"];
            if (!err && url.length > 0) {
                [[StatusBarOverlay sharedInstance] postMessage:@"Background image uploaded!" options:StatusBarShowProgressBar duration:4.0];
                [[StatusBarOverlay sharedInstance] setProgress:1.0 animated:YES];
                [[SDImageCache sharedImageCache] storeImage:image forKey:url];
                [self update:SETTINGS_KEY_BACKGROUND_IMAGE value:url];
                [self.user save];
                NSString *filePath = self.backgroundImageFilePath;
                if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
                }
            } else {
                [[StatusBarOverlay sharedInstance] postMessage:@"Failed to upload background image" duration:4.0];
            }
        }];
    }
}

- (void)restoreBackgroundImage
{
    NSString *filePath = self.backgroundImageFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    }
    backgroundImage = nil;
    [self update:SETTINGS_KEY_BACKGROUND_IMAGE value:@""];
    [self.user save];
    [self publish:EVENT_BACKGROUND_IMAGE_CHANGED];
    [[StatusBarOverlay sharedInstance] postMessage:@"Background image restored!" duration:2.0];
    NSString *url = @"users/update_background_image";
    [[Network sharedNetwork] post:url data:[self.user postRequest:@{}] requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        GLLog(@"uploadBackgroundImage:%@ err:%@", result, err);
    }];
}

- (NSString *)backgroundImageFilePath {
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    return [NSString stringWithFormat:@"%@/%lud/background.jpg",docDir,(unsigned long) [[self.user.id stringValue] hash]];
}

- (UIImage *)backgroundImage {
    if (!backgroundImage) {
        [self reloadBackground];
    }
    
    if (!backgroundImage) {
        return [self defaultBackgroundImage];
    }

    return backgroundImage;
}

- (UIImage *)defaultBackgroundImage {
    if (self.currentStatus == AppPurposesAvoidPregnant) {
        return [UIImage imageNamed:@"home-health.jpeg"];
    }
    else if (self.currentStatus == AppPurposesNormalTrack) {
        return [UIImage imageNamed:@"home-health.jpeg"];
    }
    else if (self.currentStatus == AppPurposesTTCWithTreatment) {
        return [UIImage imageNamed:@"home-babies.jpeg"];
    }
    else {
        return [UIImage imageNamed:@"home-babies.jpeg"];
    }
}

- (void)reloadBackground {
    NSString *filePath = self.backgroundImageFilePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        UIImage *image = [UIImage imageWithContentsOfFile:filePath];
        if (image) {
            [self updateBackgroundImage:image];
        } else {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        }
    }
    
    SDWebImageManager *manager = [SDWebImageManager sharedManager];
    if (self.backgroundImageUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:self.backgroundImageUrl];
        
        backgroundImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[url absoluteString]];
        if (!backgroundImage) {
            [manager downloadImageWithURL:url
                                  options:0
                                 progress:nil
                                completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                    if (image)
                                    {
                                        backgroundImage = image;
                                        [self publish:EVENT_BACKGROUND_IMAGE_CHANGED];
                                    }
                                    else
                                    {
                                        GLLog(@"Failed to download background image");
                                    }
            }];
        }
    } else {
        backgroundImage = nil;
    }
}

@end

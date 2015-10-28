//
//  Utils.h
//  emma
//
//  Created by Ryan Ye on 2/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSObject+PubSub.h"
#import <QuartzCore/QuartzCore.h>

#define IOS9_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
#define IOS8_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)
#define IOS7_OR_ABOVE ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
#define STATUSBAR_DELTA_6_FROM_7 ((IOS7_OR_ABOVE) ? 0 : -20)


#define IS_IPHONE_6_PLUS ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )736 ) < DBL_EPSILON)
#define IS_IPHONE_6 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )667 ) < DBL_EPSILON)
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON)
#define IS_IPHONE_4 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )480 ) < DBL_EPSILON)

#define HEIGHT_MORE_THAN_IPHONE_4  (IS_IPHONE_6_PLUS ? 256 : (IS_IPHONE_6 ? 187 : (IS_IPHONE_5 ? 88 : 0)))

#define STAssertEqualDate(d1, d2, desc) STAssertEqualsWithAccuracy(\
    [d1 timeIntervalSince1970], \
    [d2 timeIntervalSince1970], \
    0.1, desc)



#define printRect(rect, desc) GLLog(@"%@ CGRect x:%f y:%f w:%f h:%f", desc, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
#define printBOOL(b) GLLog(@"%@: %@", @#b, b? @"Y": @"N");

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBA(rgbaValue) [UIColor colorWithRed:((float)((rgbaValue & 0xFF000000) >> 24))/255.0 green:((float)((rgbaValue & 0xFF0000) >> 16))/255.0 blue:((float)((rgbaValue & 0xFF00) >> 8))/255.0 alpha:((float)(rgbaValue & 0xFF))/255.0]

#define setRectHeight(rect, height) CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, height)
#define setRectWidth(rect, width) CGRectMake(rect.origin.x, rect.origin.y, width, rect.size.height)
#define setRectX(rect, x) CGRectMake(x, rect.origin.y, rect.size.width, rect.size.height)
#define setRectY(rect, y) CGRectMake(rect.origin.x, y, rect.size.width, rect.size.height)
#define setHeightOfRect(rect, h) (rect = setRectHeight(rect, h))
#define setWidthOfRect(rect, w) (rect = setRectWidth(rect, w))
#define setXOfRect(rect, x) (rect = setRectX(rect, x))
#define setYOfRect(rect, y) (rect = setRectY(rect, y))

#define strLess(s1, s2) ([s1 compare:s2]==NSOrderedAscending)
#define strLargeEqual(s1, s2) ([s1 compare:s2]!=NSOrderedAscending)
#define strLarge(s1, s2) ([s1 compare:s2]==NSOrderedDescending)
#define strLessEqual(s1, s2) ([s1 compare:s2]!=NSOrderedDescending)

#define date2Label(date) [Utils dailyDataDateLabel:date]
#define label2Date(label) [Utils dateWithDateLabel:label]

#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height
#define STATUSBAR_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height

#define isNSNull(obj) ([obj isEqual:[NSNull null]])
#define isEmptyObj(obj) ([obj isEqual:[NSNull null]] || !obj)
#define GLOW_FONT @"ProximaNova-Regular"
#define GLOW_FONT_LIGHT @"ProximaNova-Light"
#define GLOW_FONT_BOLD @"ProximaNova-Bold"
#define GLOW_FONT_MEDIUM @"ProximaNova-Semibold"


#define GLOW_COLOR_PURPLE_HEX_VALUE 0x5a62d2
#define GLOW_COLOR_PURPLE UIColorFromRGB(GLOW_COLOR_PURPLE_HEX_VALUE)

#define GLOW_COLOR_LIGHT_PURPLE UIColorFromRGB(0xabaae3)

#define GLOW_COLOR_GREEN_HEX_VALUE 0x73bd37
#define GLOW_COLOR_GREEN UIColorFromRGB(GLOW_COLOR_GREEN_HEX_VALUE)

#define GLOW_COLOR_PINK_HEX_VALUE 0xF1679B
#define GLOW_COLOR_CYAN_HEX_VALUE 0x1BCCA4
#define GLOW_COLOR_PINK UIColorFromRGB(GLOW_COLOR_PINK_HEX_VALUE)
#define GLOW_COLOR_CYAN UIColorFromRGB(GLOW_COLOR_CYAN_HEX_VALUE)

#define TABLECELL_INTERLACED_YELLOW UIColorFromRGB(0xf6f5ef)
#define TABLECELL_INTERLACED_WHITE UIColorFromRGB(0xfefefd)
#define FORUMCELL_BG_ODD UIColorFromRGB(0xfbfaf6)
#define FORUMCELL_BG_EVEN UIColorFromRGB(0xf6f5f0)


#define DEFAULTS_ONBOARDING_ANSWERS @"defaults_onboarding_answers"
#define DEFAULTS_PREVIOUS_WEIGHT @"previousWeight"
#define DEFAULTS_FULFILLMENT_ORDER_PREFIX @"defaults_fulfillment_order"
#define DEFAULTS_HIDDEN_LOG_KEYS_POSTFIX @"defaults_hidden_log_keys"
#define USERDEFAULTS_USER_DAILY_POLL_IDS @"user_daily_poll_ids"
#define DEFAULTS_ADSFLYER_INSTALL @"defaults_adsflyer_INSTALL"
#define DEFAULTS_GROUP_ORDER_PRE @"defaults_group_order_"
#define DEFAULTS_MISFIT_PRE @"defaults_misfit_pre_"
#define DEFAULTS_USER_MISFIT_PRE @"defaults_user_misfit_pre_"

#define kUnitForWeight @"kUnitForWeight"
#define kUnitForHeight @"kUnitForHeight"
#define kUnitForTemp @"kUnitForTemp"

// community
#define DEFAULTS_GG_TUTORED [NSString stringWithFormat:@"defaults_gg_tutored - %@", [[User currentUser] id]]
#define kDidClickCheckoutCommunity [NSString stringWithFormat:@"kDidClickCheckoutCommunity - %@", [[User currentUser] id]]
#define kDidClickGroupsButton [NSString stringWithFormat:@"kDidClickGroupsButton - %@", [[User currentUser] id]]
#define kDidClickNewSectionInCommunity [NSString stringWithFormat:@"kDidClickNewSectionInCommunity - %@", [[User currentUser] id]]
#define kDidClickCommunityTab [NSString stringWithFormat:@"kDidClickCommunityTab - %@", [[User currentUser] id]]

#define UNIT_INCH @"IN"
#define UNIT_CM @"CM"
#define UNIT_LB @"LB"
#define UNIT_KG @"KG"
#define UNIT_CELCIUS @"℃"
#define UNIT_FAHRENHEIT @"℉"

#define BRAND_MASK 10

#define DURATION_UNITS @{@"week":@0, @"weeks":@0,@"month":@1,@"months":@1,@"year":@2,@"years":@2}


typedef void (^ReadResourceCallback)(NSString *resourceContent);
typedef NSString* DailyLogCellKey;

@interface Utils : NSObject
+ (NSString *)urlEncodedStringFromDictionary:(NSDictionary *)dict;
+ (NSString *)makeUrl:(NSString *)url query:(NSDictionary *)query;
+ (NSString *)makeUrl:(NSString *)url;
+ (NSString *)apiUrl:(NSString *)url query:(NSDictionary *)query;
+ (NSDictionary *)inverseDict:(NSDictionary *)dict;
+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;
+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color;
+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color withBlendMode:(CGBlendMode)blendMode;
+ (UIImage *)imageWithColor:(UIColor *)color andSize:(CGSize)size;
+ (UIImage *)snapshotOfView:(UIView *)view withMaxSize:(BOOL)maxSize;

+ (UIFont *)defaultFont:(CGFloat)fontSize;
+ (UIFont *)boldFont:(CGFloat)fontSize;
+ (UIFont *)lightFont:(CGFloat)fontSize;
+ (UIFont *)semiBoldFont:(CGFloat)fontSize;
+ (NSInteger)cycleLengthDisplayToModel:(NSInteger)display;
+ (NSInteger)cycleLengthModelToDisplay:(NSInteger)model;
+ (void)printViewControllStackFromViewController:(UIViewController *)vc desc:(NSString *)desc;
+ (void)printViewStackFromView:(UIView *)v desc:(NSString *)desc;
+ (id)findFirstPbIndexBefore:(NSString *)dateLabel inPrediction:(NSArray *)predictionData;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize color:(UIColor *)color;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color;
+ (NSAttributedString *)markdownToAttributedText:(NSString *)markdown fontSize:(CGFloat)fontSize lineHeight:(CGFloat)lineHeight color:(UIColor *)color alignment:(NSTextAlignment)alignment;
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)imageWithView:(UIView *)view;
+ (void)startProfileTimer;
+ (void)reportElapsedTime:(NSString *)message;
+ (NSCalendar *)calendar;
/* This function is to rotate an view by any given angle, duration */
+ (void)rotateView:(UIView *)view angle:(CGFloat)angle duration:(CGFloat)d clockwise:(BOOL)clockwise;
+ (UIView *)outline:(UIView *)view;
+ (UIColor *)randomColor;
+ (UIColor *)colorFromWebHexValue:(NSString *)hexString;
+ (NSString *)UUID;
+ (NSString *)generateUUID;
+ (NSString *)localeString;
+ (NSString *)modelString;
+ (NSString *)appVersion;
+ (int64_t)appVersionNumber;
+ (int64_t)versionToNumber:(NSString *)version;
+ (NSString *)numberToShortIntString:(long long)num;
+ (NSString *)numberToShortString:(long long)num;
+ (NSString *)numberToSeparatedString:(long long)num;
+ (NSString *)numberTo4BytesString:(long long)num;

+ (NSArray *)shuffle:(NSArray *)arr;
+ (NSString *)trim:(NSString *)aString;
+ (BOOL)isConfirmPassword:(NSString *)confirmPassword partialyMatchingPassword:(NSString *)password;
+ (BOOL)isValidEmail:(NSString *)string;
+ (void)performInMainQueueAfter:(NSTimeInterval)seconds callback:(void (^)(void))callback;
+ (NSString *)jsonStringify:(id)stringifiableObj;
+ (id)jsonParse:(NSString *)stringified;
+ (void)readStringResources:(NSString *)resourceName complete:(ReadResourceCallback)readResouceCallback;

+ (BOOL)isEmptyString:(NSString *)s;
+ (BOOL)isNotEmptyString:(NSString *)s;

+ (NSString *)stringByStrippingHtmlTags:(NSString *)string;

+ (id)getDefaultsForKey:(NSString *)key;
+ (void)setDefaultsForKey:(NSString *)key withValue:(id)val;
+ (long)getSyncableDefautsLastUpdateForKey:(NSString *)key;
+ (void)setSyncableDefautsForKey:(NSString *)key withValue:(id)val;
+ (void)syncSyncableDefaultsForKey:(NSString *)key withValue:(id)val
    withLastUpdate:(long)lastUpdate;
+ (void)syncUserDefaultsForUserId:(NSString *)uid token:(NSString *)token;
+ (void)transmitHiddenDailyLogDefaultsForUserId:(NSString *)uid token:
    (NSString *)token;

+ (NSString *)timeElapsedString:(NSUInteger)timestamp;

+ (NSString *)displayOrder:(NSInteger)order;

+ (NSDate *)dateFromTtcStartString:(NSString *)ttcStartString;
+ (NSString *)ttcStartStringFromDate:(NSDate *)ttcStartDate;

+ (CGFloat)calculateBmiWithHeightInCm:(CGFloat)h weightInKg:(CGFloat)w;

+ (void)writeString:(NSString *)str toDomainFile:(NSString *)fileName;
+ (void)clearDirectory:(NSString *)directory;
+ (void)clearAllAppData;

+ (void)imageViewRotateUpDown:(UIImageView *)imageView;
+ (void)imageViewRotateLeftRight:(UIImageView *)imageView;

+ (NSString *)formatedWithFormat:(NSString *)format date:(NSDate *)date;

+ (NSArray *)getHslaFromUIColor:(UIColor *)color;
+ (UIColor *)brighterAndUnsaturatedColor:(UIColor *)color;
@end

@interface RotateAnimation : NSObject
@property (nonatomic, retain) UIView *rotateView;
@property (nonatomic) CGFloat tgtAngle;
- (id)initWithView:(UIView *)view angle:(CGFloat)tgtAngle;
@end

@interface UIView(GradientBackground)
- (void)setGradientBackground:(UIColor *)colorOne toColor:(UIColor *)colorTwo;
- (void)removeGradientBackground;
@end

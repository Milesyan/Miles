//
//  DailyLogSummary.m
//  emma
//
//  Created by Eric Xu on 12/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogSummary.h"
#import "User.h"
#import "Tooltip.h"
#import "DailyLogCellTypeMucus.h"
#import "DailyLogCellTypeStressLevel.h"
#import "DailyLogConstants.h"
#import "UserDailyData+Symptom.h"
#import "UserDailyData+CervicalPosition.h"

@interface Summary : UIView
@property (nonatomic, strong) NSString *cellKey;
@property (nonatomic, strong) IBOutlet UIImageView *icon;
@property (nonatomic, strong) IBOutlet UILinkLabel *mainLabel;
@property (nonatomic, strong) IBOutlet UILabel *subLabel;
@end

@implementation Summary

- (void)awakeFromNib {
    self.userInteractionEnabled = YES;
    self.mainLabel.userInteractionEnabled = YES;
}

@end

@interface DailyLogSummary() {
    UserDailyData *dailyData;
    NSMutableArray *array;
    NSInteger shortHeight;
    BOOL more;
    NSUInteger dataHash;
    BOOL isSelfData;
    BOOL isAllDataSensitive;
}

@property (strong, nonatomic) UIView *summaryView;
//@property (strong, nonatomic) NSString *plainSummary;

@end

@implementation DailyLogSummary

static NSMutableDictionary *plainSummaries;

- (id)initWithDailyData:(UserDailyData *)userDailyData {
    self = [super init];
    if (self) {
        self.summaryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH-16, 280)];
        self.summaryView.userInteractionEnabled = YES;
        [[NSBundle mainBundle] loadNibNamed:@"DailyLogSummary" owner:self options:nil];
        dailyData = userDailyData;
        array = [NSMutableArray array];
        isSelfData = userDailyData.user == [User currentUser];
        [self generate];
    }
    
    return self;
}

- (void)setDailyData:(UserDailyData *)data {
    if (dataHash == [data dataHash]) {
        return;
    }
    dailyData = data ;
    dataHash = [dailyData dataHash];
    isSelfData = data.user == [User currentUser];
    [self generate];
}

- (void)refresh
{
    [self generate];
}

- (Summary *)getBlankSummary {
    Summary *view = (Summary *)[[NSBundle mainBundle] loadNibNamed:@"DailyLogSummary" owner:self options:nil][0];
    view.mainLabel.text = @"";
    view.subLabel.text = @"";
    return view;
}

static NSDictionary *summaryCategory;
static NSDictionary *summaryDictionary;
static NSDictionary *summaryIcon;
static NSDictionary *mainAttrs;
static NSDictionary *mainHighlightAttrs;
static NSDictionary *subAttrs;
static NSDictionary *subHighlightAttrs;
static NSDictionary *subBoldAttrs;
#define MAIN_FONT_SIZE 18
#define SUB_FONT_SIZE 12
- (NSMutableAttributedString *)mainAttrTextForKey:(id)k {
    return [[NSMutableAttributedString alloc] initWithString:summaryDictionary[k][0] attributes:mainAttrs];
}
- (NSMutableAttributedString *)subAttrTextForKey:(id)k {
    return [[NSMutableAttributedString alloc] initWithString:summaryDictionary[k][1] attributes:subAttrs];
}

- (UIView *)getSummaryView
{
    _summaryView.userInteractionEnabled = YES;
    return _summaryView;
}

- (NSInteger)getSummaryShortHeight {
    return shortHeight;
}

- (NSInteger)getSummaryFullHeight {
    if (_summaryView) {
        return _summaryView.frame.size.height;
    } else {
        return 0;
    }
}

- (BOOL)hasMore {
    return more;
}

- (BOOL)isAllDataSensitive
{
    return isAllDataSensitive;
}

- (void)updateNameForPartner:(NSMutableString *)orig {
    if (isSelfData) {
        return;
    }
    User *user = [User currentUser];
    NSString *partnerName = user.partner.firstName;
    NSString *partners = [NSString stringWithFormat:@"%@’s", user.partner.firstName];
    NSRange range = NSMakeRange(0, orig.length);
    
    [orig replaceOccurrencesOfString:@"I " withString:[partnerName stringByAppendingString:@" "] options:0 range:range];
    [orig replaceOccurrencesOfString:@"My" withString:partners options:0 range:range];
    
    [orig replaceOccurrencesOfString:@"feel" withString:@"feels" options:0 range:range];
    [orig replaceOccurrencesOfString:@"weigh" withString:@"weighs" options:0 range:range];
}

- (BOOL)shouldHideKey:(NSString *)key
{
    if (isSelfData) {
        return NO;
    }
    if ([UserDailyData isSensitiveItem:key]) {
        return YES;
    } else {
        isAllDataSensitive = NO;
        return NO;
    }
}

- (void)generate {
    if (!dailyData) {
        return;
    }
    
    isAllDataSensitive = YES;
    
    if (!summaryDictionary) {
        summaryDictionary = @{
                              DL_CELL_KEY_BBT:@[@"My BBT was #TEMP#",
                                                @"#CHANGE# from #LAST#"],
                              DL_CELL_KEY_INTERCOURSE:@[@"I had intercourse",
                                                        @"#TIME# time this week"],
                              DL_CELL_KEY_CM: @[@"My CM was #TEXTURE# and #WETNESS#",
                                                @"",
                                                @"My CM was #TEXTURE#",
                                                @"My CM amount was #AMOUNT#",
                                                @"My CM was #TEXTURE# and the amount was #AMOUNT#"],
                              DL_CELL_KEY_PERIOD_FLOW: @[@"I experienced #FLOW#spotting",
                                                         @"#TIME# time this month", @"My period today was #FLOW#"],
                              DL_CELL_KEY_CERVICAL: @[@"My cervix felt #FEEL#", @""],
                              DL_CELL_KEY_EXERCISE: @[@"I exercised",
                                                      @"#TIME# time this week"],
                              DL_CELL_KEY_WEIGHT: @[@"I weigh #WEIGHT#",
                                                    @"#CHANGE# from #LAST#"],
                              DL_CELL_KEY_SLEEP: @[@"I slept for #HOURS# hours #MINS# mins"],
                              DL_CELL_KEY_MOODS: @[@"I feel #EMOTION#",
                                                   @"Most common: #COMMON#"],
                              DL_CELL_KEY_STRESS_LEVEL: @[@"My stress level is #LEVEL#",
                                                          @""],
                              DL_CELL_KEY_PHYSICALDISCOMFORT: @[@"I had #DISCOMFORT#",
                                                                @"Most common: #COMMON#"],
                              DL_CELL_KEY_SMOKE: @[@"I smoked #COUNT#",
                                                   @"Smoked #TOTAL# this week"],
                              DL_CELL_KEY_ALCOHOL: @[@"I consumed #COUNT# of alcohol",
                                                     @"Consumed #TOTAL# this week"],
                              DL_CELL_KEY_OVTEST: @[@"I took a#BRAND# ovulation test, and it showed #RESULT# fertility",
                                                    @"Taken #TIME# time this month"],
                              DL_CELL_KEY_PREGNANCYTEST: @[@"I took a#BRAND# pregnancy test, and it was #RESULT#",
                                                           @"Taken #TIME# time this month"],
                              DL_CELL_KEY_FEVER: @[@"I had fever", @""],

                              };
    }
    
    if (!summaryCategory) {
        summaryCategory = @{
                            @"Fertility":@[
                                    DL_CELL_KEY_BBT,
                                    DL_CELL_KEY_INTERCOURSE,
                                    DL_CELL_KEY_FEVER,
                                    DL_CELL_KEY_CM,
                                    DL_CELL_KEY_PERIOD_FLOW,
                                    DL_CELL_KEY_CERVICAL,
                                    DL_CELL_KEY_OVTEST,
                                    DL_CELL_KEY_PREGNANCYTEST
                                    ],
                            @"Physical":@[
                                    DL_CELL_KEY_EXERCISE,
                                    DL_CELL_KEY_WEIGHT,
                                    DL_CELL_KEY_SLEEP,
                                    DL_CELL_KEY_PHYSICALDISCOMFORT,
                                    DL_CELL_KEY_SMOKE,
                                    DL_CELL_KEY_ALCOHOL
                                    ],
                            @"Emotional":@[
                                    DL_CELL_KEY_MOODS,
                                    DL_CELL_KEY_STRESS_LEVEL,
                                    ]
                            };
    }
    
    if (!summaryIcon) {
        summaryIcon = @{
                        DL_CELL_KEY_BBT: @[@"home-logged-bbt"],
                        DL_CELL_KEY_INTERCOURSE: @[@"home-logged-sex"],
                        DL_CELL_KEY_CM: @[@"home-logged-cm"],
                        DL_CELL_KEY_PERIOD_FLOW: @[@"home-logged-spotting"],
                        DL_CELL_KEY_CERVICAL: @[@"home-logged-cervic"],
                        DL_CELL_KEY_EXERCISE: @[@"home-logged-exercise"],
                        DL_CELL_KEY_WEIGHT: @[@"home-logged-weight"],
                        DL_CELL_KEY_SLEEP: @[@"home-logged-sleep"],
                        DL_CELL_KEY_MOODS: @[@"home-logged-emotional"],
                        DL_CELL_KEY_STRESS_LEVEL: @[@"home-logged-stress"],
                        DL_CELL_KEY_PHYSICALDISCOMFORT: @[@"home-logged-physical"],
                        DL_CELL_KEY_SMOKE: @[@"home-logged-smoke"],
                        DL_CELL_KEY_ALCOHOL: @[@"home-logged-alcohol"],
                        DL_CELL_KEY_OVTEST: @[@"home-logged-ovulation-neg", @"home-logged-ovulation-pos"],
                        DL_CELL_KEY_PREGNANCYTEST: @[@"home-logged-pregnancy-neg", @"home-logged-pregnancy-pos"],
                        DL_CELL_KEY_FEVER: @[@"home-logged-fever"]
                        };
    }
    
    if (!mainAttrs) {
        mainAttrs = @{
                      NSFontAttributeName:[Utils defaultFont:MAIN_FONT_SIZE],
                      NSForegroundColorAttributeName: [UIColor darkTextColor]
                      };
    }
    if (!mainHighlightAttrs) {
        mainHighlightAttrs = @{
                               NSFontAttributeName:[Utils boldFont:MAIN_FONT_SIZE],
                               NSForegroundColorAttributeName: [UIColor darkTextColor]
                               };
    }
    if (!subAttrs) {
        subAttrs = @{
                     NSFontAttributeName:[Utils semiBoldFont:SUB_FONT_SIZE],
                     NSForegroundColorAttributeName:UIColorFromRGB(0x616161)
                     };
    }
    if (!subHighlightAttrs) {
        subHighlightAttrs = @{
                              NSFontAttributeName:[Utils semiBoldFont:SUB_FONT_SIZE],
                              NSForegroundColorAttributeName: UIColorFromRGB(0x6EB839)};
    }
    if (!subBoldAttrs) {
        subBoldAttrs = @{NSFontAttributeName:[Utils semiBoldFont:SUB_FONT_SIZE]};
    }
    
    User *user = dailyData.user;
    
    NSDate *date = dailyData.nsdate;
    NSString *dateLabel = [Utils dailyDataDateLabel:date];
    
    NSArray *dataOfAll = [UserDailyData getUserDailyDataTo:dateLabel ForUser:user];
    NSArray *dataOfMonth = [UserDailyData getUserDailyDataFrom:[Utils dailyDataDateLabel:[Utils monthFirstDate:date]] to:dateLabel ForUser:user];
    NSArray *dataOfWeek = [UserDailyData getUserDailyDataFrom:[Utils dailyDataDateLabel:[Utils weekFirstDate:date]] to:dateLabel ForUser:user];
    
    if (![dailyData hasData]) {
        self.summaryView.frame = setRectHeight(self.summaryView.frame, 20);
        self.summaryView.frame = setRectX(self.summaryView.frame, 0);
        return;
    }
    
    Summary *summary = nil;
    shortHeight = 0;
    more = NO;
    [array removeAllObjects];
    [self.summaryView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    UserDailyData *lastWithBBT, *lastWithWeight;
    
    NSMutableDictionary *emotionalCount = [NSMutableDictionary dictionary];
    NSMutableDictionary *physicalCount = [NSMutableDictionary dictionary];
    
    for (NSInteger i = [dataOfAll count] - 1; i >= 0; i --) {
        UserDailyData *d = dataOfAll[i];
        if (!lastWithBBT && d.temperature > 0 && ![d.date isEqual:dateLabel]) {
            lastWithBBT = d;
        }
        if (!lastWithWeight && d.weight > 0 && ![d.date isEqual:dateLabel]) {
            lastWithWeight = d;
        }
        
        NSDictionary *emotionalSymptoms = [d getEmotionalSymptoms];
        for (NSNumber *each in emotionalSymptoms) {
            if ([emotionalCount objectForKey:each]) {
                emotionalCount[each] = @([emotionalCount[each] integerValue] + 1);
            }
            else {
                emotionalCount[each] = @(1);
            }
        }
        
        NSDictionary *physicalSymptoms = [d getPhysicalSymptoms];
        for (NSNumber *each in physicalSymptoms) {
            if ([physicalCount objectForKey:each]) {
                physicalCount[each] = @([physicalCount[each] integerValue] + 1);
            }
            else {
                physicalCount[each] = @(1);
            }
        }
    }
    
    NSInteger intercourseThisWeek = 0, cmThisWeek = 0, exerciseThisWeek = 0, smokeThisWeek = 0, alcoholThisWeek = 0;
    for (NSInteger i = [dataOfWeek count] - 1; i >=0; i --) {
        UserDailyData *d = dataOfWeek[i];
        
        if (d.intercourse >= 2) {
            intercourseThisWeek ++;
        }
        if (d.cervicalMucus >= 2) {
            cmThisWeek ++;
        }
        if (d.exercise >= 2) {
            exerciseThisWeek ++;
        }
        if (d.smoke >= 2) {
            smokeThisWeek += d.smoke - 2;
        }
        if (d.alcohol >= 2) {
            alcoholThisWeek += d.alcohol - 2;
        }
    }
    NSInteger spotThisMonth = 0, ovuTestThisMonth = 0, pregTestThisMonth = 0;
    for (NSInteger i = [dataOfMonth count] - 1; i >= 0; i --) {
        UserDailyData *d = dataOfMonth[i];
        
        if (d.periodFlow > 1 && [user predictionForDate:d.nsdate] != kDayPeriod) {
            spotThisMonth ++;
        }
        if (d.ovulationTest % BRAND_MASK > 0) {
            ovuTestThisMonth ++;
        }
        if (d.pregnancyTest % BRAND_MASK > 0) {
            pregTestThisMonth ++;
        }
    }
    
    NSString *_plainSummary = @"";
    
    if ([[dailyData valueForKey:DL_CELL_KEY_BBT] floatValue] > 0) {
        id val = [dailyData valueForKey:DL_CELL_KEY_BBT];
        NSString *k = DL_CELL_KEY_BBT;
        float bbt = [val floatValue];
        
        summary = [self getBlankSummary];
        NSMutableAttributedString *bbtMain = [self mainAttrTextForKey:k];
        [bbtMain setAttributes:mainHighlightAttrs
                         range:NSMakeRange(11, 6)];
        [bbtMain.mutableString replaceCharactersInRange:NSMakeRange(11, 6) withString:[Utils displayTextForTemperatureInCelcius:bbt]];
        [self updateNameForPartner:bbtMain.mutableString];
        summary.mainLabel.attributedText = bbtMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", bbtMain.string]];
        if (lastWithBBT) {
            NSMutableAttributedString *bbtSub = [self subAttrTextForKey:k];
            [bbtSub setAttributes:subHighlightAttrs
                            range:NSMakeRange(0, 7)];
            [bbtSub setAttributes:subBoldAttrs
                            range:NSMakeRange(13, 6)];
            
            float changes = dailyData.temperature - lastWithBBT.temperature;
            if (![[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:UNIT_CELCIUS]) {
                changes = [Utils fahrenheitFromCelcius:dailyData.temperature] - [Utils fahrenheitFromCelcius:lastWithBBT.temperature];
            }
            
            NSString *changesStr = nil;
            if (fabsf( changes) < 0.005 ) {
                changesStr = @"No changes";
            } else if (changes > 0) {
                changesStr = [NSString stringWithFormat:@"+%.2f", fabsf(changes)];
            } else {
                changesStr = [NSString stringWithFormat:@"-%.2f", fabsf(changes)];
            }
            
            [bbtSub.mutableString replaceCharactersInRange:NSMakeRange(14, 6) withString:[lastWithBBT.nsdate toReadableDate]];
            [bbtSub.mutableString replaceCharactersInRange:NSMakeRange(0, 8) withString:changesStr];
            [self updateNameForPartner:bbtSub.mutableString];
            
            summary.subLabel.attributedText = bbtSub;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", bbtSub.string]];
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_BBT iconIndex:0];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_INTERCOURSE] floatValue] >= 2) {
        NSString *k = DL_CELL_KEY_INTERCOURSE;
        summary = [self getBlankSummary];
        
        NSMutableAttributedString *intercourseMain = [self mainAttrTextForKey:k];
        //        [intercourseMain setAttributes:mainHighlightAttrs
        //                                 range:NSMakeRange(2, 3)];
        [self updateNameForPartner:intercourseMain.mutableString];
        summary.mainLabel.attributedText = intercourseMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", intercourseMain.string]];
        
        NSMutableAttributedString *intercourseSub = [self subAttrTextForKey:k];
        [intercourseSub setAttributes:subHighlightAttrs range:NSMakeRange(0, 11)];
        [intercourseSub.mutableString replaceCharactersInRange:NSMakeRange(0, 6) withString:[Utils displayOrder:intercourseThisWeek]];
        [self updateNameForPartner:intercourseSub.mutableString];
        summary.subLabel.attributedText = intercourseSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", intercourseSub.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_INTERCOURSE iconIndex:0];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_CM] floatValue] >= 2) {
        NSString *k = DL_CELL_KEY_CM;
        summary = [self getBlankSummary];
        NSInteger cm = [[dailyData valueForKey:DL_CELL_KEY_CM] integerValue];
        NSInteger texture = cm & 0xff;
        NSInteger amount = (cm >> 8) & 0xff;
        if (texture > 5 || amount > 5) {
            NSMutableAttributedString *cmMain = nil;
            if (amount <= 5) {
                cmMain = [[NSMutableAttributedString alloc] initWithString:
                          summaryDictionary[k][2] attributes:mainAttrs];
                [cmMain setAttributes:mainHighlightAttrs range:
                 NSMakeRange(10, 9)];
                NSString *textureStr = textureVal2Name(texture);
                [cmMain.mutableString replaceCharactersInRange:
                 NSMakeRange(10, 9) withString:textureStr];
            }
            else if (texture <= 5) {
                cmMain = [[NSMutableAttributedString alloc] initWithString:
                          summaryDictionary[k][3] attributes:mainAttrs];
                [cmMain setAttributes:mainHighlightAttrs range:
                 NSMakeRange(17, 8)];
                NSString *amountStr = amountVal2Name(amount);
                [cmMain.mutableString replaceCharactersInRange:
                 NSMakeRange(17, 8) withString:amountStr];
            }
            else {
                cmMain = [[NSMutableAttributedString alloc] initWithString:
                          summaryDictionary[k][4] attributes:mainAttrs];
                [cmMain setAttributes:mainHighlightAttrs range:
                 NSMakeRange(10, 9)];
                [cmMain setAttributes:mainHighlightAttrs range:
                 NSMakeRange(39, 8)];
                NSString *textureStr = textureVal2Name(texture);
                NSString *amountStr = amountVal2Name(amount);
                [cmMain.mutableString replaceCharactersInRange:
                 NSMakeRange(39, 8) withString:amountStr];
                [cmMain.mutableString replaceCharactersInRange:
                 NSMakeRange(10, 9) withString:textureStr];
            }
            [self updateNameForPartner:cmMain.mutableString];
            summary.mainLabel.attributedText = cmMain;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", cmMain.string]];
            [self _addSummary:summary cellKey:DL_CELL_KEY_CM iconIndex:0];
        }
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_PERIOD_FLOW] integerValue] > 1) {
        NSString *k = DL_CELL_KEY_PERIOD_FLOW;
        NSInteger flow = [[dailyData valueForKey:DL_CELL_KEY_PERIOD_FLOW] integerValue];
        summary = [self getBlankSummary];
        NSInteger dayType = [user predictionForDate:date];
        
        if (dayType == kDayPeriod) {
            NSString *flowStr;
            if (flow <= 12) {
                flowStr = @"spotting ";
            } else if (flow <= 35) {
                flowStr = @"light ";
            } else if (flow > 68) {
                flowStr = @"heavy ";
            } else {
                flowStr = @"medium ";
            }
            NSMutableAttributedString *periodMain = [[NSMutableAttributedString alloc] initWithString:summaryDictionary[k][2] attributes:mainAttrs];;
            [periodMain setAttributes:mainHighlightAttrs range:NSMakeRange(20, 6)];
            [periodMain.mutableString replaceCharactersInRange:NSMakeRange(20, 6) withString:flowStr];
            [self updateNameForPartner:periodMain.mutableString];
            summary.mainLabel.attributedText = periodMain;
            
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", periodMain.string]];
        } else {
            NSString *flowStr;
            if (flow == 2) {
                flowStr = @"";
            }
            else if (flow < 30)
                flowStr = @"light ";
            else if (flow > 66)
                flowStr = @"heavy ";
            else
                flowStr = @"medium ";
            NSMutableAttributedString *flowMain = [self mainAttrTextForKey:k];
            [flowMain setAttributes:mainHighlightAttrs range:NSMakeRange(14, 6)];
            [flowMain.mutableString replaceCharactersInRange:NSMakeRange(14, 6) withString:flowStr];
            [self updateNameForPartner:flowMain.mutableString];
            summary.mainLabel.attributedText = flowMain;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", flowMain.string]];
            
            NSMutableAttributedString *flowSub = [self subAttrTextForKey:k];
            [flowSub setAttributes:subHighlightAttrs range:NSMakeRange(0, 11)];
            [flowSub.mutableString replaceCharactersInRange:NSMakeRange(0, 6) withString:[Utils displayOrder:spotThisMonth]];
            [self updateNameForPartner:flowSub.mutableString];
            summary.subLabel.attributedText = flowSub;
            
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", flowSub.string]];
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_PERIOD_FLOW iconIndex:0];
    }
    
    if ([[dailyData valueForKey:DL_CELL_KEY_CERVICAL] intValue] > 0) {
        NSString *k = DL_CELL_KEY_CERVICAL;
        summary = [self getBlankSummary];
        
        NSString *cervixStatus = [dailyData getCervixDescription];
        
        NSMutableAttributedString *cervicMain = [self mainAttrTextForKey:k];
        [cervicMain setAttributes:mainHighlightAttrs range:NSMakeRange(15, 6)];
        [cervicMain.mutableString replaceCharactersInRange:NSMakeRange(15, 6) withString:cervixStatus];
        
        [self updateNameForPartner:cervicMain.mutableString];
        summary.mainLabel.attributedText = cervicMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", cervicMain.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_CERVICAL iconIndex:0];
    }
    
    if ([[dailyData valueForKey:DL_CELL_KEY_SLEEP] integerValue] > 0) {
        NSUInteger totalSeconds = [[dailyData valueForKey:DL_CELL_KEY_SLEEP] unsignedLongLongValue];
        summary = [self getBlankSummary];
        
        NSUInteger hours = (NSInteger)(totalSeconds / 3600);
        NSUInteger mins = (NSInteger)((totalSeconds % 3600) / 60);
        
        NSMutableAttributedString *sleepMain = [self mainAttrTextForKey:DL_CELL_KEY_SLEEP];
        [sleepMain setAttributes:mainHighlightAttrs range:NSMakeRange(26, 6)];
        [sleepMain setAttributes:mainHighlightAttrs range:NSMakeRange(12, 7)];
        if (mins > 0) {
            [sleepMain.mutableString replaceCharactersInRange:NSMakeRange(26, 6) withString:[NSString stringWithFormat:@"%lu", (unsigned long)mins]];
        }
        else {
            [sleepMain.mutableString deleteCharactersInRange:NSMakeRange(26, 11)];
        }
        [sleepMain.mutableString replaceCharactersInRange:NSMakeRange(12, 7) withString:[NSString stringWithFormat:@"%lu", (unsigned long)hours]];
        
        [self updateNameForPartner:sleepMain.mutableString];
        summary.mainLabel.attributedText = sleepMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", sleepMain.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_SLEEP iconIndex:0];
    }
    
    if ([[dailyData valueForKey:DL_CELL_KEY_FEVER] intValue] > 1) {
        NSString *k = DL_CELL_KEY_FEVER;
        summary = [self getBlankSummary];
        NSMutableAttributedString *text = [self mainAttrTextForKey:k];
        [self updateNameForPartner:text.mutableString];
        summary.mainLabel.attributedText = text;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", text.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_FEVER iconIndex:0];
    }
    
    
    if ([[dailyData valueForKey:DL_CELL_KEY_EXERCISE] intValue] > 1) {
        NSString *k = DL_CELL_KEY_EXERCISE;
        NSInteger exercise = [[dailyData valueForKey:DL_CELL_KEY_EXERCISE] integerValue];
        summary = [self getBlankSummary];
        NSMutableAttributedString *exerciseMain = [self mainAttrTextForKey:k];
        NSString *str;
        // ignore the right 2 bits
        exercise = exercise >> 2 << 2;
        if (exercise == 4 || exercise == 8 || exercise == 16) {
            str = @{
                    @4: @" for $$15-30$$ mins",
                    @8: @" for $$30-60$$ mins",
                    @16:@" for $$60+$$ mins"}[@(exercise)];
        } else {
            str = @"";
        }
        [exerciseMain appendAttributedString:[Utils markdownToAttributedText:str fontSize:MAIN_FONT_SIZE color:[UIColor darkTextColor]]];
        [self updateNameForPartner:exerciseMain.mutableString];
        summary.mainLabel.attributedText = exerciseMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", exerciseMain.string]];
        
        NSMutableAttributedString *exerciseSub = [self subAttrTextForKey:k];
        [exerciseSub setAttributes:subHighlightAttrs range:NSMakeRange(0, 6)];
        [exerciseSub.mutableString replaceCharactersInRange:NSMakeRange(0, 6) withString:[Utils displayOrder:exerciseThisWeek]];
        [self updateNameForPartner:exerciseSub.mutableString];
        summary.subLabel.attributedText = exerciseSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", exerciseSub.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_EXERCISE iconIndex:0];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_WEIGHT] floatValue] > 10) {
        NSString *k = DL_CELL_KEY_WEIGHT;
        float weight = [[dailyData valueForKey:DL_CELL_KEY_WEIGHT] floatValue];
        summary = [self getBlankSummary];
        
        NSMutableAttributedString *weightMain = [self mainAttrTextForKey:k];
        [weightMain setAttributes:mainHighlightAttrs range:NSMakeRange(8, 8)];
        [weightMain.mutableString replaceCharactersInRange:NSMakeRange(8, 8) withString:[Utils displayTextForWeightInKG:weight]];
        [self updateNameForPartner:weightMain.mutableString];
        summary.mainLabel.attributedText = weightMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", weightMain.string]];
        
        if (lastWithWeight) {
            NSMutableAttributedString *weightSub = [self subAttrTextForKey:k];
            [weightSub setAttributes:subHighlightAttrs range:NSMakeRange(0, 8)];
            [weightSub setAttributes:subBoldAttrs range:NSMakeRange(14, 6)];
            
            float changes = dailyData.weight - lastWithWeight.weight;
            NSString *changesStr = nil;
            if (fabsf(changes) < 0.005 ){
                changesStr = @"No changes";
            } else {
                changesStr = [NSString stringWithFormat:@"%@%@", changes>0? @"+": @"-", [Utils displayTextForWeightInKG:fabsf(changes)]];
            }
            [weightSub.mutableString replaceCharactersInRange:NSMakeRange(14, 6) withString:[lastWithWeight.nsdate toReadableDate]];
            [weightSub.mutableString replaceCharactersInRange:NSMakeRange(0, 8) withString:changesStr];
            [self updateNameForPartner:weightSub.mutableString];
            summary.subLabel.attributedText = weightSub;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", weightSub.string]];
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_WEIGHT iconIndex:0];
    }
    
    NSDictionary *emotionalSymptoms = [dailyData getEmotionalSymptoms];
    if (emotionalSymptoms.count > 0) {
        NSString *k = DL_CELL_KEY_MOODS;
        summary = [self getBlankSummary];
        NSMutableAttributedString *moodsMain = [self mainAttrTextForKey:k];
        [moodsMain setAttributes:mainHighlightAttrs range:NSMakeRange(7, 9)];
        
        NSString *moodsDescription = [self descriptionForSymptoms:emotionalSymptoms symptomType:SymptomTypeEmotional];
        [moodsMain.mutableString replaceCharactersInRange:NSMakeRange(7, 9)
                                               withString:moodsDescription];
        
        [self updateNameForPartner:moodsMain.mutableString];
        
        summary.mainLabel.attributedText = moodsMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", moodsMain.string]];
        
        NSArray *allEmotions = [emotionalCount keysSortedByValueUsingSelector:@selector(compare:)];
        NSString *common = [EmotionalSymptomNames objectForKey:[allEmotions lastObject]];
        
        if (common) {
            NSMutableAttributedString *moodSub = [self subAttrTextForKey:k];
            [moodSub setAttributes:subHighlightAttrs range:NSMakeRange(13, 8)];
            [moodSub replaceCharactersInRange:NSMakeRange(13, 8) withString:common];
            [self updateNameForPartner:moodSub.mutableString];
            summary.subLabel.attributedText = moodSub;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", moodSub.string]];
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_MOODS iconIndex:0];
    }
    
    NSDictionary *physicalSymptoms = [dailyData getPhysicalSymptoms];
    if (physicalSymptoms.count > 0) {
        NSString *k = DL_CELL_KEY_PHYSICALDISCOMFORT;
        summary = [self getBlankSummary];
        NSMutableAttributedString *physMain = [self mainAttrTextForKey:k];
        [physMain setAttributes:mainHighlightAttrs range:NSMakeRange(6, 12)];
        
        NSString *physicalDescription = [self descriptionForSymptoms:physicalSymptoms
                                                         symptomType:SymptomTypePhysical];
        
        [physMain.mutableString replaceCharactersInRange:NSMakeRange(6, 12)
                                              withString:physicalDescription];
        
        [self updateNameForPartner:physMain.mutableString];
        
        summary.mainLabel.attributedText = physMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", physMain.string]];
        
        NSArray *allPhysicals = [physicalCount keysSortedByValueUsingSelector:@selector(compare:)];
        NSMutableDictionary *physicalMapping = [PhysicalSymptomNames mutableCopy];
        [physicalMapping addEntriesFromDictionary:PhysicalSymptomNamesForMale];
        NSString *common = [physicalMapping objectForKey:[allPhysicals lastObject]];
        
        if (common) {
            NSMutableAttributedString *phySub = [self subAttrTextForKey:k];
            [phySub setAttributes:subHighlightAttrs range:NSMakeRange(13, 8)];
            [phySub replaceCharactersInRange:NSMakeRange(13, 8) withString:common];
            [self updateNameForPartner:phySub.mutableString];
            summary.subLabel.attributedText = phySub;
            _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", phySub.string]];
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_PHYSICALDISCOMFORT iconIndex:0];
    }
    
    if ([[dailyData valueForKey:DL_CELL_KEY_STRESS_LEVEL] integerValue] >= 2) {
        NSString *k = DL_CELL_KEY_STRESS_LEVEL;
        NSInteger stress = [[dailyData valueForKey:DL_CELL_KEY_STRESS_LEVEL]
                            integerValue];
        summary = [self getBlankSummary];
        NSMutableAttributedString *stressMain = [self mainAttrTextForKey:k];
        [stressMain setAttributes:mainHighlightAttrs range:
         NSMakeRange(19, 7)];
        [stressMain.mutableString replaceCharactersInRange:NSMakeRange(19, 7)
                                                withString:stressLevelVal2Name(stress)];
        [self updateNameForPartner:stressMain.mutableString];
        summary.mainLabel.attributedText = stressMain;
        _plainSummary = [_plainSummary stringByAppendingString:
                         [NSString stringWithFormat:@"\u2022 %@\n", stressMain.string]];
        
        [self _addSummary:summary cellKey:DL_CELL_KEY_STRESS_LEVEL iconIndex:0];
    }
    
    if ([[dailyData valueForKey:DL_CELL_KEY_SMOKE] integerValue] > 2) {
        NSString *k = DL_CELL_KEY_SMOKE;
        NSInteger smoke = [[dailyData valueForKey:DL_CELL_KEY_SMOKE] integerValue];
        smoke = smoke - 2;
        summary = [self getBlankSummary];
        
        NSMutableAttributedString *smokeMain = [self mainAttrTextForKey:k];
        [smokeMain setAttributes:mainHighlightAttrs range:NSMakeRange(9, 7)];
        [smokeMain.mutableString replaceCharactersInRange:NSMakeRange(9, 7)
                                               withString:[NSString stringWithFormat:@"%ld cigarette%@", (long)smoke, smoke>1 ? @"s": @""]];
        [self updateNameForPartner:smokeMain.mutableString];
        summary.mainLabel.attributedText = smokeMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", smokeMain.string]];
        
        NSMutableAttributedString *smokeSub = [self subAttrTextForKey:k];
        [smokeSub setAttributes:subHighlightAttrs range:NSMakeRange(7, 7)];
        [smokeSub.mutableString replaceCharactersInRange:NSMakeRange(7, 7)
                                              withString:[NSString stringWithFormat:@"%ld cigarette%@", (long)smokeThisWeek, smokeThisWeek>1 ? @"s": @""]];
        [self updateNameForPartner:smokeSub.mutableString];
        summary.subLabel.attributedText = smokeSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", smokeSub.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_SMOKE iconIndex:0];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_ALCOHOL] integerValue] > 2) {
        NSString *k = DL_CELL_KEY_ALCOHOL;
        NSInteger alcohol = [[dailyData valueForKey:DL_CELL_KEY_ALCOHOL] integerValue];
        alcohol = alcohol - 2;
        summary = [self getBlankSummary];
        
        NSMutableAttributedString *alcoholMain = [self mainAttrTextForKey:k];
        [alcoholMain setAttributes:mainHighlightAttrs range:NSMakeRange(11, 7)];
        [alcoholMain.mutableString replaceCharactersInRange:NSMakeRange(11, 7)
                                                 withString:[NSString stringWithFormat:@"%ld glass%@", (long)alcohol, alcohol>1? @"es": @""]];
        [self updateNameForPartner:alcoholMain.mutableString];
        summary.mainLabel.attributedText = alcoholMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", alcoholMain.string]];
        
        NSMutableAttributedString *alcoholSub = [self subAttrTextForKey:k];
        [alcoholSub setAttributes:subHighlightAttrs range:NSMakeRange(9, 7)];
        [alcoholSub.mutableString replaceCharactersInRange:NSMakeRange(9, 7)
                                                withString:[NSString stringWithFormat:@"%ld glass%@", (long)alcoholThisWeek, alcoholThisWeek>1? @"es": @""]];
        [self updateNameForPartner:alcoholSub.mutableString];
        summary.subLabel.attributedText = alcoholSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", alcoholSub.string]];
        [self _addSummary:summary cellKey:DL_CELL_KEY_ALCOHOL iconIndex:0];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_OVTEST] integerValue] %
        BRAND_MASK > 0) {
        NSString *k = DL_CELL_KEY_OVTEST;
        NSInteger ovtest = [[dailyData valueForKey:DL_CELL_KEY_OVTEST] integerValue];
        NSInteger iconIndex = 0;
        NSInteger v = ovtest % BRAND_MASK;
        NSInteger b = ovtest / BRAND_MASK;
        summary = [self getBlankSummary];
        
        NSArray *brands = @[@" Clearblue Digital",
                            @" Clearblue Easy Read",
                            @" First Response Digital",
                            @" First Response Fertility"];
        NSArray *values = @[
                            @[@"Peak", @"Low", @"High"],
                            @[@"High", @"Low"],
                            @[@"High", @"Low"],
                            @[@"High", @"Low"],
                            @[@"High", @"Low"]];
        
        NSString *brand = (b >= 1 && b<= 4)? brands[b - 1]: @"n";//n to form 'an'
        NSString *value = @"";
        if (b >= 0 && b <= 5) {
            if (b == 0) {
                b = 5;
            }
            NSArray *valArr = values[b-1];
            if (v >= 1 && v <= [valArr count] ) {
                value = valArr[v-1];
            }
        }
        
        NSMutableAttributedString *ovuMain = [self mainAttrTextForKey:k];
        [ovuMain setAttributes:mainHighlightAttrs range:NSMakeRange(8, 7)];
        [ovuMain setAttributes:mainHighlightAttrs range:NSMakeRange(46, 8)];
        
        [ovuMain.mutableString replaceCharactersInRange:NSMakeRange(46, 8) withString:value];
        [ovuMain.mutableString replaceCharactersInRange:NSMakeRange(8, 7) withString:brand];
        if (b == 0 || b == 5) {
            //AN ovulation test
            [ovuMain setAttributes:mainAttrs range:NSMakeRange(8, 1)];
        }
        [self updateNameForPartner:ovuMain.mutableString];
        summary.mainLabel.attributedText = ovuMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", ovuMain.string]];
        
        NSMutableAttributedString *ovuSub = [self subAttrTextForKey:k];
        [ovuSub setAttributes:subHighlightAttrs range:NSMakeRange(6, 6)];
        [ovuSub.mutableString replaceCharactersInRange:NSMakeRange(6, 6) withString:[NSString stringWithFormat:@"%ld", (long)ovuTestThisMonth]];
        [self updateNameForPartner:ovuSub.mutableString];
        summary.subLabel.attributedText = ovuSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", ovuSub.string]];
        
        if (v == 1) {
            iconIndex = 1;
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_OVTEST iconIndex:iconIndex];
    }
    if ([[dailyData valueForKey:DL_CELL_KEY_PREGNANCYTEST] integerValue] %
        BRAND_MASK > 0) {
        NSString *k = DL_CELL_KEY_PREGNANCYTEST;
        NSInteger iconIndex = 0;
        NSInteger pregtest = [[dailyData valueForKey:DL_CELL_KEY_PREGNANCYTEST] integerValue];
        NSInteger v = pregtest % BRAND_MASK;
        NSInteger b = pregtest / BRAND_MASK;
        summary = [self getBlankSummary];
        
        NSArray *brands = @[@" Clearblue Digital",
                            @" Clearblue",
                            @" First Response Gold",
                            @" First Response"];
        NSArray *values = @[
                            @[@"positive", @"negative"],
                            @[@"positive", @"negative"],
                            @[@"positive", @"negative"],
                            @[@"positive", @"negative"],
                            @[@"positive", @"negative"],
                            ];
        
        NSString *brand = (b >= 1 && b<= 4)? brands[b - 1]: @"";
        NSString *value = @"";
        if (b >= 0 && b <= 5) {
            if (b == 0) {
                b = 5;
            }
            NSArray *valArr = values[b-1];
            if (v >= 1 && v <= [valArr count] ) {
                value = valArr[v-1];
            }
        }
        
        NSMutableAttributedString *pregMain = [self mainAttrTextForKey:k];
        [pregMain setAttributes:mainHighlightAttrs range:NSMakeRange(8, 7)];
        [pregMain setAttributes:mainHighlightAttrs range:NSMakeRange(43, 8)];
        
        [pregMain.mutableString replaceCharactersInRange:NSMakeRange(43, 8) withString:value];
        [pregMain.mutableString replaceCharactersInRange:NSMakeRange(8, 7) withString:brand];
        [self updateNameForPartner:pregMain.mutableString];
        summary.mainLabel.attributedText = pregMain;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"\u2022 %@\n", pregMain.string]];
        
        NSMutableAttributedString *pregSub = [self subAttrTextForKey:k];
        [pregSub setAttributes:subHighlightAttrs range:NSMakeRange(6, 6)];
        [pregSub.mutableString replaceCharactersInRange:NSMakeRange(6, 6) withString:[NSString stringWithFormat:@"%ld", (long)pregTestThisMonth]];
        [self updateNameForPartner:pregSub.mutableString];
        summary.subLabel.attributedText = pregSub;
        _plainSummary = [_plainSummary stringByAppendingString:[NSString stringWithFormat:@"  %@\n", pregSub.string]];
        
        if (v == 1) {
            iconIndex = 1;
        }
        [self _addSummary:summary cellKey:DL_CELL_KEY_PREGNANCYTEST
                iconIndex:iconIndex];
    }
    
    if (_plainSummary && ![Utils isEmptyString:_plainSummary]) {
        if (!plainSummaries) {
            plainSummaries = [@{} mutableCopy];
        }
        
        plainSummaries[dateLabel] = _plainSummary;
    }
    
    
    // sort to different categories
    NSDictionary *summaryViews = @{
                                   @"Fertility":[NSMutableArray array],
                                   @"Physical":[NSMutableArray array],
                                   @"Emotional":[NSMutableArray array]
                                   };
    
    [summaryCategory enumerateKeysAndObjectsUsingBlock:^(NSString *categoryName, NSArray *requiredCells, BOOL *stop) {
        [requiredCells enumerateObjectsUsingBlock:^(NSString *cellKey, NSUInteger idx, BOOL *stop) {
            [array enumerateObjectsUsingBlock:^(Summary *summary, NSUInteger idx, BOOL *stop) {
                if ([summary.cellKey isEqual:cellKey]) {
                    NSMutableArray *views = summaryViews[categoryName];
                    [views addObject:summary];
                    [array removeObject:summary];
                    *stop = YES;
                }
            }];
        }];
    }];
    
    CGFloat h = 0;
    NSInteger count = 0;
    
    for (NSString *categoryName in @[@"Fertility", @"Physical", @"Emotional"]) {
        
        NSArray* summaries = summaryViews[categoryName];
        
        if (!summaries || summaries.count == 0) {
            continue;
        }
        
        // add section header
        NSString * title;
        if ([categoryName isEqualToString:@"Fertility"] && !dailyData.user.isFemale) {
            title = @"Sperm Health";
        } else {
            title = categoryName;
        }
        UIView *separator = [self separatorViewWithTitle:title];
        separator.top = h;
        [self.summaryView addSubview:separator];
        h += separator.height;
        
        // add section data
        for (Summary *s in summaries) {
            s.frame = setRectY(s.frame, h);
            [self.summaryView addSubview:s];
            
            
            Summary *previous = [self.summaryView.subviews count] > 1? self.summaryView.subviews[[self.summaryView.subviews count] - 2]: nil;
            if (!previous || [previous isEqual:s]) {
                NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:s
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.summaryView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:0];
                [self.summaryView addConstraint:c];
            }
            NSLayoutConstraint *c = [NSLayoutConstraint constraintWithItem:s
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.summaryView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.0
                                                                  constant:0];
            [self.summaryView addConstraint:c];
            count++;
            
            if (count > 3) {
                if (!more) {
                    shortHeight = h - 20;
                    more = YES;
                }
            }
            
            h += s.frame.size.height;
            if (!more) {
                shortHeight = h;
            }
        }
        
    }
    
    self.summaryView.frame = setRectHeight(self.summaryView.frame, h);
    
    self.summaryView.frame = setRectX(self.summaryView.frame, 0);
}

- (UIView *)separatorViewWithTitle:(NSString *)title
{
    CGFloat width = self.summaryView.width;
    CGFloat heigit = 26;
    UIColor *color = [UIColor colorFromWebHexValue:@"b3b3b3"];
    CGFloat centerY = 14;
    
    // container view
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, width, heigit)];
    //    view.backgroundColor = [UIColor redColor];
    // text
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, width, heigit)];
    label.text = title;
    label.font = [Utils defaultFont:15];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = color;
    label.centerY = centerY;
    [view addSubview:label];
    
//    CGFloat padding = 16;
//    CGFloat lineWidth = width / 3 - 20;
//    
//    // left line
//    UIView *leftLine = [[UIView alloc]init];
//    leftLine.backgroundColor = color;
//    leftLine.width = lineWidth;
//    leftLine.height = 0.5;
//    leftLine.centerY = centerY;
//    leftLine.left = padding;
//    [view addSubview:leftLine];
//    
//    // right line
//    UIView *rightLine = [[UIView alloc]init];
//    rightLine.backgroundColor = color;
//    rightLine.width = lineWidth;
//    rightLine.height = 0.5;
//    rightLine.centerY = centerY;
//    rightLine.left = width - lineWidth - padding;
//    [view addSubview:rightLine];
    
    return view;
}

- (NSString *)fertilitySectionTitle
{
    return dailyData.user.isFemale ? @"Fertility" : @"Sperm Health";
}

- (void)_addSummary:(Summary *)summary cellKey:(NSString *)k iconIndex:
(NSInteger)iconIndex {
    if (summary && ![self shouldHideKey:k]) {
        summary.cellKey = k;
        summary.frame = setRectWidth(summary.frame, SCREEN_WIDTH - 16);
        summary.icon.image = [UIImage imageNamed:summaryIcon[k][iconIndex]];
        float w = summary.width - 62;
        CGSize size = [summary.mainLabel sizeForBound:CGSizeMake(w, 1000)];
        
        summary.frame = setRectHeight(summary.frame, summary.frame.size.height + size.height - 18);
        if ([Utils isEmptyString:summary.subLabel.text]) {
            //No subtitle, reduce size.
            summary.frame = setRectHeight(summary.frame, summary.frame.size.height - 18);
        }
        
        if (DETECT_TIPS) {
            UILinkLabel *linkLabel = (UILinkLabel *)summary.mainLabel;
            [linkLabel clearCallbacks];
            for (NSString *tip in [Tooltip keywords]) {
                [linkLabel setCallback:^(NSString *str) {
                    [Tooltip tip:str];
                } forKeyword:tip];
            }
        }
        
        [array addObject:summary];
    }
}

+ (NSString *)plainSummaryForDate:(NSString *)date {
    if (!plainSummaries) {
        return @"";
    } else {
        return plainSummaries[date]?: @"";
    }
}
+ (void)clearPlainSummary {
    plainSummaries = nil;
}


- (NSString *)descriptionForSymptoms:(NSDictionary *)symptoms symptomType:(SymptomType)type
{
    NSMutableDictionary *physicalMapping = [PhysicalSymptomNames mutableCopy];
    [physicalMapping addEntriesFromDictionary:PhysicalSymptomNamesForMale];
    NSDictionary *mapping = type == SymptomTypePhysical ? physicalMapping : EmotionalSymptomNames;
    
    NSMutableArray *names = [NSMutableArray array];
    for (NSNumber *each in symptoms) {
        [names addObject:mapping[each]];
    }
    
    [names sortUsingSelector:@selector(compare:)];
    
    NSMutableString *description = [NSMutableString stringWithString:[names componentsJoinedByString:@", "]];
    
    NSRange lastComma = [description rangeOfString:@"," options:NSBackwardsSearch];
    if(lastComma.location != NSNotFound) {
        [description replaceCharactersInRange:lastComma withString:@" and"];
    }
    
    // replace sick with sickness
    NSRange sick = [description rangeOfString:@"Sick"];
    if (sick.location != NSNotFound) {
        [description replaceCharactersInRange:sick withString:@"Sickness"];
    }
    
    return description;
}


@end

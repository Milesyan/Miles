//
//  ChartInfoVIew.m
//  emma
//
//  Created by Xin Zhao on 13-7-15.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//


#import "ChartInfoVIew.h"
#import "ChartConstants.h"
#import "ChartData.h"
#import "DailyLogConstants.h"
#import "XYPieChart.h"
#import "User.h"
#import "DailyLogCellTypeMucus.h"
#import "UserDailyData+CervicalPosition.h"
#import "UserDailyData+Symptom.h"
#import "ExportReportDialog.h"

#define CHART_INFO_VIEW_RADIUS 55.0f
#define CHART_INFO_VIEW_GLOW_RADIUS 70.0f

#define FERTILITY_TITLES @[@"BBT: ", @"OPK: ", @"HPT: ", @"Sex: ", @"CM: ", @"CP: "]
#define FERTILITY_TITLES_FOR_PARTNER @[@"BBT: ", @"OPK: ", @"HPT: ", @"Sex: ", @"", @""]
#define WEIGHT_TITLES @[@"Weight: ", @"Exercise: ", @"BMI: ", @"Sex: ", @"Physical: ", @"Emotional: "]
#define CALORIE_TITLES @[@"Consumed: ", @"Burned: ", @"Weight: ", @"Exercise: ", @"BMI: ", @"Via: "]

CG_INLINE float bestRadius(float spaceX, float spaceY) {
    return MIN(spaceX / 2, MIN(spaceY / 2, MAX(spaceX * .3f, MAX(spaceY *.3f,
        MIN(spaceX, spaceY) / 2 * PIE_DIAMETER_2_BOUND))));;
}

@interface ChartInfoView (){

    __weak IBOutlet UIView *nutritionDateContainer;
    __weak IBOutlet UIButton *prevNutritionDateButton;
    __weak IBOutlet UIButton *nextNutritionDateButton;
    __weak IBOutlet UILabel *nutritionDateLabel;
    __weak IBOutlet UILabel *nutritionVia;
    __weak IBOutlet UILabel *nutritionCarb;
    __weak IBOutlet UIView *nutritionCarbLegend;
    __weak IBOutlet UILabel *nutritionCarbGoal;
    __weak IBOutlet UILabel *nutritionFat;
    __weak IBOutlet UIView *nutritionFatLegend;
    __weak IBOutlet UILabel *nutritionFatGoal;
    __weak IBOutlet UILabel *nutritionProtein;
    __weak IBOutlet UIView *nutritionProteinLegend;
    __weak IBOutlet UILabel *nutritionProteinGoal;
    __weak IBOutlet UIView *nutritionHightlightView;

    __weak IBOutlet UIView *nutritionSummaryView;

    __weak IBOutlet UILabel *date;
    __weak IBOutlet UILabel *cycleDay;
    __weak IBOutlet UILabel *hint;
    IBOutletCollection(UILabel) NSArray *titles;
    IBOutletCollection(UILabel) NSArray *values;
    
    BOOL useMetricUnit;
    BOOL isCelsius;
    NSInteger chartDataType;
    NSMutableDictionary *tag2Title;
    NSMutableDictionary *tag2Value;
    CGFloat userHeight;
}



@end

@implementation ChartInfoView

static NSDictionary *INFO_PANEL_LABEL_CONFIG = nil;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [self setPieChartParameters];
    INFO_PANEL_LABEL_CONFIG = @{
        @"PORTRAIT": @{
            @"intervalY": @15,
            @"right": @20,
            @"rows": @6,
        },
        @"LANDSCAPE": @{
            @"intervalY": @18,
            @"right": @20,
            @"rows": @3,
        }
    };
    
    NSMutableAttributedString *exportString = [[NSMutableAttributedString alloc] initWithString:@"Export PDF Report"];
    NSDictionary *attrs = @{NSUnderlineStyleAttributeName: [NSNumber numberWithInteger:NSUnderlineStyleSingle],
                            NSFontAttributeName: [Utils defaultFont:14],
                            NSForegroundColorAttributeName: [UIColor whiteColor]};
    [exportString addAttributes:attrs range:NSMakeRange(0, exportString.length)];
    
    if ([User currentUser].isSecondaryOrSingleMale) {
        self.exportReportButton.hidden = YES;
    } else {
        self.exportReportButton.hidden = NO;
    }
    
    [self.exportReportButton setAttributedTitle:exportString forState:UIControlStateNormal];
    
    self.exportReportButton.imageEdgeInsets = UIEdgeInsetsMake(4, 0, 8, 0);
    self.exportReportButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.exportReportButton sizeToFit];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setupPointerWithRadius:(CGFloat)dotRadius {
    self.currentDayDot.hidden = YES;
    self.currentDayDot.frame = CGRectMake(-100, -100, 3 * dotRadius, 3 * dotRadius);
    self.currentDayDot.layer.cornerRadius = self.currentDayDot.frame.size.width / 2;
    self.currentDayDot.layer.masksToBounds = YES;
    UIView *innerDot = (UIView *)[self.currentDayDot subviews][0];
    innerDot.frame = CGRectMake(0, 0, 2 * dotRadius, 2 * dotRadius);
    innerDot.center = CGPointMake(1.5f * dotRadius, 1.5f * dotRadius);
    innerDot.layer.cornerRadius = innerDot.frame.size.width / 2;
    innerDot.layer.masksToBounds = YES;
    self.self.extraDayDot.hidden = YES;
    self.extraDayDot.frame = CGRectMake(-100, -100, 3 * dotRadius, 3 * dotRadius);
    self.extraDayDot.layer.cornerRadius = self.currentDayDot.frame.size.width / 2;
    self.extraDayDot.layer.masksToBounds = YES;
    innerDot = (UIView *)[self.extraDayDot subviews][0];
    innerDot.frame = CGRectMake(0, 0, 2 * dotRadius, 2 * dotRadius);
    innerDot.center = CGPointMake(1.5f * dotRadius, 1.5f * dotRadius);
    innerDot.layer.cornerRadius = innerDot.frame.size.width / 2;
    innerDot.layer.masksToBounds = YES;
}

- (void)setupNutritionViewInDataType:(NSInteger)dataType {
    if (CHART_DATA_TYPE_NUTRITION == dataType) {
        self.nutritionView.hidden = NO;
        
        nextNutritionDateButton.transform = CGAffineTransformMakeScale(-1, 1);
        nutritionCarbLegend.layer.cornerRadius = 8;
        nutritionFatLegend.layer.cornerRadius = 8;
        nutritionProteinLegend.layer.cornerRadius = 8;
        nutritionProteinGoal.text = [NSString stringWithFormat:@"%ld%%",
            (long)[[User currentUser] nutritionGoalProtein]];
        nutritionFatGoal.text = [NSString stringWithFormat:@"%ld%%",
            (long)[[User currentUser] nutritionGoalFat]];
        nutritionCarbGoal.text = [NSString stringWithFormat:@"%ld%%",
            (long)[[User currentUser] nutritionGoalCarb]];
        [self updatePieChartInRect:self.nutritionView.frame];
    }
    else {
        self.nutritionView.hidden = YES;
    }
    self.currentArrow.hidden = self.infoPanel.hidden =
        !self.nutritionView.isHidden;
    
}

- (void)setupInfoPanelInDataType:(NSInteger)dataType landscape:(BOOL)isLandscape{
    chartDataType = dataType;
    isCelsius = [[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:
        UNIT_CELCIUS];
    useMetricUnit = [[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:
        UNIT_KG];
    userHeight = [User currentUser].settings.height;
    
    tag2Title = [@{} mutableCopy];
    tag2Value = [@{} mutableCopy];
    if (CHART_DATA_TYPE_TEMP == dataType) {
        if ([User currentUser].isSecondary) {
            [self _setupInfoPanelWithTitles:FERTILITY_TITLES_FOR_PARTNER dataType:dataType
                                  landscape:isLandscape];
        } else {
            [self _setupInfoPanelWithTitles:FERTILITY_TITLES dataType:dataType
                                  landscape:isLandscape];

        }
    } else if (CHART_DATA_TYPE_WEIGHT == dataType) {
        [self _setupInfoPanelWithTitles:WEIGHT_TITLES dataType:dataType
            landscape:isLandscape];
    } else if (CHART_DATA_TYPE_CALORIE == dataType) {
        [self _setupInfoPanelWithTitles:CALORIE_TITLES dataType:dataType
            landscape:isLandscape];
    }
}

- (void)_setupInfoPanelWithTitles:(NSArray *)labelTitles dataType:(NSInteger)dataType
    landscape:(BOOL)isLandscape{
    float maxW = 0;
    for (UILabel *title in titles) {
        title.text = labelTitles[title.tag];
        tag2Title[@(title.tag)] = title;
        [title sizeToFit];
        maxW = MAX(title.frame.size.width, maxW);
    }
    for (UILabel *title in titles) {
        title.frame = setRectWidth(title.frame, maxW);
    }
    for (UILabel *value in values) {
        tag2Value[@(value.tag)] = value;
//        value.backgroundColor = UIColorFromRGBA(0xaaaaaa80);
        
    }
    [self _posInfoPanelLabelsDataType:dataType landscape:isLandscape];
}

- (void)_posInfoPanelLabelsDataType:(NSInteger)dataType landscape:(BOOL)isLandscape{
    NSString *dir = isLandscape ? @"LANDSCAPE" : @"PORTRAIT";
    NSDictionary *conf = INFO_PANEL_LABEL_CONFIG[dir];
        float infoW = self.infoPanel.frame.size.width;
    float infoH = self.infoPanel.frame.size.height;
    float i = [conf[@"intervalY"] floatValue];
    int rows = [conf[@"rows"] intValue];
    float t = (infoH - i * rows) / 2;
    float titleEndX = 60;
    float titleEndX2 = 160;
    if (titles.count > 0 && values.count > 0) {
        titleEndX = ((UILabel*)titles[0]).frame.size.width + 10;
        titleEndX2 = 2 * titleEndX + ((UILabel*)values[0]).frame.size.width + 3;
    }
    
    float r = [conf[@"right"] floatValue];
    
    date.center = (CGPoint){infoW - r - date.frame.size.width / 2,
        t + date.frame.size.height / 2};
    cycleDay.center = (CGPoint){infoW - r - date.frame.size.width / 2,
        t + date.frame.size.height + cycleDay.frame.size.height / 2};;
    if (!isLandscape) {
        for (NSNumber *tag in tag2Title) {
            UILabel *title = tag2Title[tag];
            title.center = (CGPoint){titleEndX - title.frame.size.width / 2,
                [tag intValue] * i + t + title.frame.size.height / 2};
        }
        for (NSNumber *tag in tag2Value) {
            UILabel *v = tag2Value[tag];
            v.center = (CGPoint){titleEndX + 3 + v.frame.size.width / 2,
                [tag intValue] * i + t + v.frame.size.height / 2};
        }
//        hint.alpha = 1;
//        hint.center = (CGPoint){infoW - r - hint.frame.size.width / 2,
//            self.infoPanel.frame.size.height - t - hint.frame.size.height / 2};
        if (dataType == CHART_DATA_TYPE_TEMP && [User currentUser].isPrimaryOrSingle) {
            self.exportReportButton.hidden = NO;
            self.exportReportButton.center = CGPointMake(infoW - r - self.exportReportButton.width / 2,
                                                         self.infoPanel.height - t - self.exportReportButton.height / 2);
        }
        else {
            self.exportReportButton.hidden = YES;
        }

    } else {
        for (NSNumber *tag in tag2Title) {
            int _t = [tag intValue];
            float _titleEndX = _t < rows ? titleEndX : titleEndX2;
            UILabel *title = tag2Title[tag];
            title.center = (CGPoint){_titleEndX - title.frame.size.width / 2,
                (_t % rows) * i + t + title.frame.size.height / 2};
        }
        for (NSNumber *tag in tag2Value) {
            int _t = [tag intValue];
            float _titleEndX = _t < rows ? titleEndX : titleEndX2;
            UILabel *v = tag2Value[tag];
            v.center = (CGPoint){_titleEndX + 3 + v.frame.size.width / 2,
                (_t % rows) * i + t + v.frame.size.height / 2};
        }
        self.exportReportButton.hidden = YES;
    }
    
    hint.hidden = YES;
}

- (void)updateDateWithDateIdx:(NSInteger)dateIdx cycleDay:(NSInteger)cd ovulationDay:(NSInteger)ov{
    NSDate *d = [Utils dateIndexToDate:dateIdx];
    date.text = [Utils formatedWithFormat:@"MMM d, YYYY" date:d];

    BOOL needShowCycleDay = chartDataType == CHART_DATA_TYPE_TEMP || [User currentUser].isPrimaryOrSingle;

    if (!needShowCycleDay) {
        cycleDay.text = @"";
        return;
    }
    
    
    NSString *cdText = cd <= 0 ? nil : [NSString stringWithFormat:@"Cycle day %ld", (long)cd];
    NSString *ovText = ov <= 0 ? nil : [NSString stringWithFormat:@"DPO %ld", (long)ov];
    
    if (cdText) {
        cycleDay.text = cdText;
    }
    if (ovText && ![User currentUser].isFertilityTreatmentUser) {
        cycleDay.text = [cdText stringByAppendingFormat:@", %@", ovText];
    }
}

- (void)updateInfoPanelWithDailyData:(UserDailyData *)daily {
//    if (!daily) {
//        for (UILabel *value in values) {
//            value.text = @"--";
//        }
//        return;
//    }
    if (CHART_DATA_TYPE_TEMP == chartDataType) {
        [self _updateForFertilityChartWithDailyData:daily];
    } else if (CHART_DATA_TYPE_WEIGHT == chartDataType) {
        [self _updateForWeightChartWithDailyData:daily];
    } else if (CHART_DATA_TYPE_CALORIE == chartDataType) {
        [self _updateForCalorieChartWithDailyData:daily];
    }
}

- (void)_updateForFertilityChartWithDailyData:(UserDailyData *)daily {
    UILabel *v = tag2Value[@(0)];
    if (daily.temperature < 30) {
        v.text = @"--";
    }
    else {
        CGFloat val = daily.temperature;
        if (!isCelsius) val = [Utils fahrenheitFromCelcius:val];
        v.text = catstr([Utils stringWithFloatOfTwoToZeroDecimal:
            @"%f" float:val], (isCelsius ? @"°C" : @"°F"), nil);
    }
    v = tag2Value[@(1)];
    if (daily.ovulationTest % 10 == 0) {
        v.text = @"--";
    }
    else {
        v.text = daily.ovulationTest % 10 == 3
            ? @"High" : (daily.ovulationTest % 10 == 1 ? @"Pos" : @"Neg");
    }
    v = tag2Value[@(2)];
    if (daily.pregnancyTest % 10 == 0) {
        v.text = @"--";
    }
    else {
        v.text = daily.pregnancyTest % 10 == 1 ? @"Pos" : @"Neg";
    }
    v = tag2Value[@(3)];
    if (daily.intercourse == 0) {
        v.text = @"--";
    }
    else {
        v.text = daily.intercourse >= 2 ? @"Yes" : @"No";
    }
    
    v = tag2Value[@(4)];
    if (daily.cervicalMucus <= 1) {
        v.text = @"--";
    }
    else {
        NSInteger tex = daily.cervicalMucus & 0xff;
        NSInteger amt = (daily.cervicalMucus >> 8) & 0xff;
        v.text = catstr(capstr(amountVal2Name(amt)), @", ",
            capstr(textureVal2Name(tex)), nil);
    }
    if ([User currentUser].isSecondaryOrSingleMale) {
        v.text = @"";
    }
    
    v = tag2Value[@(5)];
    if (daily.cervical == 0) {
        v.text = @"--";
    }
    else {
        NSDictionary *status = [daily getCervicalPositionStatus];
        v.text = [UserDailyData statusDescriptionForCervicalStatus:status seperateBy:@" & "];
    }
    if ([User currentUser].isSecondaryOrSingleMale) {
        v.text = @"";
    }

}

- (void)_updateForWeightChartWithDailyData:(UserDailyData *)daily {
    UILabel *v = tag2Value[@(0)];
    if (daily.weight <= 10) {
        v.text = @"--";
    }
    else {
        CGFloat val = daily.weight;
        if (!useMetricUnit) val = [Utils poundsFromKg:val];
        v.text = catstr([Utils stringWithFloatOfOneOrZeroDecimal:
            @"%f" float:val], (useMetricUnit ? @"KG" : @"LB"), nil);
    }
    v = tag2Value[@(1)];
    if (daily.exercise == 0) {
        v.text = @"--";
    }
    else {
        if (daily.exercise & 4) {
            v.text = @"15-30 mins";
        } else if (daily.exercise & 8) {
            v.text = @"30-60 mins";
        } else if (daily.exercise & 16) {
            v.text = @"60+ mins";
        }
    }
    v = tag2Value[@(2)];
    if (daily.weight <= 10 || userHeight <= 10) {
        v.text = @"--";
    }
    else {
        v.text = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:
            [Utils calculateBmiWithHeightInCm:userHeight weightInKg:
            daily.weight]];
    }
    v = tag2Value[@(3)];
    if (daily.intercourse == 0) {
        v.text = @"--";
    }
    else {
        v.text = daily.intercourse >= 2 ? @"Yes" : @"No";
    }
    
    v = tag2Value[@(4)];
    NSDictionary *physicalSymptoms = [daily getPhysicalSymptoms];
    if (physicalSymptoms.count == 0) {
        v.text = @"--";
    }
    else {
        NSNumber *symp = [physicalSymptoms.allKeys firstObject];
        v.text = [PhysicalSymptomNames objectForKey:symp];
    }
    
    if (physicalSymptoms.count > 1) {
        v.text = catstr(v.text, @" ...", nil);
    }
    
//    if (daily.physicalDiscomfort <= 1) {
//        v.text = @"--";
//    }
//    else {
//        NSInteger hitCount = 0;
//        NSString *t = @"--";
//        for (NSNumber *b in PHYSICAL_DISCOMFORT_NAME) {
//            if (!(daily.physicalDiscomfort & [b intValue])) {
//                continue;
//            }
//            if (0 == hitCount) {
//                t = capstr(PHYSICAL_DISCOMFORT_NAME[b]);
//                hitCount++;
//            }
//            else if (1 == hitCount) {
//                t = catstr(t, @" ...", nil);
//                break;
//            }
//            else {
//                break;
//            }
//        }
//        v.text = t;
//    }
    
    v = tag2Value[@(5)];
    NSDictionary *emotionalSymptoms = [daily getEmotionalSymptoms];
    if (emotionalSymptoms.count == 0) {
        v.text = @"--";
    }
    else {
        NSNumber *symp = [emotionalSymptoms.allKeys firstObject];
        v.text = [EmotionalSymptomNames objectForKey:symp];
    }
    
    if (emotionalSymptoms.count > 1) {
        v.text = catstr(v.text, @" ...", nil);
    }
    
//    if (daily.moods <= 1) {
//        v.text = @"--";
//    }
//    else {
//        NSInteger hitCount = 0;
//        NSString *t = @"--";
//        for (NSNumber *b in MOODS_NAME) {
//            if (!(daily.moods & [b intValue])) {
//                continue;
//            }
//            if (0 == hitCount) {
//                t = capstr(MOODS_NAME[b]);
//                hitCount++;
//            }
//            else if (1 == hitCount) {
//                t = catstr(t, @" ...", nil);
//                break;
//            }
//            else {
//                break;
//            }
//        }
//        v.text = t;
//    }
}

- (void)_updateForCalorieChartWithDailyData:(UserDailyData *)daily {
    UILabel *v = tag2Value[@(2)];
    if (daily.weight <= 10) {
        v.text = @"--";
    }
    else {
        CGFloat val = daily.weight;
        if (!useMetricUnit) val = [Utils poundsFromKg:val];
        v.text = catstr([Utils stringWithFloatOfOneOrZeroDecimal:
            @"%f" float:val], (useMetricUnit ? @"KG" : @"LB"), nil);
    }
    v = tag2Value[@(3)];
    if (daily.exercise == 0) {
        v.text = @"--";
    }
    else {
        if (daily.exercise & 4) {
            v.text = @"15-30 mins";
        } else if (daily.exercise & 8) {
            v.text = @"30-60 mins";
        } else if (daily.exercise & 16) {
            v.text = @"60+ mins";
        }
    }
    v = tag2Value[@(4)];
    if (daily.weight <= 10 || userHeight <= 10) {
        v.text = @"--";
    }
    else {
        v.text = daily.pregnancyTest % 10 == 1 ? @"Pos" : @"Neg";
        v.text = [Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:
            [Utils calculateBmiWithHeightInCm:userHeight weightInKg:
            daily.weight]];
    }
}

- (void)updateInfoPanelWithNutritionDesc:(NSDictionary *)desc {
    UILabel *v = tag2Value[@(0)];
    NSInteger val = [desc[@"calIn"] integerValue];
    v.text = val > 0 ? catstr([@(val) stringValue], @" cal", nil) : @"--";
    v = tag2Value[@(1)];
    val = [desc[@"calOut"] integerValue];
    v.text = val > 0 ? catstr([@(val) stringValue], @" cal", nil) : @"--";
    v = tag2Value[@(5)];
    v.text = desc[@"via"];
}

- (void)updateNutritionLegendsWithNutrition:(NSDictionary *)nutrition
    atDateIdx:(NSInteger)dateIdx {
    if (chartDataType == CHART_DATA_TYPE_NUTRITION) {
        [_nutritionChart reloadData];
        NSDate *d = [Utils dateIndexToDate:dateIdx];
        nutritionDateLabel.text = [NSString stringWithFormat:@"%@ / %@",
            [d weekdayString], [d toReadableFullDate]];
        
        nutritionCarb.text = nutrition[@"carb"];
        nutritionFat.text = nutrition[@"fat"];
        nutritionProtein.text = nutrition[@"protein"];
        
        BOOL manuallySynced =
            [[Utils getDefaultsForKey:NUTRITION_DATA_MANUALLY_SYNCED]
            [[Utils dateIndexToDateLabelFrom20130101:dateIdx]] boolValue];
        
        if (dateIdx > [Utils dateToIntFrom20130101:[NSDate date]]) {
            nutritionVia.text = @"";
            nutritionVia.hidden = YES;
            nutritionVia.userInteractionEnabled = NO;
        } else {
            nutritionVia.attributedText = [[NSAttributedString alloc]
                initWithString:[NSString stringWithFormat:@"Sync%@ via %@",
                manuallySynced ? @"ed": @"", nutrition[@"via"]]
                attributes:@{
                    NSForegroundColorAttributeName: manuallySynced
                    ? UIColorFromRGB(0x889298) : UIColorFromRGB(0x5B65CE),
                    NSFontAttributeName: [Utils defaultFont:15],}];
            nutritionVia.hidden = NO;
            nutritionVia.userInteractionEnabled = YES;
        }
    }
}

- (void)showCurrentDotAtX:(CGFloat)x y:(CGFloat)y inDataType:(NSInteger)dataType
    withRadius:(CGFloat)dotRadius extra:(NSArray*)extra{
    self.currentDayDot.hidden = YES;
    if (extra) {
        self.extraDayDot.hidden = YES;
    }
    [self moveCurrentDotAtX:x y:y inDataType:dataType extra:extra];
    self.currentDayDot.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
    self.currentDayDot.hidden = NO;
    [UIView animateWithDuration:0.1f animations:^{
        self.currentDayDot.transform = CGAffineTransformIdentity;
    } completion:nil];
    if (extra) {
        self.extraDayDot.transform = CGAffineTransformMakeScale(0.01f, 0.01f);
        self.extraDayDot.hidden = NO;
        [UIView animateWithDuration:0.1f animations:^{
            self.extraDayDot.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
    
}

- (void)moveCurrentDotAtX:(CGFloat)x y:(CGFloat)y inDataType:(NSInteger)dataType
    extra:(NSArray*)extra {
    UIView *redDot = [self.currentDayDot subviews][0];
    if (CHART_DATA_TYPE_TEMP & dataType) {
        redDot.backgroundColor = TEMP_CURVE_COLOR;
    }
    if (CHART_DATA_TYPE_WEIGHT & dataType) {
        redDot.backgroundColor = WEIGHT_CURVE_COLOR;
    }
    if (CHART_DATA_TYPE_CALORIE & dataType) {
        redDot.backgroundColor = CALORIE_IN_CURVE_COLOR;
    }
    self.currentDayDot.center = CGPointMake(x, y);
    
    if (extra) {
        UIView *innerDot = [self.extraDayDot subviews][0];
        if (CHART_DATA_TYPE_CALORIE & dataType) {
            innerDot.backgroundColor = CALORIE_OUT_CURVE_COLOR;
        }
        self.extraDayDot.center = CGPointMake([extra[0] floatValue],
            [extra[1] floatValue]);
        if (self.extraDayDot.isHidden) {
            self.extraDayDot.hidden = NO;
        }
    }
    else {
        if (!self.extraDayDot.isHidden) {
            self.extraDayDot.hidden = YES;
        }
    }
}

- (void)posCurrentDotAtX:(CGFloat)x y:(CGFloat)y inDataType:(NSInteger)dataType
    withRadius:(CGFloat)dotRadius extra:(NSArray *) extra{
    if (self.currentDayDot.hidden) {
        [self showCurrentDotAtX:x y:y inDataType:dataType withRadius:dotRadius
            extra:extra];
    }
    else {
        [self moveCurrentDotAtX:x y:y inDataType:dataType extra:extra];
    }
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
    self.currentDayDot.alpha = alpha;
}

- (void)setPieChartDelegate:(id<XYPieChartDelegate>) delegate {
    _nutritionChart.delegate = delegate;
}
- (void)setPieChartDataSource:(id<XYPieChartDataSource>) dataSource {
    _nutritionChart.dataSource = dataSource;
    [_nutritionChart reloadData];
}

- (void)setPieChartParameters {
    [_nutritionChart setStartPieAngle:M_PI * 2];
    [_nutritionChart setAnimationSpeed:1.0];
    [_nutritionChart setLabelFont:[Utils defaultFont:20]];
    [_nutritionChart setLabelRadius:50];
    [_nutritionChart setShowPercentage:YES];
    [_nutritionChart setPieBackgroundColor:UIColorFromRGB(0xB4B4B4)];
    [_nutritionChart setPieCenter:CGPointMake(0, 0)];
    [_nutritionChart setUserInteractionEnabled:YES];
    [_nutritionChart setLabelShadowColor:[UIColor grayColor]];
    
    nutritionHightlightView.layer.cornerRadius = 2;
    nutritionHightlightView.alpha = 0;
}

- (void)updatePieChartForDateChange:(NSDate *)date {
//    nutritionDateLabel.text = @"Monday / April 1, 2014";
    [_nutritionChart reloadData];
}

- (void)setPieChartHidden:(BOOL)hidden {
    self.nutritionView.hidden = hidden;
}

- (void)highLight:(NSInteger)line {
    if (line < 0 || line > 2) {
        return;
    }
    float y = [ @[@41, @67, @93][line] floatValue];
    [UIView animateWithDuration:0.3 animations:^{
        nutritionHightlightView.frame = setRectY(nutritionHightlightView.frame, y);
        nutritionHightlightView.alpha = 1;
    }];
    
}
- (void)stopHighLight {
    [UIView animateWithDuration:0.3 animations:^{
        nutritionHightlightView.alpha = 0;
    }];
}

- (void)updatePieChartInRect:(CGRect)rect {
    // BOOL SHORT = !IS_IPHONE_5;
    float w = self.nutritionView.frame.size.width;
    float h = self.nutritionView.frame.size.height;
    CGSize dateSize = nutritionDateContainer.frame.size;
    CGSize summarySize = nutritionSummaryView.frame.size;
    if (rect.size.height > rect.size.width) {
        nutritionDateContainer.center = (CGPoint) {
            self.nutritionView.center.x,
            nutritionDateContainer.frame.size.height / 2
        };
       
        nutritionSummaryView.center = (CGPoint) {
            self.nutritionView.center.x,
            self.nutritionView.frame.size.height -
            nutritionSummaryView.frame.size.height / 2
        };
        
        float spaceY = self.nutritionView.frame.size.height -
            nutritionSummaryView.frame.size.height -
            nutritionDateContainer.frame.size.height;
        float spaceX = self.nutritionView.frame.size.width;
        CGPoint pieCenter = (CGPoint) {spaceX / 2,
            nutritionDateContainer.frame.origin.y +
            nutritionDateContainer.frame.size.height + spaceY / 2};
        
        _nutritionChart.frame = setRectX(_nutritionChart.frame, pieCenter.x);
        _nutritionChart.frame = setRectY(_nutritionChart.frame, pieCenter.y);
        float r = bestRadius(spaceX, spaceY);
        [_nutritionChart setPieRadius:r];
        [_nutritionChart reloadData];


    } else {
        float spaceY = h;
        float spaceX = spaceY * 0.618f;
        if (spaceX + dateSize.width > w) {
            spaceX = w - dateSize.width;
        }
        float r = bestRadius(spaceX, spaceY);
        
        CGPoint pieCenter = (CGPoint) {
            (w - 2 * r - dateSize.width) / 2 + r,
            spaceY / 2};
        
        _nutritionChart.frame = setRectX(_nutritionChart.frame,
            pieCenter.x <= r + 5 ? pieCenter.x + 20 : pieCenter.x);
        _nutritionChart.frame = setRectY(_nutritionChart.frame, pieCenter.y);
        
        [_nutritionChart setPieRadius:r];
        [_nutritionChart reloadData];
       
        float dateStartX = pieCenter.x + spaceX / 2;
        nutritionDateContainer.center = (CGPoint) {
            dateStartX + dateSize.width > w
            ? w - dateSize.width / 2
            : dateStartX + dateSize.width / 2,
            pieCenter.y - r
        };
        nutritionSummaryView.center = (CGPoint) {
            dateStartX + summarySize.width > w
            ? w - summarySize.width / 2
            : dateStartX + summarySize.width / 2,
            pieCenter.y + nutritionSummaryView.frame.size.height / 2
        };
    }
}

- (void)hideViewsExceptForChartView
{
    nutritionDateContainer.alpha = 0;
    nutritionSummaryView.alpha = 0;
}

- (void)showViewsExceptForChartView
{
    nutritionDateContainer.alpha = 1;
    nutritionSummaryView.alpha = 1;
}


- (IBAction)exportReport:(id)sender
{
    [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
}


@end

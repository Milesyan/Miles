//
//  MedicalLogDataController.m
//  emma
//
//  Created by Peng Gu on 10/17/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogDataController.h"
#import "HealthProfileData.h"
#import "User.h"
#import "MedicalLogItem.h"
#import "UserMedicalLog.h"
#import "MedManager.h"
#import "UserStatusDataManager.h"
#import <GLQuestionKit/GLQuestionCell.h>
#import <GLQuestionKit/GLYesOrNoQuestion.h>
#import <GLQuestionKit/GLPickerQuestion.h>
#import <GLQuestionKit/GLNumberQuestion.h>
#import <GLQuestionKit/GLDateQuestion.h>
#import "Appointment.h"

@interface MedicalLogDataController ()
@property (nonatomic, strong) UserStatus *userStatus;
@end


@implementation MedicalLogDataController
- (instancetype)initWithDate:(NSString *)dateString
{
    self = [super init];
    if (self) {
        self.date = dateString;
        self.userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:dateString forUser:[User userOwnsPeriodInfo]];
        [self setupQuestions];
    }
    return self;
}

- (void)setupQuestions
{
    self.questions = [NSMutableArray array];
    [self.questions addObject:self.bloodWorkQuestion];
    [self.questions addObject:self.ultraSoundQuestion];
    [self.questions addObject:self.hcgShotQuestion];
    if (self.userStatus.treatmentType == TREATMENT_TYPE_IUI) {
        [self.questions addObject:self.inseminationQuestion];
    }
    else if (self.userStatus.treatmentType == TREATMENT_TYPE_IVF) {
        [self.questions addObject:self.eggRetrievalQuestion];
        [self.questions addObject:self.embryosFrozenNumberQuestion];
        [self.questions addObject:self.embryosTransferQuestion];
    }
    
    for (GLQuestion *question in self.questions) {
        [self populateQuestionAnswer:question];
        for (NSArray *questions in question.subQuestions) {
            for (GLQuestion *subQuestion in questions) {
                [self populateQuestionAnswer:subQuestion];
            }
        }
    }
}

- (void)populateQuestionAnswer:(GLQuestion *)question
{
    UserMedicalLog *medicalLog = [UserMedicalLog medicalLogWithKey:question.key date:self.date user:[User currentUser]];
    if ([question isKindOfClass:[GLYesOrNoQuestion class]]) {
        if ([medicalLog.dataValue integerValue] == BinaryValueTypeYes) {
            question.answer = ANSWER_YES;
        } else if ([medicalLog.dataValue integerValue] == BinaryValueTypeNo){
            question.answer = ANSWER_NO;
        } else {
            question.answer = nil;
        }
    } else {
        question.answer = medicalLog.dataValue;
    }
    question.model = medicalLog;

}

- (GLQuestion *)bloodWorkQuestion
{
    GLYesOrNoQuestion *bloodWork = [GLYesOrNoQuestion new];
    bloodWork.key = kMedItemBloodWork;
    bloodWork.title = @"Did you have blood work done?";
    bloodWork.answerToShowSubQuestions = ANSWER_YES;
    bloodWork.subQuestionsSeparatorTitles = @[@"Hormone levels"];
    
    GLNumberQuestion *estrogenLevel = [GLNumberQuestion new];
    estrogenLevel.key = kMedItemEstrogenLevel;
    estrogenLevel.title = @"Estrogen level";
    estrogenLevel.unitList = @[[GLUnit unitWithName:@"pg/ml" weight:1]];
    estrogenLevel.maximumValue = 12000;
    
    GLNumberQuestion *progesteroneLevel = [GLNumberQuestion new];
    progesteroneLevel.key = kMedItemProgesteroneLevel;
    progesteroneLevel.title = @"Progesterone level";
    progesteroneLevel.unitList = @[[GLUnit unitWithName:@"nmol/l" weight:1]];
    progesteroneLevel.maximumValue = 300;
    
    GLNumberQuestion *luteinizingHormoneLevel = [GLNumberQuestion new];
    luteinizingHormoneLevel.key = kMedItemLuteinizingHormoneLevel;
    luteinizingHormoneLevel.title = @"LH level";
    luteinizingHormoneLevel.unitList = @[[GLUnit unitWithName:@"iu/l" weight:1]];
    luteinizingHormoneLevel.maximumValue = 100;

    bloodWork.subQuestions = @[@[estrogenLevel, progesteroneLevel, luteinizingHormoneLevel]];
    return bloodWork;
}

- (GLQuestion *)ultraSoundQuestion
{
    GLYesOrNoQuestion *ultrasound = [GLYesOrNoQuestion new];
    ultrasound.key = kMedItemUltrasound;
    ultrasound.title = @"Did you have an ultrasound?";
    ultrasound.answerToShowSubQuestions = ANSWER_YES;
    
    GLPickerQuestion *folliclesNumber = [GLPickerQuestion new];
    folliclesNumber.key = kMedItemFolliclesNumber;
    folliclesNumber.title = @"# of developed follicles";
    NSMutableArray *folliclesNumberTitles = [NSMutableArray array];
    NSMutableArray *folliclesNumberValues = [NSMutableArray array];
    for (int i = 0; i <= 40; i++) {
        [folliclesNumberTitles addObject:[NSString stringWithFormat:@"%d", i]];
        [folliclesNumberValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    folliclesNumber.optionTitles = folliclesNumberTitles;
    folliclesNumber.optionValues = folliclesNumberValues;
    
    
    GLPickerQuestion *folliclesSize = [GLPickerQuestion new];
    folliclesSize.key = kMedItemFolliclesSize;
    folliclesSize.title = @"Leading follicle size";
    folliclesSize.unitList = @[[GLUnit unitWithName:@"mm" weight:1]];
    NSMutableArray *folliclesSizeTitles = [NSMutableArray array];
    NSMutableArray *folliclesSizeValues = [NSMutableArray array];
    for (int i = 1; i <= 30; i++) {
        [folliclesSizeTitles addObject:[NSString stringWithFormat:@"%d mm", i]];
        [folliclesSizeValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    folliclesSize.optionTitles = folliclesSizeTitles;
    folliclesSize.optionValues = folliclesSizeValues;
    
    
    GLPickerQuestion *uterineLiningThickness = [GLPickerQuestion new];
    uterineLiningThickness.key = kMedItemUterineLiningThickness;
    uterineLiningThickness.title = @"Thickness of endometrial lining";
    uterineLiningThickness.unitList = @[[GLUnit unitWithName:@"mm" weight:1]];
    NSMutableArray *uterineLiningThicknessTitles = [NSMutableArray array];
    NSMutableArray *uterineLiningThicknessValues = [NSMutableArray array];
    for (int i = 1; i <= 20; i++) {
        [uterineLiningThicknessTitles addObject:[NSString stringWithFormat:@"%d mm", i]];
        [uterineLiningThicknessValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    uterineLiningThickness.optionTitles = folliclesSizeTitles;
    uterineLiningThickness.optionValues = folliclesSizeValues;
    
    
    ultrasound.subQuestionsSeparatorTitles = @[@"Additional Info"];
    ultrasound.subQuestions = @[@[folliclesNumber, folliclesSize, uterineLiningThickness]];
    ultrasound.subQuestionsSeparatorTitles = @[@"Additional Info"];
    return ultrasound;
}

- (GLQuestion *)hcgShotQuestion
{
    GLYesOrNoQuestion *hcgShot = [GLYesOrNoQuestion new];
    hcgShot.key = kMedItemHCGTriggerShot;
    hcgShot.title = @"Was an hCG shot administered?";
    hcgShot.answerToShowSubQuestions = ANSWER_YES;
    
    GLDateQuestion *hcgShotTime = [GLDateQuestion new];
    hcgShotTime.key = kMedItemHCGTriggerShotTime;
    hcgShotTime.title = @"When";
    hcgShotTime.pickerMode = MODE_TIME;
    
    hcgShot.subQuestionsSeparatorTitles = @[@"Additional Info"];
    hcgShot.subQuestions = @[@[hcgShotTime]];
    hcgShot.subQuestionsSeparatorTitles = @[@"Additional Info"];
    return hcgShot;
}

- (GLQuestion *)inseminationQuestion
{
    GLYesOrNoQuestion *insemination = [GLYesOrNoQuestion new];
    insemination.key = kMedItemInsemination;
    insemination.title = @"Was your insemination today?";
    return insemination;
}

- (GLQuestion *)eggRetrievalQuestion
{
    GLYesOrNoQuestion *eggRetrieval = [GLYesOrNoQuestion new];
    eggRetrieval.key = kMedItemEggRetrieval;
    eggRetrieval.title = @"Was your egg retrieval today?";
    eggRetrieval.answerToShowSubQuestions = ANSWER_YES;
    
    GLPickerQuestion *eggRetrievalNumber = [GLPickerQuestion new];
    eggRetrievalNumber.key = kMedItemEggRetrievalNumber;
    eggRetrievalNumber.title = @"How many?";
    NSMutableArray *eggRetrievalNumberTitles = [NSMutableArray array];
    NSMutableArray *eggRetrievalNumberValues = [NSMutableArray array];
    for (int i = 1; i <= 30; i++) {
        [eggRetrievalNumberTitles addObject:[NSString stringWithFormat:@"%d", i]];
        [eggRetrievalNumberValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    eggRetrievalNumber.optionTitles = eggRetrievalNumberTitles;
    eggRetrievalNumber.optionValues = eggRetrievalNumberValues;
    
    
    GLYesOrNoQuestion *freezeEmbryosFuture = [GLYesOrNoQuestion new];
    freezeEmbryosFuture.key = kMedItemFreezeEmbryosFuture;
    freezeEmbryosFuture.title = @"Planning on freezing any embryos for future cycles?";
    
    eggRetrieval.subQuestionsSeparatorTitles = @[@"Additional Info"];
    eggRetrieval.subQuestions = @[@[eggRetrievalNumber, freezeEmbryosFuture]];
    eggRetrieval.subQuestionsSeparatorTitles = @[@"Additional Info"];
    return eggRetrieval;
}

- (GLQuestion *)embryosFrozenNumberQuestion
{
    GLPickerQuestion *embryosFrozenNumber = [GLPickerQuestion new];
    embryosFrozenNumber.key = kMedItemEmbryosFrozenNumber;
    embryosFrozenNumber.title = @"Have you frozen any embryos?";
    NSMutableArray *embryosFrozenNumberTitles = [NSMutableArray array];
    NSMutableArray *embryosFrozenNumberValues = [NSMutableArray array];
    for (int i = 1; i <= 10; i++) {
        [embryosFrozenNumberTitles addObject:[NSString stringWithFormat:@"%d", i]];
        [embryosFrozenNumberValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    embryosFrozenNumber.optionTitles = embryosFrozenNumberTitles;
    embryosFrozenNumber.optionValues = embryosFrozenNumberValues;
    return embryosFrozenNumber;
}

- (GLQuestion *)embryosTransferQuestion
{
    GLYesOrNoQuestion *embryosTransfer = [GLYesOrNoQuestion new];
    embryosTransfer.key = kMedItemEmbryosTransfer;
    embryosTransfer.title = @"Was your embryo transfer today?";
    embryosTransfer.answerToShowSubQuestions = ANSWER_YES;
    
    GLPickerQuestion *embryosTransferNumber = [GLPickerQuestion new];
    embryosTransferNumber.key = kMedItemEmbryosTransferNumber;
    embryosTransferNumber.title = @"How many embryos did you transfer?";
    NSMutableArray *embryosTransferNumberTitles = [NSMutableArray array];
    NSMutableArray *embryosTransferNumberValues = [NSMutableArray array];
    for (int i = 1; i <= 10; i++) {
        [embryosTransferNumberTitles addObject:[NSString stringWithFormat:@"%d", i]];
        [embryosTransferNumberValues addObject:[NSString stringWithFormat:@"%d", i]];
    }
    embryosTransferNumber.optionTitles = embryosTransferNumberTitles;
    embryosTransferNumber.optionValues = embryosTransferNumberValues;
    
    GLPickerQuestion *freshOrFrozenEmbryos = [GLPickerQuestion new];
    freshOrFrozenEmbryos.key = kMedItemFreshOrFrozenEmbryos;
    freshOrFrozenEmbryos.title = @"Did you use fresh or frozen embryos?";
    freshOrFrozenEmbryos.optionTitles = @[@"Fresh", @"Frozen"];
    freshOrFrozenEmbryos.optionValues = @[@"1", @"2"];
    
    embryosTransfer.subQuestionsSeparatorTitles = @[@"Additional Info"];
    embryosTransfer.subQuestions = @[@[embryosTransferNumber, freshOrFrozenEmbryos]];
    embryosTransfer.subQuestionsSeparatorTitles = @[@"Additional Info"];
    return embryosTransfer;
}

- (BOOL)hasChanges
{
    for (GLQuestion *question in self.questions) {
        if (question.modified) {
            return YES;
        }
        for (NSArray *questions in question.subQuestions) {
            for (GLQuestion *subQuestion in questions) {
                if (subQuestion.modified) {
                    return YES;
                }
            }

        }
    }
    return NO;
}


- (void)saveAllToModel
{
    for (GLQuestion *question in self.questions) {
        if (question.modified) {
            [self saveQuestionAnswer:question];
        }
        for (NSArray *questions in question.subQuestions) {
            for (GLQuestion *subQuestion in questions) {
                if (subQuestion.modified) {
                    [self saveQuestionAnswer:subQuestion];
                }
            }
        }
    }
}

- (void)saveQuestionAnswer:(GLQuestion *)question
{
    if ([question.key isEqualToString:kMedItemHCGTriggerShotTime]) {
        [self createAppointmentForHcgTriggerShot:question];
    }
    
    UserMedicalLog *medicalLog = question.model;
    if (!medicalLog) {
        medicalLog = [UserMedicalLog newInstance:[User currentUser].dataStore];
        medicalLog.date = self.date;
        medicalLog.dataKey = question.key;
        medicalLog.user = [User currentUser];
    }
    if ([question isKindOfClass:[GLYesOrNoQuestion class]]) {
        if ([question.answer isEqualToString: ANSWER_YES]) {
            [medicalLog update:@"dataValue" value: [NSString stringWithFormat:@"%lu", (unsigned long)BinaryValueTypeYes]];
        } else if ([question.answer isEqualToString: ANSWER_NO]){
            [medicalLog update:@"dataValue" value: [NSString stringWithFormat:@"%lu", (unsigned long)BinaryValueTypeNo]];
        } else {
            [medicalLog update:@"dataValue" value: [NSString stringWithFormat:@"%lu", (unsigned long)BinaryValueTypeNone]];
        }
    } else {
        [medicalLog update:@"dataValue" value:question.answer];
    }
}

- (void)createAppointmentForHcgTriggerShot:(GLQuestion *)question
{
    if (question.answer) {
        NSDate *time1 = [NSDate dateWithTimeIntervalSince1970:([question.answer integerValue] + 60 * 60 * 35)];
        [Appointment createOrUpdateAppointment:nil title:@"Arrive at clinic" note:nil when:time1 repeat:REPEAT_NO on:YES forUser:[User currentUser]];
        
        
        if (self.userStatus.treatmentType == TREATMENT_TYPE_IUI) {
            NSDate *time2 = [NSDate dateWithTimeIntervalSince1970:([question.answer integerValue] + 60 * 60 * 36)];
            [Appointment createOrUpdateAppointment:nil title:@"Insemination" note:nil when:time2 repeat:REPEAT_NO on:YES forUser:[User currentUser]];
        }
        else if (self.userStatus.treatmentType == TREATMENT_TYPE_IVF) {
            NSDate *time2 = [NSDate dateWithTimeIntervalSince1970:([question.answer integerValue] + 60 * 60 * 36)];
            [Appointment createOrUpdateAppointment:nil title:@"Egg retrieval" note:nil when:time2 repeat:REPEAT_NO on:YES forUser:[User currentUser]];
        }
    }
}

@end

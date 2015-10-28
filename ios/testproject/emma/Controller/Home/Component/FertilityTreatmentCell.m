//
//  AddMedicalLogCell.m
//  emma
//
//  Created by Peng Gu on 10/16/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "FertilityTreatmentCell.h"
#import "UserMedicalLog.h"
#import "User.h"
#import "MedicalLogSummaryView.h"
#import "MedicalLogItem.h"
#import "Appointment.h"
#import "HealthProfileData.h"
#import "UIView+Emma.h"
#import "UserStatusDataManager.h"
#import "UILinkLabel.h"
#import <GLPeriodEditor/GLDateUtils.h>


@interface FertilityTreatmentCell ()
@property (nonatomic, strong) UIView *separatorView;
@property (nonatomic, strong) UIView *emptyAppointmentView;
@end


@implementation FertilityTreatmentCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.containerView addDefaultBorder];

    self.appointmentArrowImageView.highlightedImage = [Utils imageNamed:@"log-arrow" withColor:[UIColor whiteColor]];
    self.appointmentDateLabel.highlightedTextColor = [UIColor whiteColor];
    self.appointmentTitleLabel.highlightedTextColor = [UIColor whiteColor];
    
    self.separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0.5)];
    self.separatorView.backgroundColor = UIColorFromRGB(0xe2e2e2);
    
    [self.logButton setTitleColor:UIColorFromRGB(0x3f47ae) forState:UIControlStateHighlighted];
    self.logButton.adjustsImageWhenHighlighted = NO;

    [self.medicalLogView addDefaultBorder];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
}


- (void)setHasLogs:(BOOL)hasLogs
{
    _hasLogs = hasLogs;
    [self layoutIfNeeded];
}


- (void)configureWithDate:(NSDate *)date dateRelation:(DateRelationOfToday)dateRelation
{
    [self clearViewsFromContainer];
    
    NSString *dateLabel = [Utils dailyDataDateLabel:date];
    
    BOOL showTreatmentEnd = [self hasTreatmentEndCellForDate:date];
    
    // Treatment end
    if (showTreatmentEnd) {
        [self addTreatmentEndView];
        return;
    }
    
    // Appointment
    Appointment *appt = [self appointmentForDate:date dateRelation:dateRelation];
    if (appt) {
        [self addAppointmentViewWithAppointment:appt];
    } else {
        [self addEmpytAppointmentView];
    }
    

    // Medical Summary
    self.hasLogs = [UserMedicalLog user:[User userOwnsPeriodInfo] hasMedicalLogsOnDate:dateLabel];

    BOOL hasPositiveData = NO;
    if (self.hasLogs) {
        hasPositiveData = [self addSummaryViewWithDate:date];
    }
    
    // Add Medical Log button
    if ([User currentUser].isSecondary) {
        [self addSeparator];
        NSString *text;
        if (!self.hasLogs) {
            if (dateRelation == dateRelationToday) {
                text = [NSString stringWithFormat:@"%@ hasn’t logged today.", [User currentUser].partner.firstName];
            } else {
                text = [NSString stringWithFormat:@"%@ did not log on this day.", [User currentUser].partner.firstName];
            }
            [self addPartnerInfoViewToContainerWithText:text];
        } else if (self.hasLogs && !hasPositiveData) {
            if (dateRelation == dateRelationToday) {
                text = [NSString stringWithFormat:@"%@ logged today.", [User currentUser].partner.firstName];
            } else {
                text = [NSString stringWithFormat:@"%@ logged on this day.", [User currentUser].partner.firstName];
            }
            [self addPartnerInfoViewToContainerWithText:text];
        }
    } else {
        if (self.hasLogs) {
            [self.logButton setTitle:@"Fertility treatment logged!" forState:UIControlStateNormal];
            [self.logButton setImage:[UIImage imageNamed:@"check-green"] forState:UIControlStateNormal];
        } else {
            [self.logButton setTitle:@"Add fertility treatment log" forState:UIControlStateNormal];
            [self.logButton setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        [self addViewToContainer:self.medicalLogView];
    }
    
}


- (void)addSeparator
{
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 0.5)];
    separatorView.backgroundColor = UIColorFromRGB(0xe2e2e2);
    [self addViewToContainer:separatorView];

}

- (void)addPartnerInfoViewToContainerWithText:(NSString *)text;
{
    CGFloat labelWidth = SCREEN_WIDTH - 15 * 2 - 8 * 2;
    UIFont *labelFont = [Utils defaultFont:18];
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = labelFont;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.text = text;
    label.width = labelWidth;
    label.height = [text boundingRectWithSize:CGSizeMake(labelWidth, 500) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:labelFont} context:nil].size.height;
    label.backgroundColor = [UIColor whiteColor];
    
    CGFloat paddingTop = 18;
    
    UIView *lastView = self.containerView.subviews.lastObject;
    label.top = lastView.bottom;
    [self.containerView addSubview:label];
    
    self.heightThatFits = label.bottom + paddingTop * 2 + 8;
    
    [label mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(lastView.bottom + paddingTop));
        make.left.equalTo(@(16));
        make.height.equalTo(@(label.height));
        make.width.equalTo(@(label.width));
    }];
}


- (void)addViewToContainer:(UIView *)view
{
    UIView *lastView = self.containerView.subviews.lastObject;
    if (lastView) {
        view.top = lastView.bottom;
    } else {
        view.top = 0;
    }
    [self.containerView addSubview:view];
    
    self.heightThatFits = view.bottom + 8;
    
    [view mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (lastView) {
            make.top.equalTo(lastView.mas_bottom);
        } else {
            make.top.equalTo(@(0));
        }
        make.left.equalTo(view.superview.mas_left);
        make.right.equalTo(view.superview.mas_right);
        make.height.equalTo(@(view.height));
    }];
}


- (void)clearViewsFromContainer
{
    NSArray *subViews = self.containerView.subviews;
    for (int i = 0; i < subViews.count; i++) {
        UIView *view = subViews[i];
        [view removeFromSuperview];
    }
}


#pragma mark - Appointment
- (Appointment *)appointmentForDate:(NSDate *)date dateRelation:(DateRelationOfToday)dateRelation
{
    if ((dateRelation == dateRelationToday) &&
        [User currentUser].settings.currentStatus == AppPurposesTTCWithTreatment) {
        return [Appointment currentUserUpcomingAppointmentForDate:date];
    }
    else {
        return nil;
    }
}


- (void)addAppointmentViewWithAppointment:(Appointment *)appt
{
    NSDateFormatter * fmt = [[NSDateFormatter alloc] init];
    [fmt setDateFormat:@"MMM dd, yyyy 'at' h:mm a"];
    NSString * timeStr = [NSString stringWithFormat:@"%@, %@", [appt.date weekdayString], [fmt stringFromDate:appt.date]];
    self.appointmentTitleLabel.text = appt.title;
    self.appointmentDateLabel.text = timeStr;
    [self addViewToContainer:self.appointmentView];
}

- (void)addEmpytAppointmentView
{
    [self addViewToContainer:self.emptyAppointmentView];
}

- (UIView *)emptyAppointmentView
{
    if (_emptyAppointmentView) {
        return _emptyAppointmentView;
    }
    _emptyAppointmentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 50)];
    UILabel *label = [[UILinkLabel alloc] initWithFrame:CGRectMake(15, 0, 280, 30)];
    label.centerY = 25;
    label.font = [Utils defaultFont:15];
    label.textColor = UIColorFromRGB(0x6e6e6e);
    label.text = @"No upcoming appointment.";
    label.backgroundColor = [UIColor whiteColor];
    [_emptyAppointmentView addSubview:label];
    
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(195, 0, 66, 30)];
    button.titleLabel.font = [Utils defaultFont:15];
    button.centerY = 25;
    NSAttributedString *string = [[NSAttributedString alloc] initWithString:@"Add one?" attributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle), NSForegroundColorAttributeName:GLOW_COLOR_PURPLE}];
    [button setAttributedTitle:string forState:UIControlStateNormal];
    [button addTarget:self action:@selector(goToAlertPage) forControlEvents:UIControlEventTouchUpInside];
    [_emptyAppointmentView addSubview:button];

    return _emptyAppointmentView;
}


#pragma mark - treatment end
- (BOOL)hasTreatmentEndCellForDate:(NSDate *)date
{
    if ([User currentUser].isSecondary) {
        return NO;
    }
    BOOL isToday = [Utils date:date isSameDayAsDate:[NSDate date]];
    if (!isToday) {
        return NO;
    }
    UserStatus *lastTreatment = [[UserStatusDataManager sharedInstance] lastTreatmentStatusForUser:[User userOwnsPeriodInfo]];
    if (!lastTreatment) {
        return NO;
    }
    if ([GLDateUtils daysBetween:lastTreatment.endDate and:date] > 0) {
        return YES;
    }
    return NO;
}


- (void)addTreatmentEndView
{
    
    UserStatus *lastHistory = [[UserStatusDataManager sharedInstance] lastTreatmentStatusForUser:[User userOwnsPeriodInfo]];

    FertilityTreatmentType type = (int)[User currentUser].settings.fertilityTreatment;
    NSString *treatment = [HealthProfileData shortDescriptionForFertilityTreatmentType:type];
    NSString *title = [NSString stringWithFormat:@"Start a new %@ cycle", treatment];
    [self.startCycleButton setTitle:title forState:UIControlStateNormal];
    
    if (lastHistory.treatmentType == TREATMENT_TYPE_PREPARING) {
        self.treatmentEndAskPregnancy.hidden = YES;
        self.treatmentEndView.height = 208 - 45;
    }
    else {
        self.treatmentEndAskPregnancy.hidden = NO;
        self.treatmentEndView.height = 208;
    }
    
    [self addViewToContainer:self.treatmentEndView];
}


#pragma mark - Seperator
- (void)addSummarySeparatorView
{
    [self addViewToContainer:self.seperatorView];
}


#pragma mark - summary
- (BOOL)addSummaryViewWithDate:(NSDate *)date
{
    BOOL hasPositiveData = NO;
    // get logs
    NSSet *logs = [UserMedicalLog medicalLogsOnDate:[Utils dailyDataDateLabel:date]
                                            forUser:[User userOwnsPeriodInfo]];
    
    NSMutableSet *medicationLogs = [NSMutableSet set];
    NSMutableSet *normalLogs = [NSMutableSet set];
    
    UserMedicalLog *eggRetrieval, *embryoTransfer, *eggRetrievalNumber, *embryoTransferNumber;
    for (UserMedicalLog *each in logs) {
        if ([each.dataKey hasPrefix:kMedicationItemKeyPrefix] && each.dataValue.integerValue == BinaryValueTypeYes) {
            [medicationLogs addObject:each];
        }
        else if ([each.dataKey isEqualToString:kMedItemEggRetrieval]) {
            eggRetrieval = each;
        }
        else if ([each.dataKey isEqualToString:kMedItemEggRetrievalNumber]) {
            eggRetrievalNumber = each;
        }
        else if ([each.dataKey isEqualToString:kMedItemEmbryosTransfer]) {
            embryoTransfer = each;
        }
        else if ([each.dataKey isEqualToString:kMedItemEmbryosTransferNumber]) {
            embryoTransferNumber = each;
        }
        else {
            [normalLogs addObject:each];
        }
    }
    
    if (eggRetrievalNumber.dataValue.integerValue > 0) {
        [normalLogs addObject:eggRetrievalNumber];
    }
    else if (eggRetrieval.dataValue.integerValue == BinaryValueTypeYes) {
        [normalLogs addObject:eggRetrieval];
    }
    
    if (embryoTransferNumber.dataValue.integerValue > 0) {
        [normalLogs addObject:embryoTransferNumber];
    }
    else if (embryoTransfer.dataValue.integerValue == BinaryValueTypeYes) {
        [normalLogs addObject:embryoTransfer];
    }
    
    // setup subviews
    [self.summaryView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSMutableArray *views = [NSMutableArray array];
    NSArray *sortedLogs = [normalLogs sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dataKey" ascending:YES]]];
    
    for (UserMedicalLog *each in sortedLogs) {
        MedicalLogSummaryView *view = [[MedicalLogSummaryView alloc] initWithMedicalLog:each];
        if (view) {
            [views addObject:view];
        }
    }
    
    if (medicationLogs.count > 0) {
        [views addObject:[[MedicalLogSummaryView alloc] initWithMedicationLogs:[medicationLogs allObjects]]];
    }
    
    if (views.count > 0) {
        hasPositiveData = YES;
        [self addSummarySeparatorView];
    }
    
    // add subviews to container
    CGFloat offsetY = 10;
    for (MedicalLogSummaryView *view in views) {
        view.top = offsetY;
        offsetY += view.height;
        
        [self.summaryView addSubview:view];
    }

    if (offsetY > 10) {
        self.summaryView.height = offsetY + 10;
        [self addViewToContainer:self.summaryView];
    }
    return hasPositiveData;
}


#pragma mark - actions
- (IBAction)appointmentButtonClicked:(id)sender
{
    [Logging log:BTN_CLK_HOME_ADD_NEW_APPOINTMENT];
    [self goToAlertPage];
}


- (IBAction)medicalLogButtonClicked:(id)sender
{
    if ([User currentUser].isSecondaryOrSingleMale) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(tableViewCell:needsPerformSegue:)]) {
        [self.delegate tableViewCell:self needsPerformSegue:@"MedicalLogSegueIdentifier"];
    }
}

- (void)goToAlertPage
{
    if ([self.delegate respondsToSelector:@selector(tableViewCell:needsPerformSegue:)]) {
        [self.delegate tableViewCell:self needsPerformSegue:@"appointments"];
    }
}

@end







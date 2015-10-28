//
//  AppPurposesManager.m
//  emma
//
//  Created by Xin Zhao on 13-12-11.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "AppPurposesManager.h"
#import "Settings.h"
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "UIStoryboard+Emma.h"
#import "MakeUpOnboardingInfoViewController.h"
#import "StatusBarOverlay.h"
#import "OnboardingPeriodEditorViewController.h"
#import "StepsNavigationItem.h"
#import "TabbarController.h"
#import "DailyLogConstants.h"
#import "ForumTopicsViewController.h"
#import "PregnantViewController.h"
#import "PregnantViewController.h"
#import "PregnantAppDlgViewController.h"
#import "PushablePresenteeNavigationController.h"
#import "MeViewController.h"
#import "CurrentStatusTableViewController.h"
#import "HealthProfileData.h"
#import "UserStatusDataManager.h"
#import "UserStatus.h"
#import "User+Prediction.h"
#import "Period.h"

@interface AppPurposesManager () <FirstPeriodSelectorDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) UserStatusDataManager *statusManager;
@end

@implementation AppPurposesManager


- (instancetype)initWithViewController:(UIViewController *)viewController user:(User *)user
{
    self = [self init];
    if (self) {
        self.viewController = viewController;
        self.user = user;
        self.promoPregnancyApp = NO;
        self.statusManager = [UserStatusDataManager sharedInstance];
        
        [self subscribe:EVENT_SWITCHING_PURPOSE_INFO_MADE_UP selector:@selector(saveAfterSwitchingPurpose:)];
        
        [self subscribe:PREGNANT_VIEW_CONTROLLER_DISMISSED selector:@selector(onPregnantViewControllerDismissed:)];
        [self subscribe:EVENT_SWITCH_PREGNANT_CANCELLED selector:@selector(onCancelFromPregnantView)];
        [self subscribe:EVENT_SWITCH_PREGNANT_CONFIRMED selector:@selector(onConfirmFromPregnantView)];
    }
    return self;
}


- (NSString *)descriptionForCurrentStatus
{
    AppPurposes status = self.user.settings.currentStatus;

    if (status == AppPurposesAvoidPregnant || status == AppPurposesNormalTrack) {
        return self.user.partner ? @"We're avoiding pregnancy" : @"Avoiding pregnancy";
    }
    else if (status == AppPurposesTTC) {
        return self.user.partner ? @"We're trying to conceive" : @"I'm trying to conceive";
    }
    else if (status == AppPurposesTTCWithTreatment) {
        return @"Fertility treatment";
    }
    else if (status == AppPurposesAlreadyPregnant) {
        return self.user.partner ? @"We're pregnant!" : @"I'm pregnant!";
    }
    else {
        return @"";
    }
}


- (void)switchingToPurpose:(AppPurposes)purpose
{
    if (purpose == AppPurposesAlreadyPregnant) {
        [self switchingToPregnant];
        return;
    }
    
    NSArray *missedSettings = [self missedSettingsForPurpose:purpose];
    
    if (missedSettings) {
        MakeUpOnboardingInfoViewController *vc = (MakeUpOnboardingInfoViewController*)[UIStoryboard makeUpOnboardingInfo];
        vc.targetAppPurpose = purpose;
        vc.missedSettings = missedSettings;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.viewController.navigationController presentViewController:nav animated:YES completion:nil];
    }
    else {
        Event *event = [[Event alloc] initWithName:nil obj:nil data:@{@"target":@(purpose)}];
        [self saveAfterSwitchingPurpose:event];
    }
}


- (void)switchingToPregnant
{
    if (self.user.currentPurpose == AppPurposesAvoidPregnant) {
        [UIAlertView bk_showAlertViewWithTitle:@""
                                       message:@"Would you like to change your status to **I'm Pregnant**?"
                             cancelButtonTitle:@"No, thanks"
                             otherButtonTitles:@[@"Yes, please"]
                                       handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                                           if (buttonIndex != alertView.cancelButtonIndex) {
                                               [self onConfirmFromPregnantView];
                                               if ([self.viewController isKindOfClass:[CurrentStatusTableViewController class]]) {
                                                   [(CurrentStatusTableViewController *)self.viewController updateUserStatus];
                                               }
                                           }
                                       }];
    }
    else {
        UIViewController *congratsVC = [UIStoryboard congrats];
        [self.viewController.navigationController presentViewController:congratsVC animated:YES completion:^{
            [self.viewController.navigationController popToRootViewControllerAnimated:NO];
        }];
    }
}


- (NSArray *)missedSettingsForPurpose:(AppPurposes)purpose
{
    if (purpose == self.user.currentPurpose) {
        return nil;
    }
    NSMutableArray *missedSettings = [NSMutableArray array];
    Settings *settings = self.user.settings;
    switch (purpose) {
        case AppPurposesTTC: {
            if (!settings.ttcStart || [settings.ttcStart toDateIndex] < -3650) {
                [missedSettings addObject:SETTINGS_KEY_TTC_START];
            }
            if (!settings.childrenNumber || settings.childrenNumber <= 0) {
                [missedSettings addObject:SETTINGS_KEY_CHILDREN_NUMBER];
            }
        }
            break;
        case AppPurposesNormalTrack:
            break;
        case AppPurposesAvoidPregnant: {
            /*
            if (!settings.timePlanedConceive) {
                [missedSettings addObject:SETTINGS_KEY_TIME_PLANED_CONCEIVE];
            }
            */
            if (!settings.birthControl) {
                [missedSettings addObject:SETTINGS_KEY_BIRTH_CONTROL];
            }
        }
            break;
        case AppPurposesTTCWithTreatment: {
            if (!settings.ttcStart || [settings.ttcStart toDateIndex] < -3650) {
                [missedSettings addObject:SETTINGS_KEY_TTC_START];
            }
            if (!settings.childrenNumber || settings.childrenNumber <= 0) {
                [missedSettings addObject:SETTINGS_KEY_CHILDREN_NUMBER];
            }
            [missedSettings addObject:SETTINGS_KEY_TREATMENT_TYPE];
            [missedSettings addObject:SETTINGS_KEY_TREATMENT_STARTDATE];
            // [missedSettings addObject:SETTINGS_KEY_SAME_SEX_COUPLE];
        }
            break;
        default:
            break;
    }
    if (settings.weight < 10.0f) {
        [missedSettings addObject:SETTINGS_KEY_WEIGHT];
    }
    if (settings.height < 100.0f) {
        [missedSettings addObject:SETTINGS_KEY_HEIGHT];
    }
    return [missedSettings count] > 0 ? missedSettings : nil;
}


#pragma mark- Markup Info view Controller Notification
- (void)saveAfterSwitchingPurpose:(Event*)evt
{
    [self showStatusBarSwitchingPurpose];
    
    NSDictionary *switchResult = (NSDictionary*)evt.data;
    
    AppPurposes prevPurpose = self.user.settings.currentStatus;
    AppPurposes purpose = [switchResult[@"target"] intValue];
    [self.user.settings update:@"previousStatus" value:@(prevPurpose)];
    [self.user.settings update:@"currentStatus" value:@(purpose)];
    
    NSMutableDictionary *settings = [switchResult[@"settings"] mutableCopy];
    NSArray *settingAttrs = [Settings attrMapper].allValues;
    for (NSString *attrName in settings) {
        if ([settingAttrs indexOfObject:attrName] != NSNotFound) {
            [self.user.settings update:attrName value:settings[attrName]];
        }
    }
    
    for (NSString *each in [FertilityTest allTestKeys]) {
        NSNumber *answer = [settings objectForKey:each];
        if (!answer) {
            continue;
        }
        
        if (!self.user.fertilityTest) {
            FertilityTest *test = [FertilityTest newInstance:self.user.dataStore];
            test.user = self.user;
        }
        [self.user.fertilityTest update:each value:answer];
    }
    
    BOOL preHasPeriod = YES;
    if ((prevPurpose == AppPurposesAlreadyPregnant) || (prevPurpose == AppPurposesTTCWithTreatment)){
        preHasPeriod = NO;
    }
    BOOL curNeedPeriod = YES;
    NSInteger treatmentType = self.user.settings.fertilityTreatment;
    if (purpose == AppPurposesAlreadyPregnant) {
        curNeedPeriod = NO;
    } else if ((purpose == AppPurposesTTCWithTreatment) &&
               (treatmentType == FertilityTreatmentTypeIUI ||
                treatmentType == FertilityTreatmentTypeIVF)) {
                   curNeedPeriod = NO;
               }
    
//    if ((prevPurpose == AppPurposesAlreadyPregnant) && (!preHasPeriod && curNeedPeriod)) {
//        [self.user archivePeriodDailyData];
//    }
    
    if (prevPurpose == AppPurposesAlreadyPregnant) {
        NSString *pregnantDate = self.user.settings.lastPregnantDate;
        if (pregnantDate && ![pregnantDate isEqualToString:@""]) {
            [self.statusManager createStatusHistory:[UserStatus instanceWithStatus:STATUS_PREGNANT treatmentType:TREATMENT_TYPE_INTERVAL startDate:[Utils dateWithDateLabel:pregnantDate] endDate:[NSDate date]] forUser:self.user];
        }
    }
    
    // save status history
    if (purpose == AppPurposesTTCWithTreatment) {
        NSDate *startDate = [Utils dateWithDateLabel:self.user.settings.treatmentStartdate];
        NSDate *endDate = [Utils dateWithDateLabel:self.user.settings.treatmentEnddate];
        [self.statusManager createStatusHistory:[UserStatus instanceWithStatus:STATUS_TREATMENT treatmentType:treatmentType startDate:startDate endDate:endDate] forUser:self.user];
    } else {
        [self.statusManager cutAndRemoveAllFutureStatusHistory];
    }
    
    [self.user save];
    // Push is not enough, we need a sync
    // [self.user pushToServer];
    [self.user syncWithServer];
    [self publish:EVENT_USER_SETTINGS_UPDATED];
    
    // turn on reminders
    [Reminder updateByPurposeChanged];
    
    [self showStatusBarStatusUpdated];
 
    // open period select page
    if (self.user.isFemale && !preHasPeriod && curNeedPeriod) {
        [self presentFirstPeriodViewController];
    } else {
        // recalculate prediction for IUI and IVF
        if ((treatmentType == FertilityTreatmentTypeIUI) ||
            (treatmentType == FertilityTreatmentTypeIVF)) {
            [self publish:EVENT_NEW_RULES_PULLED];
        }
    }
    [self publish:EVENT_PURPOSE_CHANGED data:@(purpose)];
}


#pragma mark - Congrats/Pregnant View Controller Notifications
- (void)onCancelFromPregnantView
{
}


- (void)onConfirmFromPregnantView
{
    NSString *today = [[NSDate date] toDateLabel];
    
    [self.user.settings update:@"previousStatus" value:@(self.user.settings.currentStatus)];
    [self.user.settings update:@"currentStatus" value:@(AppPurposesAlreadyPregnant)];
    [self.user.settings update:@"lastPregnantDate" value:today];
    
    [self.statusManager cutAndRemoveAllFutureStatusHistory];
    [self.user turnOffPrediction];
    [self publish:EVENT_NEW_RULES_PULLED];
}


- (void)onPregnantViewControllerDismissed:(Event *)e
{
    BOOL shared = [(id)e.data boolValue];
    if (self.user.ovationStatus == OVATION_STATUS_UNDER_FUND || self.user.ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to stop contributing to Glow First?"
                                                                 delegate:self
                                                        cancelButtonTitle:@"No, don't stop"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Yes, please stop", nil];
        [actionSheet showInView:self.viewController.view.window];
    }
    else {
        [self nonGFFlow:shared];
    }
}


- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [Logging log:BTN_CLK_PREGNANT_STOP_CONTRIBUTION_NO];
        [self nonGFFlow:NO];
    }
    else {
        [Logging log:BTN_CLK_PREGNANT_STOP_CONTRIBUTION_YES];
        
        [[GlowFirst sharedInstance] userPregnant];
        
        MeViewController *meViewController = (MeViewController *)self.viewController.navigationController.viewControllers[0];
        [[TabbarController getInstance:meViewController] rePerformFundSegue];
        [Utils performInMainQueueAfter:1 callback:^{
            [[TabbarController getInstance:meViewController] selectFundPage];
        }];
    }
}


- (void)nonGFFlow:(BOOL)shared
{
    if (shared) {
        self.promoPregnancyApp = YES;
        [self presentSuccessStoriesForum];
    }
    else {
        [self openPromoPregnancyApp];
    }
}


- (void)presentSuccessStoriesForum
{
    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:@{@"id": @72057594037927937, @"name": @"group", @"category_id":@3}];
    ForumCategory *cat = [Forum categoryFromGroup:group];
    ForumTopicsViewController *vc = [ForumTopicsViewController viewController];
    vc.showGroupInfo = YES;
    vc.category = cat;
    vc.group = group;

    GLNavigationController *nav = [[GLNavigationController alloc]
                                   initWithRootViewController:vc];
    nav.navigationBar.translucent = NO;
    [self.viewController.navigationController presentViewController:nav animated:YES completion:nil];
}


- (void)openPromoPregnancyApp
{
    self.promoPregnancyApp = NO;
    PregnantAppDlgViewController * dlg = [[PregnantAppDlgViewController alloc] initWithNibName:@"PregnantAppDlgViewController" bundle:nil];
    [dlg present];
}


#pragma mark - First Period View Controller
- (void)presentFirstPeriodViewController
{
    OnboardingPeriodEditorViewController *vc = [OnboardingPeriodEditorViewController instance];
    vc.showCancelButton = NO;
    [vc setTipText:@"Choose a new period cycle before we can switch status for you."];
    vc.delegate = self;
    vc.title = @"New period cycle";
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [Logging log:BTN_CLK_ONBOARDING_PERIOD];
    [self.viewController.navigationController presentViewController:nav animated:YES completion:nil];
}


- (void)firstPeriodSelector:(OnboardingPeriodEditorViewController *)firstPeriodSelector didDismissWithPeriod:(NSDictionary *)firstPeriod
{
    if (firstPeriod) {
        NSDate *begin = firstPeriod[@"begin"];
        NSDate *end = [Utils dateByAddingDays:1 toDate:firstPeriod[@"end"]];
        NSDictionary *period = @{
                                 @"pb": [begin toDateLabel],
                                 @"pe": [end toDateLabel],
                                 @"flag": @(FLAG_SOURCE_USER_INPUT | 1 << FLAG_ADDED_BIT)
                                 };
        [self.user turnOnPredictionWithLatestPeriod:period];
    }
    [self publish:EVENT_NEW_RULES_PULLED];
}


#pragma mark - Status Bar actions
- (void)showStatusBarSwitchingPurpose
{
    [[StatusBarOverlay sharedInstance] postMessage:@"Magic and science at work..."
                                           options:StatusBarShowSpinner | StatusBarShowProgressBar
                                          duration:3.0f];
    
    [[StatusBarOverlay sharedInstance] setProgress:0 animated:NO];
    [[StatusBarOverlay sharedInstance] setProgress:0.7 animated:YES duration:0.5];
    
    [Utils performInMainQueueAfter:0.5 callback:^{
        [[StatusBarOverlay sharedInstance] setProgress:0.8 animated:YES duration:1.25];
    }];
}


- (void)showStatusBarStatusUpdated
{
    [Utils performInMainQueueAfter:0.75 callback:^{
        [[StatusBarOverlay sharedInstance] postMessage:@"Status updated!"
                                               options:StatusBarShowProgressBar
                                              duration:0.3];
        [[StatusBarOverlay sharedInstance] setProgress:1.0 animated:YES duration:0.25];
    }];
}



@end








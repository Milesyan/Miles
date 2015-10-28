//
//  CurrentStatusTableViewController.m
//  emma
//
//  Created by Peng Gu on 10/9/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "CurrentStatusTableViewController.h"
#import "User.h"
#import "PregnantViewController.h"
#import "AppPurposesManager.h"
#import "Logging.h"
#import "WebViewController.h"
#import "StatusBarOverlay.h"
#import "StepsNavigationItem.h"
#import "PillButton.h"

@interface CurrentStatusTableViewController ()

@property (nonatomic, weak) IBOutlet PillButton *nonttcButton;
@property (nonatomic, weak) IBOutlet PillButton *ttcButton;
@property (nonatomic, weak) IBOutlet PillButton *ttcftButton;
@property (nonatomic, weak) IBOutlet PillButton *pregnantButton;

@end


@implementation CurrentStatusTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateUserStatus];
    self.appPurposeManager.viewController = self;
    [Logging log:PAGE_IMP_ME_STATUS_CHANGE];

}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_CURRENT_STATUS];
}


- (void)updateUserStatus
{
    AppPurposes status = self.user.settings.currentStatus;
    self.nonttcButton.selected = (status == AppPurposesAvoidPregnant || status == AppPurposesNormalTrack) ? YES : NO;
    self.ttcButton.selected = (status == AppPurposesTTC) ? YES : NO;
    self.ttcftButton.selected = (status == AppPurposesTTCWithTreatment) ? YES : NO;
    self.pregnantButton.selected = (status == AppPurposesAlreadyPregnant) ? YES : NO;
}


- (IBAction)buttonClicked:(PillButton *)button
{
    int currentStatus = self.user.settings.currentStatus;
    if (button.tag == 0) {
        if (currentStatus == AppPurposesAvoidPregnant) {
            button.selected = YES;
            return;
        }
        int16_t ovation = self.user.ovationStatus;
        if (ovation != OVATION_STATUS_NONE && ovation != OVATION_STATUS_DEMO) {
            //Under fund or in the middle of.
            [[[UIAlertView alloc] initWithTitle:@"Can not change status"
                                        message:@"You are currently under Glow First or in the middle of application."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
            return;
        }
        else {
            [Logging log:BTN_CLK_ME_STATUS_NONE_TTC];
            [self.appPurposeManager switchingToPurpose:AppPurposesAvoidPregnant];
        }
    }
    else if (button.tag == 1) {
        if (currentStatus == AppPurposesTTC) {
            button.selected = YES;
            return;
        }
        [Logging log:BTN_CLK_ME_STATUS_TTC];
        [self.appPurposeManager switchingToPurpose:AppPurposesTTC];
    }
    else if (button.tag == 2) {
        if (currentStatus == AppPurposesTTCWithTreatment) {
            button.selected = YES;
            return;
        }
        [Logging log:BTN_CLK_ME_STATUS_TTC_TREATMENT];
        [self.appPurposeManager switchingToPurpose:AppPurposesTTCWithTreatment];
    }
    else if (button.tag == 3) {
        if (currentStatus == AppPurposesAlreadyPregnant) {
            button.selected = YES;
            return;
        } else {
            button.selected = NO;
        }
        [Logging log:BTN_CLK_ME_STATUS_PREGNANT];
        [self.appPurposeManager switchingToPurpose:AppPurposesAlreadyPregnant];
    }
}

@end

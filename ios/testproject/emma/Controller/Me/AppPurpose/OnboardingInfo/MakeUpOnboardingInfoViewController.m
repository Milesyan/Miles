//
//  MakeUpOnboardingInfoViewController.m
//  emma
//
//  Created by Xin Zhao on 13-12-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//
#import "Logging.h"
#import "MakeUpOnboardingInfoViewController.h"
#import "User.h"
#import "VariousPurposesDataProviderFactory.h"
#import "OnboardingDataProviderTreatment.h"

@interface MakeUpOnboardingInfoViewController () {
    User *user;
}

@end

@implementation MakeUpOnboardingInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated
{
    user = [User currentUser];
//    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [Logging log:PAGE_IMP_MAKEUP_INFO];
    [CrashReport leaveBreadcrumb:@"MakeUpOnboardingInfoViewController"];
    [self _checkDoneButtonStatusWithShowingMessage:NO];
}

- (void)logPageImpression {
    switch (self.targetAppPurpose) {
        case AppPurposesTTC:
            [Logging log:PAGE_IMP_MISS_INFO_TTC];
            break;
        case AppPurposesTTCWithTreatment:
            [Logging log:PAGE_IMP_MISS_INFO_TTC_TREATMENT];
            break;
        case AppPurposesAvoidPregnant:
            [Logging log:PAGE_IMP_MISS_INFO_NO_TTC];
            break;
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_prepareData {
    self.data = [NSMutableDictionary dictionary];
}

- (void)_setDataProvider{
    self.variousPurposesDataProvider =
            [VariousPurposesDataProviderFactory
            generateMakeUpDataProviderWithReceiver:self
            storedAnser:self.data presenter:self
            targetPurpose:self.targetAppPurpose];
    
    User *_user = [User currentUser];
    if ([self.variousPurposesDataProvider containsKey:SETTINGS_KEY_WEIGHT]) {
        if (_user.settings.weight > 0) {
            self.variousPurposesDataProvider.storedAnswer[SETTINGS_KEY_WEIGHT] =
                @(_user.settings.weight);
        }
        if (_user.settings.height > 0) {
            self.variousPurposesDataProvider.storedAnswer[SETTINGS_KEY_HEIGHT] =
                @(_user.settings.height);
        }
    }
}

- (void)onDataUpdatedIndexPath:(NSIndexPath *)indexPath {
    [super onDataUpdatedIndexPath:indexPath];
    self.data = self.variousPurposesDataProvider.storedAnswer;
}

- (IBAction)backButtonClicked:(id)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)doneButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        NSDictionary *data = @{@"settings":self.data, @"target":@(self.targetAppPurpose)};
        [self publish:EVENT_SWITCHING_PURPOSE_INFO_MADE_UP data:data];
    }];
}


@end





//
//  AppGalleryTableViewController.m
//  emma
//
//  Created by Peng Gu on 10/9/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "AppGalleryTableViewController.h"
#import "User+MyFitnessPal.h"
#import "User+Jawbone.h"
#import "User+Fitbit.h"
#import "User+Misfit.h"
#import "HealthKitManager.h"
#import "GLDialogViewController.h"

#pragma mark - Connect Cell
@interface ConnectCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) IBOutlet UIImageView *icon;
@property (strong, nonatomic) IBOutlet UISwitch *conSwitch;

@end

@implementation ConnectCell

@end


#pragma mark - App Gallery View Controller
@interface AppGalleryTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *healthKitSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fbConnectSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *mfpConnectSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *jawboneConnectSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *fitbitConnectSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *misfitConnectSwitch;

@property (assign, nonatomic) BOOL connectingFacebook;
@property (assign, nonatomic) BOOL connectingMfp;
@property (assign, nonatomic) BOOL connectingJawbone;
@property (assign, nonatomic) BOOL connectingFitbit;
@property (assign, nonatomic) BOOL connectingMisfit;

@end


@implementation AppGalleryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self subscribe:EVENT_USER_ADD_FACEBOOK_FAILED selector:@selector(addFacebookFailed:)];
    [self subscribe:EVENT_FB_CONNECT_FAILED selector:@selector(addFacebookFailed:)];
    [self subscribe:EVENT_USER_DISCONNECT_FACEBOOK_FAILED selector:@selector(disconnectFacebookFailed:)];
    [self subscribe:EVENT_USER_ADD_FACEBOOK_RETURNED selector:@selector(addFacebookReturned)];
    
    [self subscribe:EVENT_MFP_CONNECT_FAILED selector:@selector(addMfpFailed:)];
    [self subscribe:EVENT_USER_ADD_MFP_FAILED selector:@selector(addMfpFailed:)];
    [self subscribe:EVENT_USER_DISCONNECT_MFP_FAILED selector:@selector(disconnectMfpFailed:)];
    [self subscribe:EVENT_USER_ADD_MFP_RETURNED selector:@selector(addMfpReturned)];
    
    [self subscribe:EVENT_JAWBONE_CONNECT_FAILED selector:@selector(connectJawboneFailed:)];
    [self subscribe:EVENT_USER_ADD_JAWBONE_FAILED selector:@selector(connectJawboneFailed:)];
    [self subscribe:EVENT_USER_DISCONNECT_JAWBONE_FAILED selector:@selector(disconnectJawboneFailed:)];
    [self subscribe:EVENT_USER_ADD_JAWBONE_RETURNED selector:@selector(connectJawboneReturned)];
    
    [self subscribe:EVENT_FITBIT_CONNECT_FAILED selector:@selector(connectFitbitFailed:)];
    [self subscribe:EVENT_USER_ADD_FITBIT_FAILED selector:@selector(connectFitbitFailed:)];
    [self subscribe:EVENT_USER_DISCONNECT_FITBIT_FAILED selector:@selector(disconnectFitbitFailed:)];
    [self subscribe:EVENT_USER_ADD_FITBIT_RETURNED selector:@selector(connectFitbitReturned)];
    
    [self subscribe:EVENT_USER_ADD_MISFIT_FAILED selector:
        @selector(connectMisfitFailed:)];
    [self subscribe:EVENT_USER_DISCONNECT_FITBIT_FAILED selector:
        @selector(disconnectFitbitFailed:)];
    [self subscribe:EVENT_USER_ADD_MISFIT_RETURNED selector:
        @selector(connectMisfitReturned)];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.healthKitSwitch.on = [HealthKitManager connected];
    self.fbConnectSwitch.on = self.connectingFacebook ? YES : self.user.isFacebookConnected;
    self.mfpConnectSwitch.on = self.connectingMfp ? YES : self.user.isMFPConnected;
    self.jawboneConnectSwitch.on = self.connectingJawbone ? YES: self.user.isJawboneConnected;
    self.fitbitConnectSwitch.on = self.connectingFitbit? YES: self.user.isFitbitConnected;
    self.misfitConnectSwitch.on = self.connectingMisfit? YES : [self.user isConnectedWithMisfit];
    
    if (!self.mfpConnectSwitch.on) {
        // fix for mfp connection, but we need to dig into why the alias data isn't created on server
        NSString *accessToken = [Utils getDefaultsForKey:MFP_ACCESS_TOKEN];
        NSString *refreshToken = [Utils getDefaultsForKey:MFP_REFRESH_TOKEN];
        if (accessToken && refreshToken) {
            self.mfpConnectSwitch.on = YES;
        }
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_APP_GALLERY];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Fitbit
- (IBAction)toggleFitbit:(id)sender {
    int switchOn = 0;
    if (self.fitbitConnectSwitch.on) {
        switchOn = 1;
        [self.user connectFitbitForUser];
        self.connectingFitbit = YES;
    } else {
        [self.user disconnectFitbitForUser];
    }
    
    [Logging log:BTN_CLK_ME_FITBIT_CONNECT eventData:@{@"switch_on": @(switchOn)}];
    
}

- (void)connectFitbitReturned {
    self.connectingFitbit = NO;
    [self.user doInitalCalorieAndNutritionSync];
}

- (void)connectFitbitFailed:(Event *)event {
    self.fitbitConnectSwitch.on = NO;
    self.connectingFitbit = NO;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)disconnectFitbitFailed:(Event *)event {
    self.fitbitConnectSwitch.on = YES;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - Jawbone
- (IBAction)toggleJawbone:(id)sender {
    int switchOn = 0;
    if (self.jawboneConnectSwitch.on) {
        switchOn = 1;
        [self.user connectJawboneForUser];
        self.connectingJawbone = YES;
    } else {
        [self.user disconnectJawboneForUser];
    }
    
    [Logging log:BTN_CLK_ME_JAWBONE_CONNECT eventData:@{@"switch_on": @(switchOn)}];
    
}

- (void)connectJawboneReturned {
    self.connectingJawbone = NO;
    [self.user doInitalCalorieAndNutritionSync];
}

- (void)connectJawboneFailed:(Event *)event {
    self.jawboneConnectSwitch.on = NO;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)disconnectJawboneFailed:(Event *)event {
    self.jawboneConnectSwitch.on = YES;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

#pragma mark - MFP

- (IBAction)toggleMyFitnessPalConnect {
    int switchOn = 0;
    if (self.mfpConnectSwitch.on) {
        switchOn = 1;
        self.connectingMfp = YES;
        [self.user addMFPConnectForUser];
    } else {
        [self.user disconnectForUser];
    }
    [Logging log:BTN_CLK_ME_MFP_CONNECT eventData:@{@"switch_on": @(switchOn)}];
}

- (void)addMfpReturned
{
    self.connectingMfp = NO;
    [self.user doInitalCalorieAndNutritionSync];
}

- (void)addMfpFailed:(Event *)evt {
    self.connectingMfp = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.mfpConnectSwitch.on = NO;
    });
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:(NSString*)evt.data
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)disconnectMfpFailed:(Event *)evt {
    self.mfpConnectSwitch.on = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:(NSString*)evt.data
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - FBConnect
- (IBAction)toggleFacebookConnect {
    int switchOn = 0;
    if (self.fbConnectSwitch.on) {
        switchOn = 1;
        self.connectingFacebook = YES;
        [self.user addFacebook];
    } else {
        [self.user disconnectFacebook];
    }
    [Logging log:BTN_CLK_ME_FB_CONNECT eventData:@{@"switch_on": @(switchOn)}];
}

- (void)addFacebookReturned
{
    self.connectingFacebook = NO;
}

- (void)addFacebookFailed:(Event *)evt {
    self.fbConnectSwitch.on = NO;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:(NSString*)evt.data
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)userCanceled {
    self.fbConnectSwitch.on = NO;
}

- (void)disconnectFacebookFailed:(Event *)evt {
    self.fbConnectSwitch.on = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                    message:(NSString*)evt.data
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - Misfit
- (IBAction)toggleMisfit:(id)sender {
    int switchOn = 0;
    if (self.misfitConnectSwitch.on) {
        switchOn = 1;
        [User misfitAuthForConnect];
        self.connectingMisfit = YES;
    } else {
        [self.user disconnectMisfit];
    }

    [Logging log:BTN_CLK_ME_MISFIT_CONNECT eventData:@{@"switch_on": @(switchOn)}];
}

- (void)connectMisfitReturned {
    self.connectingMisfit = NO;
    [self.user doInitalCalorieAndNutritionSync];
}

- (void)connectMisfitFailed:(Event *)event {
    self.misfitConnectSwitch.on = NO;
    self.connectingMisfit = NO;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}

- (void)disconnectMisfitFailed:(Event *)event {
    self.misfitConnectSwitch.on = YES;
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:(NSString*)event.data
                               delegate:self
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
}


#pragma mark - health kit
- (IBAction)toggleHealthKit:(id)sender
{
    if (self.healthKitSwitch.on) {
        [[HealthKitManager sharedInstance] connect];
    }
    else {
        [[HealthKitManager sharedInstance] disconnect];
    }
    [Logging log:BTN_CLK_ME_HEALTHKIT_CONNECT eventData:@{@"switch_on": @(self.healthKitSwitch.on)}];
}


- (IBAction)presentHealthKitInfoDialog:(id)sender
{
    UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"health"];
    vc.view.frame = CGRectMake(0, 0, 280, 300);
    [[GLDialogViewController sharedInstance] presentWithContentController:vc];
}



#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [HealthKitManager haveHealthKit] ? 6 : 5;
}




@end

//
//  ScanViewController.m
//  emma
//
//  Created by Eric Xu on 1/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define ACCOUNT_SECTION 0
#define PARTNER_SECTION 1
#define PREFERENCE_SECTION 2
#define PERIOD_SECTION 3
#define SECURITY_SECTION 4
#define CREDITCARD_SECTION 5
#define LOGOUT_SECTION 6

#define TAG_PROFILE_IMAGE       101
#define TAG_NAME_EMAIL          102
#define TAG_BIRTHDAY            103
#define TAG_GENDER              104
#define TAG_HEIGHT              106
#define TAG_EXERCISE            107
#define TAG_BACKGROUND          105
#define TAG_PUSH_NOTIFICATION   108
#define TAG_BIRTH_CONTROL       109
#define TAG_PERIOD_LENGTH       201
#define TAG_PERIOD_CYCLE        202
#define TAG_PARTNER_CONNECT     301
#define TAG_PARTNER_DISCONNECT  302
#define TAG_CODE                401
#define TAG_CREDITCARD          501
#define TAG_DEBUG_REPORT        601
#define TAG_CLEAR_LOCAL_DATA    602
#define TAG_LOGOUT              603
#define TAG_HEIGHT_UNIT         701
#define TAG_WEIGHT_UNIT         702
#define TAG_TEMPERATURE_UNIT    703

#define TAG_ALERT_CONFIRM_DISCONNECT 10
#define TAG_ALERT_ADD_CREDITCARD 11
#define TAG_ALERT_CONFIRM_LOGOUT 12
#define TAG_ALERT_DEBUG_REPORT      13
#define TAG_ALERT_CONFIRM_CLEAR_LOCAL_DATA 14

#import "CardIOPaymentViewController.h"
#import "Errors.h"
#import "GlowFirst.h"
#import "ImagePicker.h"
#import "InvitePartnerDialog.h"
#import "KKKeychain.h"
#import "KKPasscodeLock.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import <GLFoundation/GLPickerViewController.h>
#import "SettingViewController.h"
#import "StatusBarOverlay.h"
#import "UIImage+Resize.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "UserInfoDialog.h"
#import <QuartzCore/QuartzCore.h>
#import "HealthProfileData.h"
#import "User+Misc.h"
#import <GLFoundation/GLGeneralPicker.h>
#import "DailyLogCellTypeBMI.h"
#import "NetworkLoadingView.h"
#import "DropdownMessageController.h"
#import "OnboardingPeriodEditorViewController.h"
#import "Period.h"
#import "User+Prediction.h"

@interface SettingViewController () <ImagePickerDelegate, CardIOPaymentViewControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate, FirstPeriodSelectorDelegate> {
    BOOL connectingFacebook;
    BOOL connectingMfp;
    NSInteger cellTagWaitingImage;
}

//Account
@property (weak, nonatomic) IBOutlet UIImageView *profilePhoto;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;


@property (strong, nonatomic) IBOutlet UISwitch *pushSwitch;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundThumbnail;


//Partner
@property (weak, nonatomic) IBOutlet UIImageView *partnerPhoto;
@property (weak, nonatomic) IBOutlet UILabel *partnerNameLabel;

//Security
@property (weak, nonatomic) IBOutlet UILabel *changeCodeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *passcodeSwitch;
@property (weak, nonatomic) IBOutlet UITableViewCell *changeCodeCell;

//Credit Card
@property (weak, nonatomic) IBOutlet UILabel *cardNumber;

//Period
@property (weak, nonatomic) IBOutlet UISwitch *predictionSwitch;

@property (nonatomic, retain)User *user; 
- (void)invitePartner;
- (void)disconnectPartner;
- (void)changeCode;
- (void)addCreditCard;
- (void)updateCardInfo;
@end
//
@implementation SettingViewController

- (User *)user {
    return [User currentUser];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

//    self.profilePhoto.frame = CGRectMake(10, 4, 36, 36);
    self.profilePhoto.layer.cornerRadius = 18;
    [self.profilePhoto setImage:[[UIImage imageNamed:@"profile-empty"] resizedImage:CGSizeMake(36, 36) interpolationQuality:kCGInterpolationHigh]];
    self.partnerPhoto.layer.cornerRadius = 18;
    [self.user loadProfileImage:^(UIImage *image, NSError *error) {
        if (!error && image) self.profilePhoto.image = image;
        else self.profilePhoto.image = [UIImage imageNamed:@"profile-empty"];
    }];

    self.backgroundThumbnail.layer.cornerRadius = 5.0;
    self.backgroundThumbnail.image = self.user.settings.backgroundImage;

    [self setKKPasscodeWidgets];
    
    if (self.user.partner) {
        [self setPartnerInfo];
    }
    [self syncCardInfo];

    [self.navigationController.navigationBar setNeedsLayout];
    
    [self updateCardInfo];

    // Subscribe Events
    __weak SettingViewController *_self = self;
    [self subscribe:EVENT_PARTNER_REMOVED handler:^(Event *evt){
        [_self.tableView reloadData];
    }];
    [self subscribe:EVENT_PARTNER_REMOVED_FAILED handler:^(Event *evt){
        NSDictionary * data = (NSDictionary *)evt.data;
        NSString * msg = [data objectForKey:@"msg"];
        [[[UIAlertView alloc] initWithTitle:@""
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }];
    [self subscribe:EVENT_PARTNER_INVITED handler:^(Event *evt){
        [_self.tableView reloadData];
        [_self setPartnerInfo];
    }];
        
    [self subscribe:EVENT_PROFILE_IMAGE_UPDATE handler:^(Event *event){
        _self.profilePhoto.image = _self.user.profileImage;
    }];

    [self subscribe:EVENT_DATA_SAVED handler:^(Event *event){
        [_self refresh];
    }];

    [self subscribe:EVENT_CARDNUMBER_CHANGED selector:@selector(changeCardResponse:)];
    [self subscribe:EVENT_GET_CARD selector:@selector(syncCardResponse:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.tintColor = UIColorFromRGB(0x6c6dd3);

    [self refresh];
    // logging
    [CrashReport leaveBreadcrumb:@"SettingViewController"];
    [Logging log:PAGE_IMP_SETTINGS];
}

- (void)refresh {
    GLLog(@"SettingViewController refresh");
    self.nameLabel.text = self.user.fullName;
    self.emailLabel.text = self.user.email;
    self.pushSwitch.on = self.user.settings.receivePushNotification;
    self.predictionSwitch.on = self.user.settings.predictionSwitch == 1;
    // refresh tableview to update the layout
    [self.tableView reloadData];
}

- (void)didPickedImage:(UIImage *)image {
    if (cellTagWaitingImage == TAG_PROFILE_IMAGE) {
        self.profilePhoto.image = image;
        [self.user updateProfileImage:image];
        [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
    } else if (cellTagWaitingImage == TAG_BACKGROUND) {
        self.backgroundThumbnail.image = image;
        [self.user.settings updateBackgroundImage:image];
    }
}

- (void)imagePickerDidClickDestructiveButton
{
    if (cellTagWaitingImage == TAG_BACKGROUND) {
        [self.user.settings restoreBackgroundImage];
        self.backgroundThumbnail.image = self.user.settings.backgroundImage;
    }
}

#pragma mark - Account Management

- (void)updateNameAndEmail {
    [Logging log:BTN_CLK_SETTINGS_NAME_EMAIL];
    UserInfoDialog *userInfoDialog = [[UserInfoDialog alloc] initWithUser:self.user]; 
    [userInfoDialog present];
}

- (IBAction)pushSwitched:(id)sender {
    [self.user.settings update:@"receivePushNotification" boolValue:self.pushSwitch.on];

    NSInteger switchOn = 0;
    if (self.pushSwitch.on) {
        UIRemoteNotificationType types = [[UIApplication sharedApplication] enabledRemoteNotificationTypes];
        UIRemoteNotificationType typesset = (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge);
        if((types & typesset) != typesset)
        {
            NSString *msg = nil;
            msg = @"Go to Settings -> Notification Center -> Glow to turn on alerts to receive push notification from Glow.";
            [[[UIAlertView alloc] initWithTitle:@"Turn on notification"
                                        message:msg
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        }
        switchOn = 1;
    }
    [Logging log:BTN_CLK_SETTINGS_NOTIFICATION eventData:@{@"switch_on": @(switchOn)}];
    [self save];
}

- (IBAction)predicationSwitched:(id)sender {
    if (self.predictionSwitch.on) {
        [self presentPeriodViewController];
    } else {
        [self.user turnOffPrediction];
    }
    [Logging log:BTN_CLK_SETTINGS_PREDICTION eventData:@{@"switch_on": @(self.predictionSwitch.on)}];
}

#pragma mark - First Period View Controller
- (void)presentPeriodViewController
{
    OnboardingPeriodEditorViewController *vc = [OnboardingPeriodEditorViewController instance];
    vc.showCancelButton = YES;
    [vc setTipText:@"Enter your latest period, so that we can give you updated predictions."];
    vc.delegate = self;
    vc.title = @"New period cycle";
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [Logging log:BTN_CLK_ONBOARDING_PERIOD];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
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
        self.predictionSwitch.on = YES;
    }
}




- (void)logout {
    // log the logout button
    [Logging syncLog:BTN_CLK_SETTINGS_LOGOUT eventData:nil];
    [self.user logout];
    UIViewController *root = [self.tableView window].rootViewController;
    [root dismissViewControllerAnimated:YES completion:nil];
}

- (void)save {
    [self.user pushToServer];
    [[StatusBarOverlay sharedInstance] postMessage:@"Updated!" duration:2.0];
}

#pragma mark - Partner
- (void)disconnectPartner {
    if (!self.user.partner) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"This will disconnect your partner and stop sharing information between your and your partner." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Yes, disconnect", nil];
    alert.tag = TAG_ALERT_CONFIRM_DISCONNECT;
    [alert show];
    
}

- (void)invitePartner {
    if (self.user.partner) {
        return;
    }
    GLLog(@"invite partner!");
    [InvitePartnerDialog openDialog];
}

- (void)setPartnerInfo {
    [self.partnerPhoto setImage:[[UIImage imageNamed:@"profile-empty"] resizedImage:CGSizeMake(36, 36) interpolationQuality:kCGInterpolationHigh]];
    NSString *displayName = [NSString stringWithFormat:@"%@ %@", self.user.partner.firstName, self.user.partner.lastName];
    if ([[Utils trim:displayName] isEqualToString:@""]) {
        displayName = self.user.partner.email;
    }
    [self.partnerNameLabel setText:displayName];
    [self.user.partner loadProfileImage:^(UIImage *image, NSError *error) {
        if (!error && image) self.partnerPhoto.image = image;
        else
            self.partnerPhoto.image = [UIImage imageNamed:@"profile-empty"];
    }];
}

#pragma mark - Security
- (IBAction)togglePasscodeSwitch
{
    BOOL _passcodeLockOn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"passcode_on"] isEqualToString:@"YES"];
    KKPasscodeMode mode = _passcodeLockOn ? KKPasscodeModeDisabled : KKPasscodeModeSet;
    
    [self openKKPasscodeViewWithMode:mode];
        
}

- (void)changeCode{
    [self openKKPasscodeViewWithMode:KKPasscodeModeChange];
}

- (void)didSettingsChanged:(KKPasscodeViewController *)viewController {
    [self setKKPasscodeWidgets];
}

- (void)didCancelled:(KKPasscodeViewController *)viewController {
    [self setKKPasscodeWidgets];
}

- (void)setKKPasscodeWidgets {
    BOOL isPasscodeRequired = [[KKPasscodeLock sharedLock] isPasscodeRequired];
    [_passcodeSwitch setOn:isPasscodeRequired];
    [_changeCodeLabel setEnabled:isPasscodeRequired];
    [_changeCodeCell setUserInteractionEnabled:isPasscodeRequired];
}

- (void)openKKPasscodeViewWithMode:(KKPasscodeMode)mode{
    KKPasscodeViewController* vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
    vc.delegate = self;
    vc.mode = mode;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

    if ([vc respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        [vc setEdgesForExtendedLayout:UIRectEdgeNone];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        nav.navigationBar.barStyle = UIBarStyleBlack;
        nav.navigationBar.opaque = NO;
    } else {
        nav.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        nav.navigationBar.translucent = self.navigationController.navigationBar.translucent;
        nav.navigationBar.opaque = self.navigationController.navigationBar.opaque;
        nav.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
    }
    
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

#pragma mark - Credit Card
- (void)addCreditCard {
    CardIOPaymentViewController *scanViewController = [[CardIOPaymentViewController alloc] initWithPaymentDelegate:self];
//    scanViewController.appToken = CARDIO_TOKEN;
//    scanViewController.showsFirstUseAlert = NO;
    [self presentViewController:scanViewController animated:YES completion:nil];
}

- (void)changeCreditCard {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?" message:@"We will remove your current credit card and replace it with the new one you enter." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Replace now", nil];
    alert.tag = TAG_ALERT_ADD_CREDITCARD;
    [alert show];
}

- (void)updateCardInfo {
    self.cardNumber.text = [[GlowFirst sharedInstance] redactedCardNumber];
}

- (void)syncCardInfo {
    [[GlowFirst sharedInstance] syncCardInfo];
}

- (void)syncCardResponse:(Event *)event {    
    NSDictionary * result = (NSDictionary *)event.data;
    BOOL cardAddOrRemove = [[result objectForKey:@"cardAddOrRemove"] boolValue];
    [self updateCardInfo];
    if (cardAddOrRemove) {
        [self.tableView reloadData];
    }
}

# pragma mark CardIOPaymentViewControllerDelegate

- (void)userDidCancelPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    GLLog(@"User canceled payment info");
    // Handle user cancellation here...
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
}

//TODO: Use the card info here.
- (void)userDidProvideCreditCardInfo:(CardIOCreditCardInfo *)info inPaymentViewController:(CardIOPaymentViewController *)scanViewController {
    // The full card number is available as info.cardNumber, but don't log that!
    [scanViewController dismissViewControllerAnimated:YES completion:nil];
    [NetworkLoadingView show];
    [[GlowFirst sharedInstance] changeCard:info.cardNumber expMonth:info.expiryMonth expYear:info.expiryYear cvc:info.cvv];
}

- (void)changeCardResponse:(Event *)event {
    [NetworkLoadingView hide];
    
    NSDictionary * result = (NSDictionary *)event.data;
    NSInteger rc = [[result objectForKey:@"rc"] integerValue];
    NSError *err = [result objectForKey:@"error"];
    if (!err) {
        if (rc == RC_SUCCESS) {
            [self updateCardInfo];
        } else {
            NSString *errMsg = [result objectForKey:@"errMsg"];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alertView show];
        }
    } else {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to change card." duration:4.0];
    }
}

#pragma mark - TableView Delegate and DataSource
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (cell.tag == TAG_CODE) {
        [Logging log:BTN_CLK_SETTINGS_CODE];
        [self changeCode];
    }
    else if (cell.tag == TAG_PARTNER_CONNECT) {
        [Logging log:BTN_CLK_SETTINGS_INV_PTN];
        [self invitePartner];
    }
    else if (cell.tag == TAG_PARTNER_DISCONNECT) {
        [Logging log:BTN_CLK_SETTINGS_DCONN_PTN];
        [self disconnectPartner];
    }
    else if (cell.tag == TAG_DEBUG_REPORT) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Debug report"
                                                        message:@"Do you want to send a debug report to Glow?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes", nil];
        alert.tag = TAG_ALERT_DEBUG_REPORT;
        [alert show];
    }
    else if (cell.tag == TAG_CLEAR_LOCAL_DATA) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"You are about to clear your local data and fetch your server data. Please proceed with caution."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Clear local data", nil];
        alert.tag = TAG_ALERT_CONFIRM_CLEAR_LOCAL_DATA;
        [alert show];
    }
    else if (cell.tag == TAG_LOGOUT) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                        message:@"You are about to log out."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Yes, log out", nil];
        alert.tag = TAG_ALERT_CONFIRM_LOGOUT;
        [alert show];
    }
    else if (cell.tag == TAG_PROFILE_IMAGE) {
        [Logging log:BTN_CLK_SETTINGS_PROFILE];
        cellTagWaitingImage = cell.tag;
        [[ImagePicker sharedInstance] showInController:self
                                             withTitle:@"Change profile photo"];
    }
    else if (cell.tag == TAG_NAME_EMAIL) {
        [self updateNameAndEmail];
    }
    else if (cell.tag == TAG_BACKGROUND) {
        [Logging log:BTN_CLK_SETTINGS_BACKGROUND];
        cellTagWaitingImage = cell.tag;
        [[ImagePicker sharedInstance] showInController:self
                                             withTitle:@"Change background image"
                                destructiveButtonTitle:@"Restore default"
                                         allowsEditing:NO];
    }
    else if (cell.tag == TAG_CREDITCARD) {
        [Logging log:BTN_CLK_SETTINGS_CREDITCARD];
        [self changeCreditCard];
    }
    else if (cell.tag == TAG_WEIGHT_UNIT) {
        NSInteger selectedRow = 0;
        if ([[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG]) {
            selectedRow = 1;
        } else {
            selectedRow = 0;
        }
        [GLGeneralPicker presentSimplePickerWithTitle:@"Choose your prefered unit" rows:@[@"Imperial", @"Metric"] selectedRow:(int)selectedRow showCancel:NO withAnimation:YES doneCompletion:^(NSInteger row, NSInteger comp) {
            if (row == 0) {
                cell.detailTextLabel.text = @"Imperial";
                [Utils setDefaultsForKey:kUnitForWeight withValue:UNIT_LB];
            } else {
                cell.detailTextLabel.text = @"Metric";
                [Utils setDefaultsForKey:kUnitForWeight withValue:UNIT_KG];
            }
            [self publish:EVENT_DAILY_LOG_UNIT_CHANGED];
        } cancelCompletion:^(NSInteger row, NSInteger comp) {
            
        }];
    }
    else if (cell.tag == TAG_HEIGHT_UNIT) {
        NSInteger selectedRow = 0;
        if ([[Utils getDefaultsForKey:kUnitForHeight] isEqualToString:UNIT_CM]) {
            selectedRow = 1;
        } else {
            selectedRow = 0;
        }
        [GLGeneralPicker presentSimplePickerWithTitle:@"Choose your prefered unit" rows:@[@"Imperial", @"Metric"] selectedRow:(int)selectedRow showCancel:NO withAnimation:YES doneCompletion:^(NSInteger row, NSInteger comp) {
            if (row == 0) {
                cell.detailTextLabel.text = @"Imperial";
                [Utils setDefaultsForKey:kUnitForHeight withValue:UNIT_INCH];
                
            } else {
                cell.detailTextLabel.text = @"Metric";
                [Utils setDefaultsForKey:kUnitForHeight withValue:UNIT_CM];
            }
            [self publish:EVENT_DAILY_LOG_UNIT_CHANGED];
        } cancelCompletion:^(NSInteger row, NSInteger comp) {
            
        }];
    }
    else if (cell.tag == TAG_TEMPERATURE_UNIT) {
        NSInteger selectedRow = 0;
        if ([[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:UNIT_CELCIUS]) {
            selectedRow = 1;
        } else {
            selectedRow = 0;
        }
        [GLGeneralPicker presentSimplePickerWithTitle:@"Choose your prefered unit" rows:@[@"Fahrenheit", @"Celsius"] selectedRow:(int)selectedRow showCancel:NO withAnimation:YES doneCompletion:^(NSInteger row, NSInteger comp) {
            if (row == 0) {
                cell.detailTextLabel.text = @"Fahrenheit";
                [Utils setDefaultsForKey:kUnitForTemp withValue:UNIT_FAHRENHEIT];
                
            } else {
                cell.detailTextLabel.text = @"Celsius";
                [Utils setDefaultsForKey:kUnitForTemp withValue:UNIT_CELCIUS];
            }
            [self publish:EVENT_DAILY_LOG_UNIT_CHANGED];
        } cancelCompletion:^(NSInteger row, NSInteger comp) {
            
        }];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == PARTNER_SECTION && self.user.partner){
        indexPath = [NSIndexPath indexPathForRow:indexPath.row+1 inSection:PARTNER_SECTION];
    }

    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (cell.tag == TAG_WEIGHT_UNIT) {
        if ([[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG]) {
            cell.detailTextLabel.text = @"Metric";
        } else {
            cell.detailTextLabel.text = @"Imperial";
        }
    }
    else if (cell.tag == TAG_HEIGHT_UNIT) {
        if ([[Utils getDefaultsForKey:kUnitForHeight] isEqualToString:UNIT_CM]) {
            cell.detailTextLabel.text = @"Metric";
        } else {
            cell.detailTextLabel.text = @"Imperial";
        }
    }
    else if (cell.tag == TAG_TEMPERATURE_UNIT) {
        if ([[Utils getDefaultsForKey:kUnitForTemp] isEqualToString:UNIT_CELCIUS]) {
            cell.detailTextLabel.text = @"Celsius";
        } else {
            cell.detailTextLabel.text = @"Fahrenheit";
        }
    }
    
    return cell;
}

- (BOOL)hasCreditCardSection {
    return [[GlowFirst sharedInstance] hasCreditCardOnFile];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == PARTNER_SECTION) {
        return self.user.partner ? 2 : 1;
    }
    else if (section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return 0;
    }
    else if (section == PERIOD_SECTION && [self.user isSecondary]) {
        return 0;
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return 0;
    }
    else if (indexPath.section == PERIOD_SECTION && [self.user isSecondary]) {
        return 0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return nil;
    }
    else if (section == PERIOD_SECTION && [self.user isSecondary]) {
        return nil;
    }
    
    return [super tableView:tableView titleForHeaderInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return 0;
    }
    else if (section == PERIOD_SECTION && [self.user isSecondary]) {
        return 0;
    }
    return [super tableView:tableView heightForHeaderInSection:section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return nil;
    }
    else if (section == PERIOD_SECTION && [self.user isSecondary]) {
        return nil;
    }
    return [super tableView:tableView titleForFooterInSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == CREDITCARD_SECTION && ![self hasCreditCardSection]) {
        return 0;
    }
    else if (section == PERIOD_SECTION && [self.user isSecondary]) {
        return 0;
    }
    return [super tableView:tableView heightForFooterInSection:section];
}

# pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        switch (alertView.tag) {
            case TAG_ALERT_ADD_CREDITCARD:
                [self addCreditCard];
                break;
            case TAG_ALERT_CONFIRM_DISCONNECT:
            {
                [self.user removePartner];
            }
                break;
            case TAG_ALERT_CONFIRM_LOGOUT:
            {
                [self logout];
            }
                break;
            case TAG_ALERT_DEBUG_REPORT:
            {
                [self.user sendDebugReportWithShowingNetwork:YES];
            }
                break;
            case TAG_ALERT_CONFIRM_CLEAR_LOCAL_DATA:
            {
                [NetworkLoadingView showWithoutAutoClose];
                [self.user clearLocalData:^(BOOL success, NSString *errMsg) {
                    [NetworkLoadingView hide];
                    if (!success) {
                        NSString *message;
                        if ([Utils isEmptyString:errMsg]) {
                            message = @"Network is currently unavailable";
                        } else {
                            message = errMsg;
                        }
                        [[DropdownMessageController sharedInstance] postMessage:message duration:1.5f inWindow:self.view.window];
                    }
                }];
            }
                break;
            default:
                break;
        }

    }
}


@end

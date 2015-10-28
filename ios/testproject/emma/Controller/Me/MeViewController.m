//
//  MeViewController.m
//  emma
//
//  Created by Eric Xu on 10/23/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AskRateDialog.h"
#import "ExportReportDialog.h"
#import "ImagePicker.h"
#import "InvitePartnerDialog.h"
#import "Logging.h"
#import "MeViewController.h"
#import "UIImage+blur.h"
#import "UIView+Helpers.h"
#import "Utils.h"
#import "WebViewController.h"
#import "ForumProfileViewController.h"
#import "ShareController.h"
#import "AppGalleryTableViewController.h"
#import "SettingViewController.h"
#import "OAuth1_0.h"
#import "MeHeaderView.h"
#import "Sendmail.h"
#import "TabbarController.h"
#import "CurrentStatusTableViewController.h"
#import "ChooseTreatmentViewController.h"
#import "AppPurposesManager.h"
#import "PillButton.h"
#import "HealthProfileDataController.h"
#import "HealthProfileData.h"
#import "User+Misc.h"
#import "GLAppGalleryTableViewController.h"
#import "MedicalRecordsDataManager.h"

#import <GLCommunity/Forum.h>
#import <GLCommunity/ForumEditProfileViewController.h>

#define kAppGallerySegueIdentifier @"AppGallerySegueIdentifier"
#define kSettingsSegueIdentifier @"SettingsSegueIdentifier"
#define kHelpSegueIdentifier @"HelpSegueIdentifier"
#define kCurrentStatusSegueIdentifier @"CurrentStatusSegueIdentifier"
#define kPregnantSegueIdentifier @"PregnantSegueIdentifier"



@implementation PersistentBackgroundLabel
- (void)setPersistentBackgroundColor:(UIColor*)color {
    super.backgroundColor = color;
}

- (void)setBackgroundColor:(UIColor *)color {
    // do nothing - background color never changes
}
@end

#pragma mark - MeViewController
@interface MeViewController () <ImagePickerDelegate>

@property (nonatomic, weak) IBOutlet MeHeaderView *meHeader;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *statusConnectionLines;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *healthProfileCompletionLabelHeight;
@property (nonatomic, weak) IBOutlet PersistentBackgroundLabel *healthProfileComplectionRateLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chooseTreatmentButtonRight;
@property (weak, nonatomic) IBOutlet UIButton *chooseTreatmentButton;
@property (weak, nonatomic) IBOutlet UIButton *pregnantButton;
@property (weak, nonatomic) IBOutlet UIButton *pregnantLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) AppPurposesManager *appPurposeManager;
@property (nonatomic, strong) User* user;

@end 

@implementation MeViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[NSBundle mainBundle] loadNibNamed:@"MeHeader" owner:self options:nil];
    self.meHeader.viewController = self;
    // Header hack for ios 6/7
    
    self.tableView.tableHeaderView = self.meHeader;
    [self.meHeader.backgroundMask setGradientBackground:[UIColor colorWithWhite:0.0 alpha:0.0]
                                                toColor:[UIColor colorWithWhite:0.0 alpha:0.6]];
    
    self.user = [User currentUser];
    
    [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(onLogout:)];
    [self subscribe:EVENT_PROFILE_MODIFIED selector:@selector(onProfileModified:)];
    [self subscribe:EVENT_SHOW_ME_CONNECTION_SECTION selector:@selector(goAppGallery:)];
    
    self.appPurposeManager = [[AppPurposesManager alloc] initWithViewController:self user:self.user];
    [self.tableView registerNib:[UINib nibWithNibName:@"MeStatusCell" bundle:nil] forCellReuseIdentifier:@"MeStatusCell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *title;
    if (self.user.partner) {
        title = [NSString stringWithFormat:@"%@ & %@", self.user.firstName, self.user.partner.firstName];
    }
    else {
        title = self.user.firstName;
    }
    self.navigationItem.title = title;

    [self.tableView reloadData];
    [self.meHeader updateProfileCell];
    self.tableView.tableHeaderView = self.meHeader;
    
    // add motion effects, reset bgimageview position to avoid positioning bug
    [self.meHeader addMotionEffect];
    
    self.appPurposeManager.viewController = self;
    
    NSUInteger rate = (NSUInteger)([HealthProfileDataController completionRate] * 100);
    self.healthProfileComplectionRateLabel.text = [NSString stringWithFormat:@"%ld%%", (unsigned long)rate];
    
    [Logging log:PAGE_IMP_ME eventData:@{@"health_profile_complete_rate": @(rate)}];
    
    PersistentBackgroundLabel *label = self.healthProfileComplectionRateLabel;
    if (rate != 100) {
        label.font = [Utils defaultFont:13];
        [label setPersistentBackgroundColor:[UIColor colorFromWebHexValue:@"DE402D"]];
        label.textColor = [UIColor whiteColor];
        self.healthProfileCompletionLabelHeight.constant = 17;
        label.layer.cornerRadius = 17 / 2;
        label.layer.masksToBounds = YES;
    } else {
        label.font = [Utils defaultFont:16];
        [label setPersistentBackgroundColor:[UIColor clearColor]];
        self.healthProfileCompletionLabelHeight.constant = 26;
        label.textColor = GLOW_COLOR_PURPLE;
        label.layer.cornerRadius = 0;
        label.layer.masksToBounds = YES;
    }
    
    [self.pregnantLabel setTitle:self.user.isSecondary ? @"We're pregnant!" : @"I'm pregnant"
                        forState:UIControlStateNormal];
    
    if ([[MedicalRecordsDataManager sharedInstance] connectStatus] != ConnectStatusConnected) {
        [[MedicalRecordsDataManager sharedInstance] fetchSummaryData];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"MeViewController"];
    
    if (self.appPurposeManager.promoPregnancyApp) {
        [self.appPurposeManager openPromoPregnancyApp];
    }
    
    // show invite-partner popup upon first impression
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL hasAsked = [defaults boolForKey:@"hasAskedForInvite"];
    if (!hasAsked) {
        [InvitePartnerDialog openDialog];
        [defaults setBool:YES forKey:@"hasAskedForInvite"];
        [defaults synchronize];
    }

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.meHeader removeMotionEffect];
}


- (void)onLogout:(Event *)event
{
    [self unsubscribeAll];
}


- (void)layoutSublayersOfLayer:(CALayer *)layer
{
    [super layoutSublayersOfLayer:layer];
}


- (void)openBlog
{
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES from:self];
    [controller openUrl:[Utils makeUrl:GLOW_BLOG_URL]];
}


- (void)onPregnant:(Event *)e
{
    if (self.navigationController.topViewController != self) {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
    
    [self.appPurposeManager switchingToPurpose:AppPurposesAlreadyPregnant];
}


- (void)goAppGallery:(Event *)event {
    [self performSegueWithIdentifier:kAppGallerySegueIdentifier sender:nil];
}

- (void)goToGlowFirstPage
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    UIViewController *vc = [self fundViewController];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)setStatusConnectionLinesHidden:(BOOL)hidden
{
    for (UIView *line in self.statusConnectionLines) {
        line.hidden = hidden;
    }
}

#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        if (![self userCanChangeStatus]) {
            return 1;
        }
    }
    return [super tableView:tableView numberOfRowsInSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    // status section
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // status cell
    if (indexPath.section == 0 && indexPath.row == 0) {
        self.statusLabel.text = [self.appPurposeManager descriptionForCurrentStatus];
        if (self.user.settings.currentStatus == AppPurposesTTCWithTreatment) {
            self.chooseTreatmentButton.hidden = NO;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            self.chooseTreatmentButton.hidden = YES;
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        
        [cell bringSubviewToFront:cell.contentView];
    }
    
    return cell;
}

- (BOOL)userCanChangeStatus
{
    return ![User currentUser].isSecondary;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AppPurposes status = self.user.settings.currentStatus;
    
    // status, i am pregnant, see all status
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            BOOL nonTTC = (status == AppPurposesAvoidPregnant || status == AppPurposesNormalTrack);
            if (nonTTC || status == AppPurposesAlreadyPregnant) {
                [self setStatusConnectionLinesHidden:YES];
                return 0;
            } else {
                [self setStatusConnectionLinesHidden:NO];
            }
        }
        if (![self userCanChangeStatus]) {
            [self setStatusConnectionLinesHidden:YES];
        }
    }
    
    // fertility testing, health profile, export pdf, connect apps, glow first
    else if (indexPath.section == 1) {
        User *user = [User currentUser];
        if (indexPath.row == 0 && (user.isSecondary || user.isMale || (status != AppPurposesTTCWithTreatment && status != AppPurposesTTC))) {
            return 0;
        }
        
        if (indexPath.row == 2 && self.user.isSecondaryOrSingleMale) {
            return 0;
        }
        if (indexPath.row == 5) {
            if (![self enableGlowFirst]) {
                return 0.0;
            }
        }
    }
    
    // invite partner, tell friends, success stories, give five stars
    else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            if (self.user.partner) {
                return 0.5;     // the border will be missing if return 0
            }
        }
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        if (indexPath.row == 2) {
            [Logging log:BTN_CLK_HELP_EXPORT];
            [[[ExportReportDialog alloc] initWithUser:[User currentUser]] present];
        }
        else if (indexPath.row == 4) {
            [Logging log:BTN_CLK_ME_GLOW_APP_GALLERY];
            [self showOtherGlowApps];
        }
        else if (indexPath.row == 5) {
            [Logging log:BTN_CLK_ME_GLOW_FIRST];
            [self goToGlowFirstPage];
        }
    }
    else if (indexPath.section == 2) {
        NSUInteger row = indexPath.row;
        if (row == 0) {
            [Logging log:BTN_CLK_ME_INVITE_PARTNER];
            [InvitePartnerDialog openDialog];
        }
        else if (row == 1) {
            [Logging log:BTN_CLK_ME_SEND_MIRACLES];
            [ShareController presentWithShareType:ShareTypeAppShareMe shareItem:nil fromViewController:self];
        }
        else if (row == 2) {
            [Logging log:BTN_CLK_ME_GLOW_BLOG];
            [self openBlog];
        }
        else if (row == 3) {
            [Logging log:BTN_CLK_ME_FIVE_STARS];
            [[AskRateDialog getInstance] goToRatePage];
        }
    }
    else if (indexPath.section == 3 && indexPath.row == 2) {
        [Logging log:BTN_CLK_HELP_FEEDBACK];
        [[Sendmail sharedInstance] composeTo:@[FEEDBACK_RECEIVER]
                                     subject:@""
                                        body:@""
                            inViewController:self
                                withCallback:^(BOOL success) {
                                    if (success) {
                                        [self.user sendDebugReportWithShowingNetwork:NO];
                                    }
        }];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showOtherGlowApps
{
    GLAppGalleryTableViewController *gallery = [GLAppGalleryTableViewController viewControllerFromStoryboard];
    NSMutableArray *apps = [NSMutableArray array];
    {
        GLAppEntity *app = [[GLAppEntity alloc] init];
        app.appID = 638021335;
        app.name = @"Eve";
        app.schema = @"lexie://";
        app.desc = @"Eve by Glow is a savvy health & sex app for women who want to take control of their sex lives.";
        app.icon = [UIImage imageNamed:@"ruby-logo"];
        [apps addObject:app];
    }
    {
        GLAppEntity *app = [[GLAppEntity alloc] init];
        app.appID = 882398397;
        app.name = @"Glow Nurture";
        app.schema = @"kaylee://";
        app.desc = @"Glow Nurture is an unparalleled pregnancy tracker that takes care of you while you prepare to welcome your baby.";
        app.icon = [UIImage imageNamed:@"nurture-icon"];
        [apps addObject:app];
    }
    gallery.apps = apps;
    gallery.navigationItem.title = @"Glow App Gallery";
    gallery.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:gallery animated:YES from:self];
}

- (UIViewController *)fundViewController
{
    UIViewController *dest = nil;
    User *u = [User currentUser];
    
    switch (u.ovationStatus) {
        case OVATION_STATUS_UNDER_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"appliedFund"];
            break;
        case OVATION_STATUS_PASS_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"acceptedFund"];
            break;
        case OVATION_STATUS_FAIL_REVIEW:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"rejectedFund"];
            break;
        case OVATION_STATUS_UNDER_FUND:
        case OVATION_STATUS_UNDER_FUND_DELAY:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"ongoing"];
            break;
        case OVATION_STATUS_EXIT_FUND:
        case OVATION_STATUS_PREGNANT:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"ongoing"];
            break;
        case OVATION_STATUS_GET_FUND:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"fundClaimPre"];
            break;
        case OVATION_STATUS_DEMO:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"demo"];
            break;
        default:
            dest = [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateViewControllerWithIdentifier:@"home"];
            break;
    }
    
    return dest;
}

- (BOOL)enableGlowFirst {
    return ([User currentUser] && [User currentUser].currentPurpose != AppPurposesAvoidPregnant);
}


- (IBAction)PregnantButtonClicked:(id)sender
{
//    [sender setIconName:@"check"];
    [Logging log:BTN_CLK_ME_PREGNANT_AFTER_STATUS];
    [self.appPurposeManager switchingToPurpose:AppPurposesAlreadyPregnant];
}


#pragma mark - Segue
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [super prepareForSegue:segue sender:sender];
    
    if ([segue.identifier isEqualToString:kAppGallerySegueIdentifier]) {
        AppGalleryTableViewController *vc = (AppGalleryTableViewController *)segue.destinationViewController;
        vc.user = self.user;
    }
    else if ([segue.identifier isEqualToString:kSettingsSegueIdentifier]) {
        [Logging log:BTN_CLK_ME_GO_SETTINGS];
    }
    else if ([segue.identifier isEqualToString:kHelpSegueIdentifier]) {
        [Logging log:BTN_CLK_ME_GO_HELP];
    }
    else if ([segue.identifier isEqualToString:kCurrentStatusSegueIdentifier]) {
        CurrentStatusTableViewController *vc = (CurrentStatusTableViewController *)segue.destinationViewController;
        vc.appPurposeManager = self.appPurposeManager;
        vc.user = self.user;
        [Logging log:BTN_CLK_ME_GO_STATUS_PAGE];
    }
    else if ([segue.identifier isEqualToString:kPregnantSegueIdentifier]) {
        
    }
    else if ([segue.identifier isEqualToString:@"fertilityTreatmentIdentifier"]) {
        [Logging log:BTN_CLK_ME_TREATMENT_HISTORY];
    }
    else if ([segue.identifier isEqualToString:@"healthProfileSegue"]) {
        [Logging log:BTN_CLK_ME_HEALTH_PROFILE];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offsetY = self.tableView.contentOffset.y + self.tableView.contentInset.top;
    [self.meHeader updateBackgroundFrameWithOffset:offsetY];
}


#pragma mark - ImagePickerDelegate
- (void)didPickedImage:(UIImage *)image
{
    if (self.meHeader.tagWaitingImage == kTagProfileImage) {
        [[User currentUser] updateProfileImage:image];
    } else if (self.meHeader.tagWaitingImage == kTagBackgroundImage) {
        [[User currentUser].settings updateBackgroundImage:image];
    }
}


- (void)imagePickerDidClickDestructiveButton
{
    if (self.meHeader.tagWaitingImage == kTagBackgroundImage) {
        User *currentUser = [User currentUser];
        [currentUser.settings restoreBackgroundImage];
    }
}


#pragma mark - profile actions/delegate
- (IBAction)editProfile:(id)sender
{
    ForumEditProfileViewController *vc = [[ForumEditProfileViewController alloc] initWithUser:[Forum currentForumUser]];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)onProfileModified:(Event *)evt
{
    NSString *title;
    if (self.user.partner) {
        title = [NSString stringWithFormat:@"%@ & %@", self.user.firstName, self.user.partner.firstName];
    } else
        title = self.user.firstName;
    self.navigationItem.title = title;
    
    [self.meHeader updateProfileCell];
    self.tableView.tableHeaderView = self.meHeader;
}

@end

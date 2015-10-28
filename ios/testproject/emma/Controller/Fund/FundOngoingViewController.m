//
//  FundOngoingViewController.m
//  emma
//
//  Created by Eric Xu on 5/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define ARC4RANDOM_MAX      0x100000000
#define ACTIVE_COLOR UIColorFromRGB(0x6cba2d)
#define INACTIVE_COLOR UIColorFromRGB(0xdc4234)
#define EVENT_PREGNANT_PRESSED @"event_pregnant_pressed"
#define EVENT_CONTACT_US_PRESSED @"event_contact_us_pressed"

#import <UIDeviceUtil/UIDeviceUtil.h>
#import "FundOngoingViewController.h"
#import "User.h"
#import "Activity.h"
#import "PillButton.h"
#import "PregnantCongratsDialog.h"
#import "ActivityLevel.h"
#import "PillGradientButton.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "GlowFirst.h"
#import "Logging.h"
#import "TabbarController.h"
#import "FundOngoingSectionHeader.h"
#import "FundOngoingBaseCell.h"
#import "FundOngoingGrantCell.h"
#import "FundOngoingButtonCell.h"
#import "FundOngoingActivityCell.h"
#import "Errors.h"
#import <GLFoundation/NSString+Markdown.h>

#define FUND_ONGOING_GRANT_CELL_IDENTIFIER @"grantCell"
#define FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER @"activityCell"
#define FUND_ONGOING_BUTTON_CELL_IDENTIFIER @"buttonCell"
#define FUND_ONGOING_STATUS_CELL_IDENTIFIER @"statusCell"


@interface FundEndPregnantStateCell : FundOngoingBaseCell
@property (nonatomic) NSInteger contribution;
@property (strong, nonatomic) IBOutlet UILabel *contributionLabel;
@property (strong, nonatomic) IBOutlet PillGradientButton *contactUsButton;
- (IBAction)contactUsPressed:(id)sender;
@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *fontAttributedTexts;

@end

@implementation FundEndPregnantStateCell
- (void)awakeFromNib {
    [self.contactUsButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}

- (IBAction)contactUsPressed:(id)sender {
    GLLog(@"contact us");
    [self publish:EVENT_CONTACT_US_PRESSED];
}

- (void)setContribution:(NSInteger)contribution {
    _contribution = contribution;
    NSString * text;
    if (contribution == 0) {
        text = @"contribution will now be used";
    } else {
        text = [NSString stringWithFormat: @"contribution of **$%ld** will now be used", (long)contribution];
    }
    self.contributionLabel.attributedText = [Utils markdownToAttributedText:text fontSize:14 lineHeight:14 color:[UIColor whiteColor]  alignment:NSTextAlignmentCenter];
    
    for (UILabel * label in self.fontAttributedTexts) {
        label.attributedText = [NSString addFont:[Utils defaultFont:14.0] toAttributed:label.attributedText];
    }
}
@end

@interface FundEndPregnantDetailCell : FundOngoingBaseCell
@property (strong, nonatomic) IBOutlet UILabel *primaryLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLabel;
@property (strong, nonatomic) IBOutlet UIView *circle;

@end

@implementation FundEndPregnantDetailCell
- (void)awakeFromNib {
    [self.circle.layer setCornerRadius:70];

    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = CGRectMake(0, 0, 140, 140);
    gradient.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGB(0x4149c1) CGColor], (id)[UIColorFromRGB(0x7682dd) CGColor], nil];
    gradient.cornerRadius = 70;
    [self.circle.layer insertSublayer:gradient atIndex:0];
    self.circle.backgroundColor = [UIColor clearColor];

}
@end

@interface FundEndKickedStateCell : FundOngoingBaseCell
@property (nonatomic) NSInteger contribution;
@property (strong, nonatomic) IBOutlet UILabel *contributionLabel;
@property (strong, nonatomic) IBOutlet UILabel *kickedReasonLabel;
@property (strong, nonatomic) IBOutlet PillGradientButton *contactUsButton;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *fontAttributedTexts;
- (IBAction)contactUsPressed:(id)sender;

@end

@implementation FundEndKickedStateCell
- (void)awakeFromNib {
    [self.contactUsButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}

- (IBAction)contactUsPressed:(id)sender {
    GLLog(@"contact us");
    [self publish:EVENT_CONTACT_US_PRESSED];
}

- (void)setContribution:(NSInteger)contribution {
    _contribution = contribution;
    NSString * text;
    if (contribution == 0) {
        text = @"Your prior contribution will be";
    } else {
        text = [NSString stringWithFormat: @"Your prior contribution of **$%ld** will be", (long)contribution];
    }
    self.contributionLabel.attributedText = [Utils markdownToAttributedText:text fontSize:14 lineHeight:14 color:[UIColor whiteColor] alignment:NSTextAlignmentCenter];
    
    for (UILabel * label in self.fontAttributedTexts) {
        label.attributedText = [NSString addFont:[Utils defaultFont:14.0] toAttributed:label.attributedText];
    }
}

- (void)setStopReason:(NSString *)reason {
    self.kickedReasonLabel.attributedText = [Utils markdownToAttributedText:reason fontSize:14 lineHeight:14 color:[UIColor whiteColor] alignment:NSTextAlignmentCenter];
}
@end

@interface StatusCell : FundOngoingBaseCell {
}
@property (nonatomic, strong) IBOutlet UILabel *contributionsLabel;
@property (nonatomic, strong) IBOutlet UILabel *pregnanciesLabel;
@property (nonatomic, strong) IBOutlet UILabel *participationLabel;

@end

@implementation StatusCell
@end

@interface FundOngoingViewController ()<UIAlertViewDelegate, MFMailComposeViewControllerDelegate> {
    IBOutlet UIView *bgView;
}

@end

@implementation FundOngoingViewController

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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingGrantCell" bundle:nil] forCellReuseIdentifier:FUND_ONGOING_GRANT_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingActivityCell" bundle:nil] forCellReuseIdentifier:FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"FundOngoingButtonCell" bundle:nil] forCellReuseIdentifier:FUND_ONGOING_BUTTON_CELL_IDENTIFIER];
    
    [self.tableView setContentInset:UIEdgeInsetsMake(-50, 0, 0, 0)];

    self.navigationItem.title = @"Glow First™";
    self.tableView.backgroundView = bgView;
    
    GlowFirst *gf = [GlowFirst sharedInstance];
    NSInteger ovationStatus = [User currentUser].ovationStatus;

    if (ovationStatus == OVATION_STATUS_PREGNANT) {
        [gf syncFundsSummary];
        [gf syncFundPaid];
    }else if (ovationStatus == OVATION_STATUS_EXIT_FUND) {
        [gf syncUserFundSummary];
        [gf syncFundPaid];
        if ([Utils isEmptyString:gf.fundStopReason]) {
            [gf syncFundStopReason];
        }
    } else {
        /* We keep this line, since we disable the first part, but may enable in future
        [gf syncFundsSummary];
        */
        if (ovationStatus == OVATION_STATUS_UNDER_FUND) {
            [gf syncUserFundSummary];
        }
        [self subscribe:EVENT_PREGNANT_PRESSED handler:^(Event *event) {
            PregnantCongratsDialog * dlg = [[PregnantCongratsDialog alloc] initWithNibName:@"PregnantCongratsDialog" bundle:nil];
            [dlg stopGlowFirst];
        }];
        [self subscribe:EVENT_FUND_USER_PREGNANT selector:@selector(userDidPregnant:)];
    }
    [self subscribe:EVENT_CONTACT_US_PRESSED selector:@selector(contactUs)];
    __weak FundOngoingViewController *_self = self;
    [self subscribe:EVENT_FUND_SYNC_PAID handler:^(Event *event) {
        [_self.tableView reloadData];
    }];
    [self subscribe:EVENT_FUND_SYNC_SUMMARY handler:^(Event *event) {
        [_self.tableView reloadData];
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(cellDidScrolled:) withObject:[NSValue valueWithCGPoint:self.tableView.contentOffset]];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.tableView.visibleCells makeObjectsPerformSelector:@selector(cellDidScrolled:) withObject:[NSValue valueWithCGPoint:self.tableView.contentOffset]];
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    if (ovationStatus == OVATION_STATUS_PREGNANT) {
        [Logging log:PAGE_IMP_FUND_PREGNANT];
        [CrashReport leaveBreadcrumb:@"FundOngoingViewController - pregnant"];
    }else if (ovationStatus == OVATION_STATUS_EXIT_FUND) {
        [Logging log:PAGE_IMP_FUND_STOP];
        [CrashReport leaveBreadcrumb:@"FundOngoingViewController - stop"];
    } else {
        [Logging log:PAGE_IMP_FUND_ONGOING];
        [CrashReport leaveBreadcrumb:@"FundOngoingViewController - ongoing"];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    NSInteger preMonthsCount = [[Activity getGlowFirstActivityHistory:[User currentUser]] count];
    switch (ovationStatus) {
        case OVATION_STATUS_UNDER_FUND:
            return preMonthsCount > 0 ? 5 : 4;
        case OVATION_STATUS_UNDER_FUND_DELAY:
            return preMonthsCount > 0 ? 4 : 3;
        case OVATION_STATUS_PREGNANT:
            return 1;
        case OVATION_STATUS_EXIT_FUND:
            return 1;
        default:
            return 2;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    User * user = [User currentUser];
    if (ovationStatus == OVATION_STATUS_UNDER_FUND) {
        // add this line, since we temply disable the first part
        if (section == 0) return 0;
        return section <= 3 ? 1: [[Activity getGlowFirstActivityHistory:user] count];
    } else if (ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY) {
        // add this line, since we temply disable the first part
        if (section == 0) return 0;
        return section <= 2 ? 1: [[Activity getGlowFirstActivityHistory:user] count];
    } else if (ovationStatus == OVATION_STATUS_PREGNANT) {
        return section == 0? 1: 3;
    } else if (ovationStatus == OVATION_STATUS_EXIT_FUND) {
        return section == 0? 1: [[Activity getGlowFirstActivityHistory:user] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView fundPregnantCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSArray *identifiers = nil;
    identifiers = @[@"fundEndPregnant", @"pregantDetail"];
    CellIdentifier = [identifiers objectAtIndex:indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *fundsSummary = [[GlowFirst sharedInstance] getFundsSummary];
    
    if ([cell isKindOfClass:[FundEndPregnantStateCell class]]) {
        FundEndPregnantStateCell *aCell = (FundEndPregnantStateCell *)cell;
        [aCell setContribution:[GlowFirst sharedInstance].fundPaid];
    } else if ([cell isKindOfClass:[FundEndPregnantDetailCell class]]) {
        FundEndPregnantDetailCell *aCell = (FundEndPregnantDetailCell *)cell;        
        NSArray *primaryLabels = @[
                [fundsSummary objectForKey:@"amounts"],
                [fundsSummary objectForKey:@"pregnancies"],
                [fundsSummary objectForKey:@"users_all"]
                ];
        NSArray *secondaryLabels = @[@"Contributions in Glow First", @"Successful pregnancies", @"Couples participating"];
        [aCell.primaryLabel setText:[primaryLabels objectAtIndex:indexPath.row]];
        [aCell.secondaryLabel setAttributedText:[Utils markdownToAttributedText:[secondaryLabels objectAtIndex:indexPath.row] fontSize:14 lineHeight:16 color:[UIColor whiteColor] alignment:NSTextAlignmentCenter]];
    }

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView fundExitCellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"Cell";
    NSArray *identifiers = nil;
    identifiers = @[@"fundEndKicked",
                    FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER];
    CellIdentifier = [identifiers objectAtIndex:indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    if ([cell isKindOfClass:[FundEndKickedStateCell class]]) {
        GlowFirst *gf = [GlowFirst sharedInstance];
        FundEndKickedStateCell *aCell = (FundEndKickedStateCell *)cell;
        [aCell setContribution:gf.fundPaid];
        if ([Utils isNotEmptyString:gf.fundStopReason]) {
            [aCell setStopReason:gf.fundStopReason];
        }
    } else if ([cell isKindOfClass:[FundOngoingActivityCell class]]){
        FundOngoingActivityCell *aCell = (FundOngoingActivityCell *)cell;
        ActivityLevel *activity = [[Activity getGlowFirstActivityHistory:[User currentUser]] objectAtIndex:indexPath.row];
        GLLog(@"act: %d %@", activity.activeLevel, activity.activityDescription);
        aCell.active = activity.activeLevel != ACTIVITY_INACTIVE;
        aCell.activityLabel.text = activity.activityDescription;
        aCell.monthLabel.text = activity.monthLabel;
        aCell.scoreLabel.text = [NSString stringWithFormat:@"%2.1f%%", activity.activeScore * 100];
        // This value is used for the size of background cycle, minus 1
        // The max size is 160% (score=100%), min size is 100% (score=15%)
        aCell.activeLevel = ((activity.activeScore - 0.15) / 0.85) * 0.6;
    }
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView underFundCellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    NSArray *identifiers = nil;
    NSInteger staticSections;
    if ([User currentUser].ovationStatus == OVATION_STATUS_UNDER_FUND) {
        identifiers = @[FUND_ONGOING_STATUS_CELL_IDENTIFIER,
                        FUND_ONGOING_GRANT_CELL_IDENTIFIER,
                        FUND_ONGOING_BUTTON_CELL_IDENTIFIER,
                        FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER,
                        FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER];
        staticSections = 3;
    } else {
        identifiers = @[FUND_ONGOING_STATUS_CELL_IDENTIFIER,
                        FUND_ONGOING_GRANT_CELL_IDENTIFIER,
                        FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER,
                        FUND_ONGOING_ACTIVITY_CELL_IDENTIFIER];
        staticSections = 2;
    }
    CellIdentifier = [identifiers objectAtIndex:indexPath.section];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    NSDictionary *fundsSummary = [[GlowFirst sharedInstance] getFundsSummary];
    NSDictionary *userFundSummary = [[GlowFirst sharedInstance] getUserFundSummary];
    
    if ([cell isKindOfClass:[StatusCell class]]) {
        // in V2.1.1, we disable this part
        return nil;
        // top bar, 3 numbers
        StatusCell *aCell = (StatusCell *)cell;
        aCell.contributionsLabel.text = [fundsSummary objectForKey:@"amounts"];
        aCell.pregnanciesLabel.text = [fundsSummary objectForKey:@"pregnancies"];
        aCell.participationLabel.text = [fundsSummary objectForKey:@"users_all"];
    } else if ([cell isKindOfClass:[FundOngoingGrantCell class]]) {
        // current month circle, 2 numbers
        FundOngoingGrantCell *aCell = (FundOngoingGrantCell *)cell;
        aCell.mainLabel.text = [userFundSummary objectForKey:@"potentialGrant"];
        aCell.secondaryLabel.text = [NSString stringWithFormat:@"You contributed %@", [userFundSummary objectForKey:@"userAmount"]];
    } else if ([cell isKindOfClass:[FundOngoingButtonCell class]]) {
        FundOngoingButtonCell *bCell = (FundOngoingButtonCell *)cell;
        [bCell setIsPregnantButton:YES];
    } if ([cell isKindOfClass:[FundOngoingActivityCell class]]) {
        // history months
        FundOngoingActivityCell *aCell = (FundOngoingActivityCell *)cell;
        
        ActivityLevel *activity = nil;
        if (indexPath.section == staticSections) {
            activity = [Activity getActivityForCurrentMonth:[User currentUser]];
        } else {
            activity = [[Activity getGlowFirstActivityHistory:[User currentUser]] objectAtIndex:indexPath.row];
        }
        
        aCell.active = activity.activeLevel != ACTIVITY_INACTIVE;
        aCell.activityLabel.text = activity.activityDescription;
        aCell.monthLabel.text = activity.monthLabel;
        aCell.scoreLabel.text = [NSString stringWithFormat:@"%2.1f%%", activity.activeScore * 100];
        
        // This value is used for the size of background cycle, minus 1
        // The max size is 160% (score=100%), min size is 100% (score=15%)
        aCell.activeLevel = ((activity.activeScore - 0.15) / 0.85) * 0.6;
    }
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    if ((ovationStatus == OVATION_STATUS_UNDER_FUND) || (ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY)) {
        return [self tableView:tableView underFundCellForRowAtIndexPath:indexPath];
    } else if (ovationStatus == OVATION_STATUS_PREGNANT) {
        return [self tableView:tableView fundPregnantCellForRowAtIndexPath:indexPath];
    } else {
        //  (ovationStatus == OVATION_STATUS_EXIT_FUND)
        return [self tableView:tableView fundExitCellForRowAtIndexPath:indexPath];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    if (ovationStatus == OVATION_STATUS_UNDER_FUND) {
        // We keep this line, since we disable the first part, but may enable in future
        // NSArray *rowHeight = @[@100, @255, @165, @160, @160];
        NSArray *rowHeight = @[@0, @255, @165, @160, @160];
        return [[rowHeight objectAtIndex:indexPath.section ] integerValue];
    } else if (ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY) {
        // keep this line, since we temply disable the first part
        // NSArray *rowHeight = @[@100, @255, @160, @160];
        NSArray *rowHeight = @[@0, @255, @160, @160];
        return [[rowHeight objectAtIndex:indexPath.section ] integerValue];
    } else if (ovationStatus == OVATION_STATUS_PREGNANT) {
        return indexPath.section == 0? 300: 160;
    } else {
        //  (ovationStatus == OVATION_STATUS_EXIT_FUND)
        return indexPath.section == 0? 315: 160;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSArray *headerText = nil;
    NSArray *headerTextWidth = nil;
    NSInteger ovationStatus = [User currentUser].ovationStatus;
    
    if (ovationStatus == OVATION_STATUS_PREGNANT) {
        headerText = @[@"", @"Glow First to-date"];
        headerTextWidth = @[@0, @148];
    } else if (ovationStatus == OVATION_STATUS_EXIT_FUND) {
        headerText = @[@"", @"Previous engagement level"];
        headerTextWidth = @[@0, @205];
    } else {
        if ([User currentUser].ovationStatus == OVATION_STATUS_UNDER_FUND) {
            headerText = @[@"", @"Your potential grant", @"Click below to stop contributing", @"Current engagement level", @"Previous engagement level"];
            headerTextWidth = @[@0, @148, @230, @200, @205];
        } else {
            headerText = @[@"", @"Your potential grant", @"Current engagement level", @"Previous engagement level"];
            headerTextWidth = @[@0, @148, @200, @205];
        }
    }
    
    if (section == 0) {
        // give an empty header with transform background, because we don't want to
        // other headers stay at top when scroll up
        UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_HEIGHT, 50)];
        view.backgroundColor = [UIColor clearColor];
        return view;
    } else {
        FundOngoingSectionHeader * header = [[[NSBundle mainBundle] loadNibNamed:@"FundOngoingSectionHeader" owner:nil options:nil] objectAtIndex:0];
        [header setHeaderText:[headerText objectAtIndex:section] width:[[headerTextWidth objectAtIndex:section] integerValue]];
        return header;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(willShow)]) {
        [cell performSelector:@selector(willShow)];
    }
}

#pragma -
#pragma mark UIAlertViewDelegate
- (void)userDidPregnant:(Event *)event {
    NSDictionary * response = (NSDictionary *)(event.data);
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_SUCCESS) {
        [[TabbarController getInstance:self] rePerformFundSegue];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)contactUs {
    GLLog(@"contactUs, to present MFMailComposeViewController");
    UIDevice *device = [UIDevice currentDevice];
    NSString *msgBody = [NSString stringWithFormat:@"<br><br>**My device is %@, and iOS version is %@**", [UIDeviceUtil hardwareDescription], [device systemVersion]];
    NSString *subject = [User currentUser].ovationStatus == OVATION_STATUS_PREGNANT? @"I'm pregnant!": @"Contribution stopped";
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:@[FEEDBACK_RECEIVER]];
    [controller setMessageBody:msgBody isHTML:YES];
    [controller setSubject:subject];
    
    if (controller && [MFMailComposeViewController canSendMail]) {
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: @"mailto:%@", FEEDBACK_RECEIVER]];
        if ([[UIApplication sharedApplication] canOpenURL:url])
            [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        //        GLLog(@"It's away!");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end

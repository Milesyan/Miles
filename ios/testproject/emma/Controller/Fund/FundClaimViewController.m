//
//  FundPreClaimViewController.m
//  emma
//
//  Created by Eric Xu on 5/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIDeviceUtil/UIDeviceUtil.h>
#import "FundClaimViewController.h"
#import "PillGradientButton.h"
#import "Logging.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "Utils.h"
#import "GlowFirst.h"
#import "FundOngoingSectionHeader.h"
#import <MessageUI/MFMailComposeViewController.h>
#import <GLFoundation/NSString+Markdown.h>

#define EVENT_FUND_CLAIM_LIST_CLINICS @"event_fund_claim_list_clinics"
#define EVENT_FUND_CLAIM_CONTACT_US @"event_fund_claim_contact_us"

@interface FundClaimViewInfoCell : UITableViewCell

@property (strong, nonatomic) IBOutlet PillGradientButton *clinicsButton;
@property (strong, nonatomic) IBOutlet PillGradientButton *sendProofButton;
@property (strong, nonatomic) IBOutlet UILabel * deadline;
@property (strong, nonatomic) IBOutlet UILabel * contactUsLabel;
@property (nonatomic) UITapGestureRecognizer * contactTap;

- (IBAction)listClinicsPressed:(id)sender;

@end

@implementation FundClaimViewInfoCell

- (void)awakeFromNib {
    [self.clinicsButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    [self.sendProofButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    if (!self.contactTap) {
        self.contactTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contactUsClicked:)];
        [self.contactTap setNumberOfTapsRequired:1];
        [self.contactUsLabel addGestureRecognizer:self.contactTap];
        self.contactUsLabel.userInteractionEnabled = YES;
    }
}

- (IBAction)listClinicsPressed:(id)sender {
    [self publish:EVENT_FUND_CLAIM_LIST_CLINICS];
    return;
}

- (void)contactUsClicked:(Event *)event {
    [self publish:EVENT_FUND_CLAIM_CONTACT_US];
}

@end

@interface FundClaimViewClaimCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *claimCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *claimTextLabel;
@property (weak, nonatomic) IBOutlet UIView *claimCircle;
@property (nonatomic) IBOutlet UILabel * headerLabel;

@end

@implementation FundClaimViewClaimCell

- (void)awakeFromNib {
    self.claimCircle.layer.cornerRadius = 100;
    self.headerLabel.layer.cornerRadius = 15;
}

@end

@interface FundClaimViewGrantCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIView *grantBG;
@property (strong, nonatomic) IBOutlet UIView *grantCircle;
@property (strong, nonatomic) IBOutlet UILabel *grantLabel;
@property (strong, nonatomic) IBOutlet UILabel *grantSubtitle;
@property (nonatomic) IBOutlet UILabel * headerLabel;

@end

@implementation FundClaimViewGrantCell

- (void)awakeFromNib {
    self.grantBG.layer.cornerRadius = 120;
    self.grantCircle.layer.cornerRadius = 100;
    self.headerLabel.layer.cornerRadius = 15;
}

@end


@interface FundClaimViewController () <MFMailComposeViewControllerDelegate>

@property (nonatomic) IBOutlet FundClaimViewInfoCell *infoCell;
@property (nonatomic) IBOutlet FundClaimViewClaimCell *claimCell;
@property (nonatomic) IBOutlet FundClaimViewGrantCell *grantCell;
@property (strong, nonatomic) IBOutlet UIView *bgView;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *fontAttributedTexts;
- (IBAction)claimButtonClicked:(id)sender;

@end

@implementation FundClaimViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.title = @"Glow First™";
    self.tableView.backgroundView = self.bgView;
    
    for (UILabel * label in self.fontAttributedTexts) {
        label.attributedText = [NSString addFont:[Utils defaultFont:14.0] toAttributed:label.attributedText];
    }
    
    [self subscribe:EVENT_FUND_SYNC_GRANT selector:@selector(refresh)];
    [self subscribe:EVENT_FUND_SYNC_BALANCE selector:@selector(refresh)];
    [self subscribe:EVENT_FUND_CLAIM_LIST_CLINICS selector:@selector(listClinicsPressed:)];
    [self subscribe:EVENT_FUND_CLAIM_CONTACT_US selector:@selector(contactUsClicked:)];
    [[GlowFirst sharedInstance] syncFundGrant];
    [self refresh];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[GlowFirst sharedInstance] syncCreditBalance];
}

- (void)refresh {
    GlowFirst * fund = [GlowFirst sharedInstance];
    
    // info cell
    self.infoCell.sendProofButton.enabled = NO;
    if (fund.fundGrantDeadline) {
        self.infoCell.deadline.text = [fund.fundGrantDeadline toReadableDate];
        if ([fund.fundGrantDeadline timeIntervalSinceNow] > 0) {
            self.infoCell.sendProofButton.enabled = YES;
        }
    } else {
        self.infoCell.deadline.text = @"-";
    }
    // TODO
    // self.infoCell.sendProofButton.enabled = YES;
    
    // claim cell
    self.claimCell.claimCountLabel.text = [NSString stringWithFormat:@"%d", fund.reviewClaims];
    self.claimCell.claimTextLabel.text  = [NSString stringWithFormat:@"claim%s under review", fund.reviewClaims == 1 ? "": "s"];
    
    // grant cell
    self.grantCell.grantLabel.text = [fund getBalanceString];
    
    CGFloat creditClaimed = [fund getFundGrant] - [fund getBalance];
    self.grantCell.grantSubtitle.text = [NSString stringWithFormat:@"You've claimed %@\n\n out of %@", [fund getCreditString:creditClaimed], [fund getFundGrantString]];
    
    if ((fund.reviewClaims == 0) && (creditClaimed == 0)) {
        self.grantCell.headerLabel.text = @"Final grant";
    } else {
        self.grantCell.headerLabel.text = @"Grant left";
    }
    
    [self.tableView reloadData];
}

#pragma mark - IBAction
- (void)listClinicsPressed:(id)sender {
    [self.navigationController pushViewController:[UIStoryboard clinicsNearby] animated:YES from:self];
}

- (IBAction)claimButtonClicked:(id)sender {
    User * u = [User currentUser];
    // TODO, need change the if back
    if ([Utils isEmptyString:u.settings.taxId]) {
        [self performSegueWithIdentifier:@"termsSegue" sender:self from:self];
    } else {
        [self performSegueWithIdentifier:@"claimSegue" sender:self from:self];
    }
}

- (void)contactUsClicked:(Event *)event {
    GLLog(@"contactUs, to present MFMailComposeViewController");
    UIDevice *device = [UIDevice currentDevice];
    NSString *msgBody = [NSString stringWithFormat:@"<br><br>**My device is %@, and iOS version is %@**", [UIDeviceUtil hardwareDescription], [device systemVersion]];
    NSString *subject = @"GlowFirst Claim question";
    
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:@[GF_CLAIM_RECEIVER]];
    [controller setMessageBody:msgBody isHTML:YES];
    [controller setSubject:subject];
    
    if (controller && [MFMailComposeViewController canSendMail]) {
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat: @"mailto:%@", GF_CLAIM_RECEIVER]];
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

#pragma mark - table view source and delegate
- (BOOL)hasClaimRow {
    return [GlowFirst sharedInstance].reviewClaims > 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 480;
    } else if (indexPath.row == 1) {
        return [self hasClaimRow] ? 280 : 0;
    } else {
        return 320;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return self.infoCell;
    } else if (indexPath.row == 1) {
        if ([self hasClaimRow]) {
            return self.claimCell;
        } else {
            return [[UITableViewCell alloc] initWithFrame:CGRectMake(0, 0, 320, 0)];
        }
    } else {
        return self.grantCell;
    }
}

@end

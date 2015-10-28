//
//  FundApplyWaysViewController.m
//  emma
//
//  Created by Jirong Wang on 12/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundApplyWaysViewController.h"
#import "Logging.h"
#import "User.h"
#import "SingleColorImageView.h"
#import "Tooltip.h"

@interface FundApplyWaysViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *buttonMidLines;
@property (weak, nonatomic) IBOutlet UIButton *personalButton;

@property (weak, nonatomic) IBOutlet UILabel *tipLabelInPerson;
@property (weak, nonatomic) IBOutlet UILabel *tipLabelNotAvailable;
@property (weak, nonatomic) IBOutlet SingleColorImageView *arrowInPerson;

- (IBAction)backButtonPressed:(id)sender;
- (IBAction)personalButtonPressed:(id)sender;
- (IBAction)enterpriseButtonPressed:(id)sender;

@end

@implementation FundApplyWaysViewController

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
	// Do any additional setup after loading the view.
    for (UIView * view in self.buttonMidLines) {
        view.frame = setRectHeight(view.frame, 0.5);
    }
    
    User * u = [User currentUser];
    if (u.settings.currentStatus == AppPurposesTTCWithTreatment) {
        self.personalButton.backgroundColor = UIColorFromRGBA(0x00000077);
        self.personalButton.layer.cornerRadius = 5;
        self.tipLabelInPerson.hidden = YES;
        self.arrowInPerson.hidden = YES;
        self.tipLabelNotAvailable.hidden = NO;
    } else {
        self.tipLabelNotAvailable.hidden = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    // logging
    [CrashReport leaveBreadcrumb:@"FundApplyWaysViewController"];
    [Logging log:PAGE_IMP_FUND_WAYS];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_WAYS_BACK];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)personalButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_WAYS_PERSONAL];
    User * u = [User currentUser];
    if (u.settings.currentStatus == AppPurposesTTCWithTreatment) {
        [Tooltip tip:@"Eligibility"];
    } else {
        [self performSegueWithIdentifier:@"waysToPersonStep2" sender:nil from:self];
    }
}

- (IBAction)enterpriseButtonPressed:(id)sender {
    [Logging log:BTN_CLK_FUND_WAYS_ENTERPRISE];
}

@end

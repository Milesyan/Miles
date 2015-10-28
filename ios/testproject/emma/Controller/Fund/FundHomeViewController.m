//
//  FundHomeViewController.m
//  emma
//
//  Created by Jirong Wang on 11/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundHomeViewController.h"
#import "User.h"
#import "Logging.h"
#import "TabbarController.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import <GLFoundation/NSString+Markdown.h>

@interface FundHomeViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dividerViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dividerLines;
@property (weak, nonatomic) IBOutlet UILabel *crowdfundingLabel;

@property (weak, nonatomic) IBOutlet UILabel *startDemoLabel;
@property (weak, nonatomic) IBOutlet UILabel *goToDetailLabel;

- (IBAction)applyButtonPressed:(id)sender;

@end

@implementation FundHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    self.fromHelpViewController = NO;
    return self;
}

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
	// Do any additional setup after loading the view.
    for (UIView *view in self.dividerViews) {
        view.layer.cornerRadius = view.frame.size.height / 2;
    }
    for (UIView *view in self.dividerLines) {
        view.frame = setRectHeight(view.frame, 0.5);
    }
    
    // navigation bar buttons
    int curStatus = [User currentUser].ovationStatus;
    if ((curStatus != OVATION_STATUS_NONE) && (curStatus != OVATION_STATUS_DEMO)) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"Applied";
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Apply";
    }
    if (self.fromHelpViewController) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    // crowdfunding label
    self.crowdfundingLabel.layer.shadowOpacity = 0.8f;
    self.crowdfundingLabel.layer.shadowRadius = 4;
    self.crowdfundingLabel.layer.shadowOffset = CGSizeMake(0, 1.0);
    self.crowdfundingLabel.layer.shadowColor = [[UIColor blackColor] CGColor];
    
    // Glow First DEMO link
    self.startDemoLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(demoLinkPressed:)];
    [reg setNumberOfTapsRequired:1];
    [self.startDemoLabel addGestureRecognizer:reg];
    
    self.startDemoLabel.attributedText = [NSString addFont:[Utils boldFont:18.0] toAttributed:self.startDemoLabel.attributedText];
    
    // details link
    self.goToDetailLabel.userInteractionEnabled = YES;
    UITapGestureRecognizer *regconizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(detailLinkPressed:)];
    [regconizer setNumberOfTapsRequired:1];
    [self.goToDetailLabel addGestureRecognizer:regconizer];
    
    self.goToDetailLabel.attributedText = [NSString addFont:[Utils boldFont:18.0] toAttributed:self.goToDetailLabel.attributedText];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
     if (IOS7_OR_ABOVE) {
     [self.tableView setContentInset:UIEdgeInsetsMake(113, 0, 49, 0)];
     }
     */
    [self subscribe:EVENT_FUND_START_DEMO selector:@selector(onStartDemo:)];
    // logging
    [CrashReport leaveBreadcrumb:@"FundHomeViewController"];
    [Logging log:PAGE_IMP_FUND_HOME];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSDate * date = [[GlowFirst sharedInstance] localFundQuitDemoDate];
    if (date) {
        if ([date timeIntervalSinceNow] < 0) {
            // hide DEMO part
            return 3;
        }
    }
    return self.fromHelpViewController ? 3 : 4;
}

#pragma mark - IBAction
- (void)demoLinkPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_HOME_START_DEMO];
    [NetworkLoadingView show];
    [[GlowFirst sharedInstance] startDemo];
}

- (void)detailLinkPressed:(id)sender
{
    [Logging log:BTN_CLK_FUND_HOME_DETAILS];
    [self performSegueWithIdentifier:@"goToDetail" sender:nil];
}

- (IBAction)applyButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_HOME_APPLY];
    if (ENABLE_GF_ENTERPRISE)
        [self performSegueWithIdentifier:@"applyFromHome" sender:self from:self];
    else
        [self performSegueWithIdentifier:@"personalFromHome" sender:self from:self];
}

- (IBAction)back:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Glow First start demo callback
- (void)onStartDemo:(Event *)event {
    [NetworkLoadingView hide];
    NSDictionary * response = (NSDictionary *)(event.data);
    
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to apply Glow Demo." duration:4.0];
    } else if (rc == RC_SUCCESS) {
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

@end

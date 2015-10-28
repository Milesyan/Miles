//
//  FundReviewingViewController.m
//  emma
//
//  Created by Jirong Wang on 3/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundReviewingViewController.h"
#import "User.h"
#import "NSObject+PubSub.h"
#import "Logging.h"
#import "NetworkLoadingView.h"
#import "GlowFirst.h"
#import "PillFlatButton.h"
#import "Sendmail.h"

@interface FundReviewingViewController () {
    IBOutlet PillFlatButton *contactBtn;
}

- (IBAction)contactButtonPressed:(id)sender;

@end

@implementation FundReviewingViewController

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
    self.navigationItem.title = @"Application";
    contactBtn.layer.cornerRadius = contactBtn.frame.size.height / 2;
    
    /*
    // subscribe the "ovation before" event, to update the ovation async
    [self subscribe:EVENT_GET_OVATION_REVIEW_BEFORE selector:@selector(showOvationReviewBefore)];
     
    GlowFirst *gf = [GlowFirst sharedInstance];
    if (!gf.reviewBefore) {
        // get the review before value async
        [gf getOvationReviewBefore];
    }
    */
    // show the value first, event the "ovation before" value is not correct
    // better than a white space
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [CrashReport leaveBreadcrumb:@"FundReviewingViewController"];
    [Logging log:PAGE_IMP_FUND_REVIEW];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)contactButtonPressed:(id)sender {
    [[Sendmail sharedInstance] composeTo:@[FEEDBACK_RECEIVER] subject:@"Glow First question" body:@"" inViewController:self];
}
@end

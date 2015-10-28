//
//  FundRejectedViewController.m
//  emma
//
//  Created by Jirong Wang on 5/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundRejectedViewController.h"
#import "PillGradientButton.h"
#import "Sendmail.h"
#import "Logging.h"
#import <GLFoundation/NSString+Markdown.h>

@interface FundRejectedViewController () {
    IBOutlet PillGradientButton *contactUs;
}

@property (weak, nonatomic) IBOutlet UILabel *rejectInfoText;
- (IBAction)contactPressed:(id)sender;

@end

@implementation FundRejectedViewController

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
    self.navigationItem.title = @"Glow First™";
    [contactUs setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    self.rejectInfoText.attributedText = [NSString addFont:[Utils defaultFont:15.0] toAttributed:self.rejectInfoText.attributedText];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [CrashReport leaveBreadcrumb:@"FundRejectedViewController"];
    [Logging log:PAGE_IMP_FUND_REJECT_REVIEW];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)contactPressed:(id)sender {
    [[Sendmail sharedInstance] composeTo:@[FEEDBACK_RECEIVER] subject:@"Approval rejection" body:@"" inViewController:self];
}

@end

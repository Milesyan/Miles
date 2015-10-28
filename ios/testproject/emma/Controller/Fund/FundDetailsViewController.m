//
//  FundDetailViewController.m
//  emma
//
//  Created by Jirong Wang on 11/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundDetailsViewController.h"
#import "PillGradientButton.h"
#import "WebViewController.h"
#import "Logging.h"
#import "User.h"
#import "FundHomeViewController.h"
#import <GLFoundation/NSString+Markdown.h>

#define DETAIL_APPLY_SECTION  1
#define DETAIL_GF_TOS_CELL    2

@interface FundDetailsViewController ()

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dividerViews;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *dividerLines;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *greenNumbers;
@property (weak, nonatomic) IBOutlet PillGradientButton *listClinics;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *attributedTexts;

- (IBAction)listClinicsPressed:(id)sender;
- (IBAction)applyButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@end

@implementation FundDetailsViewController

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

    // green numbers and divider view
    for (UILabel *lb in self.greenNumbers) {
        lb.layer.cornerRadius = lb.frame.size.height / 2;
    }
    for (UIView *view in self.dividerViews) {
        view.layer.cornerRadius = view.frame.size.height / 2;
    }
    for (UIView *view in self.dividerLines) {
        view.frame = setRectHeight(view.frame, 0.5);
    }
    
    // add font for the text
    for (UILabel *label in self.attributedTexts) {
        label.attributedText = [NSString addFont:[Utils defaultFont:18.0] toAttributed:label.attributedText];
    }
    
    // clinics button
    [self.listClinics setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    // navigation bar buttons
    NSInteger curStatus = [User currentUser].ovationStatus;
    if ((curStatus != OVATION_STATUS_NONE) && (curStatus != OVATION_STATUS_DEMO)) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.title = @"Applied";
    } else {
        self.navigationItem.rightBarButtonItem.title = @"Apply";
    }
    
    UIViewController * viewController = [self backViewController];
    if ((viewController) && ([viewController isKindOfClass:[FundHomeViewController class]])) {
        FundHomeViewController * fundHomeController = (FundHomeViewController *)viewController;
        if (fundHomeController.fromHelpViewController) {
            self.navigationItem.rightBarButtonItem = nil;
        }
    }

    /*  code from LearnMore page, will delete if no use in v3.0
    // gradient labels
    for (GradientLabel *l in gradientLabels) {
        [l initGradientColor:UIColorFromRGB(0x5b62d2) endColor:UIColorFromRGB(0x8578ea) direction:[GradientLabel topToBottom]];
        l.shadowColor = [UIColor whiteColor];
        l.shadowOffset = CGSizeMake(0, 1);
    }
     */
}

- (UIViewController *)backViewController {
    NSArray * stack = self.navigationController.viewControllers;
    for (NSInteger i=stack.count-1; i > 0; --i) {
        if (stack[i] == self)
            return stack[i-1];
    }
    return nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /*
    if (IOS7_OR_ABOVE) {
        [self.tableView setContentInset:UIEdgeInsetsMake(113, 0, 49, 0)];
    }
    */
    // logging
    [CrashReport leaveBreadcrumb:@"FundDetailsViewController"];
    [Logging log:PAGE_IMP_FUND_DETAILS];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)listClinicsPressed:(id)sender {
    [self.navigationController pushViewController:[UIStoryboard clinicsNearby] animated:YES from:self];
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_DETAILS_BACK];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)applyButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_DETAILS_APPLY];
    if (ENABLE_GF_ENTERPRISE)
        [self performSegueWithIdentifier:@"applyFromDetails" sender:self from:self];
    else
        [self performSegueWithIdentifier:@"personalFromDetails" sender:self from:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section == DETAIL_APPLY_SECTION) && (indexPath.row == DETAIL_GF_TOS_CELL)) {
        // open webView for TOS
        WebViewController *controller = (WebViewController *)[UIStoryboard webView];
        [self.navigationController pushViewController:controller animated:YES from:self];
        [controller openUrl:[Utils makeUrl:FUND_TOS_URL]];
    }
}

@end

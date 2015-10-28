//
//  FundPersonalApplyViewController.m
//  emma
//
//  Created by Jirong Wang on 3/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundPersonalApplyViewController.h"
#import "User.h"
#import "NSObject+PubSub.h"
#import "PillButton.h"
#import "Logging.h"
#import "WebViewController.h"
#import "UIStoryboard+Emma.h"
#import "PillFlatButton.h"
#import "Sendmail.h"
#import "FontReplaceableBarButtonItem.h"
#import "DropdownMessageController.h"
#import <CoreLocation/CoreLocation.h>
#import "NetworkLoadingView.h"
#import "TabbarController.h"
#import "StepsNavigationItem.h"

@interface FundPersonalApplyViewController () <CLLocationManagerDelegate>  {
    IBOutletCollection(PillButton) NSArray *answerButtons;
    IBOutlet UITableView *questionTable;
    IBOutlet UILabel *glowfirstTosLink;
    
    IBOutlet FontReplaceableBarButtonItem *nextButton;
    
    DropdownMessageController *msgController;
    CLLocationManager *locationManager;
    
    Sendmail *sendmail;
}

- (IBAction)backButtonPressed:(id)sender;
- (IBAction)nextButtonPressed:(id)sender;

@property (nonatomic) CGFloat webViewHeight;

@end

@implementation FundPersonalApplyViewController

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
    // self.navigationItem.title = @"Application";
    UIImageView *bg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-gray.jpeg"]];
    [questionTable setBackgroundView:bg];
    
    if (!ENABLE_GF_ENTERPRISE) {
        StepsNavigationItem * navItem = (StepsNavigationItem *)self.navigationItem;
        navItem.allSteps = @(2);
        navItem.currentStep = @(1);
        navItem.title = @"Step 1 - Complete application";
        [navItem redraw];
    }
    
    nextButton.enabled = NO;
    for (PillButton * item in answerButtons) {
        item.iconName = @"check";
        [item addTarget:self action:@selector(pillButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    // Glow First TOS link
    NSDictionary *underlineAttribute = @{NSUnderlineStyleAttributeName: @1};
    glowfirstTosLink.attributedText = [[NSAttributedString alloc] initWithString:glowfirstTosLink.text attributes:underlineAttribute];
    glowfirstTosLink.userInteractionEnabled = YES;
    UITapGestureRecognizer *reg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tosLinkPressed:)];
    [reg setNumberOfTapsRequired:1];
    [glowfirstTosLink addGestureRecognizer:reg];
    
    // location manager
    msgController = [DropdownMessageController sharedInstance];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    
    sendmail = [[Sendmail alloc] init];
    sendmail.addUserInfo = YES;
    
    [self.tableView setContentInset:UIEdgeInsetsMake(-350, 0, 49, 0)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [CrashReport leaveBreadcrumb:@"FundPersonalApplyViewController"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_PERSONAL_APPLY_BACK];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (void)pillButtonPressed:(id)sender {
    BOOL allSelected = YES;
    for (PillButton *item in answerButtons) {
        if (!item.selected) {
            allSelected = NO;
            break;
        }
    }
    nextButton.enabled = allSelected;
}

- (void)tosLinkPressed:(id)sender {
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    [self.navigationController pushViewController:controller animated:YES from:self];
    [controller openUrl:[Utils makeUrl:FUND_TOS_URL]];
}

#pragma mark - NextButtonPressed
/* I add this value because locationManager:didUpdateLocations always be called multiple times.  */
static BOOL locationUpdated = NO;

- (IBAction)nextButtonPressed:(id)sender {
    // logging    
    [Logging log:BTN_CLK_FUND_PERSONAL_APPLY_NEXT];
    if (![CLLocationManager locationServicesEnabled]) {
        [[[UIAlertView alloc] initWithTitle:@"Applying Glow First requires your location" message:@"Please enable location service in Settings->Privacy->Location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
        [[[UIAlertView alloc] initWithTitle:@"Applying Glow First requires your location" message:@"Please authorize Glow to access your location in Settings->Privacy->Location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        GLLog(@"start updating location");
        locationUpdated = NO;
        if (IOS8_OR_ABOVE) {
            [locationManager requestWhenInUseAuthorization];
        }
        [locationManager startUpdatingLocation];
        // applyButton.enabled = NO;
        [NetworkLoadingView show];
        // [msgController postMessage:@"Getting your location." duration:3 inView:self.view];
        [self performSelector:@selector(locationServiceTimeout) withObject:nil afterDelay:20];
    }
}

- (void)locationServiceTimeout {
    [msgController postMessage:@"Getting location timeout." duration:3 inView:self.view];
    // applyButton.enabled = YES;
    [NetworkLoadingView hide];
    [locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if (locationUpdated)
        return;
    locationUpdated = YES;
    
    [User currentUser].currentLocation = (CLLocation *)locations.lastObject;
    GLLog(@"located: %@", [User currentUser].currentLocation);
    [locationManager stopUpdatingLocation];
    [NetworkLoadingView hide];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationServiceTimeout) object:nil];
    
    int curStatus = [User currentUser].ovationStatus;
    if ((curStatus == OVATION_STATUS_NONE) || (curStatus == OVATION_STATUS_DEMO)) {
        [self performSegueWithIdentifier:@"goPersonalPayment" sender:self from:self];
    } else {
        [[TabbarController getInstance:self] rePerformFundSegue];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    GLLog(@"error: %@", error);
    /*
     * Get location fails
     *   restore done button, hide networking view
     */
    if ([error domain] == kCLErrorDomain) {
        switch ([error code]) {
            case kCLErrorDenied:
                [[[UIAlertView alloc] initWithTitle:@"Applying Glow First requires your location" message:@"Please authorize Glow to access your location in Settings->Privacy->Location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                break;
                
            default:
                [[[UIAlertView alloc] initWithTitle:@"Error happens when getting your location" message:@"Please authorize Glow to access your location in Settings->Privacy->Location." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
                break;
        }
    }
    // applyButton.enabled = YES;
    [NetworkLoadingView hide];
    [locationManager stopUpdatingLocation];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(locationServiceTimeout) object:nil];
}

@end

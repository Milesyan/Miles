//
//  AskLocationDialog.m
//  emma
//
//  Created by Peng Gu on 12/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "AskLocationDialog.h"
#import <GLDialogViewController.h>
#import <CoreLocation/CoreLocation.h>
#import "User.h"
#import "GLLocationManager.h"

@interface AskLocationDialog()

@property (nonatomic, weak) GLDialogViewController *dialogViewController;
@property (nonatomic, weak) IBOutlet UIButton *sureButton;
@property (nonatomic, weak) IBOutlet UIButton *laterButton;
@property (nonatomic, strong) GLLocationManager *locationManager;

@property (nonatomic, assign) BOOL hasFetchedLocation;

@end


@implementation AskLocationDialog


- (instancetype)init
{
    return [super initWithNibName:@"AskLocationDialog" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sureButton.layer.cornerRadius = self.sureButton.height / 2;
//    self.sureButton.layer.borderWidth = 1;
    
    NSMutableAttributedString *text = [self.laterButton.titleLabel.attributedText mutableCopy];
    [text addAttribute:NSUnderlineStyleAttributeName
                 value:[NSNumber numberWithInteger:NSUnderlineStyleSingle]
                 range:NSMakeRange(0, text.length)];
    
    [self.laterButton setAttributedTitle:text forState:UIControlStateNormal];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_ASK_LOCATION_DIALOG];
}

- (IBAction)sureButtonClicked:(id)sender {
    // 0 not asked,  1 yes,  2 no
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ASK_LOCATION withValue:@(1)];
    [Logging log:BTN_CLK_ASK_LOCATION_OK];
    
    if (!self.locationManager) {
        self.locationManager = [[GLLocationManager alloc] init];
    }
    
    @weakify(self)
    [self.locationManager startUpdatingLocation:^(NSString * str) {
        @strongify(self)
        [self.dialogViewController close];
    } failCallback:^() {
        @strongify(self)
        [self.dialogViewController close];
        // [self presentErrorAlert];
    }];
}

- (IBAction)laterButtonClicked:(id)sender
{
    // 0 not asked,  1 yes,  2 no
    // [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ASK_LOCATION withValue:@(2)];
    
    [Logging log:BTN_CLK_ASK_LOCATION_LATER];
    [self.dialogViewController close];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    // for later button and X button, we set the default key be 2
    NSNumber * d = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_ASK_LOCATION];
    if (d) {
        if ([d intValue] == 1) {
            return;
        }
    }
    // 0 not asked,  1 yes,  2 no
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ASK_LOCATION withValue:@(2)];
}

- (void)presentErrorAlert
{
    NSString *msg = @"Unable to retrieve current location, please check your network and location service setting.";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Error"
                                                    message:msg
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


- (void)present
{
    if (![CLLocationManager locationServicesEnabled]) {
        return;
    }
    
    self.dialogViewController = [GLDialogViewController sharedInstance];
    [self.dialogViewController presentWithContentController:self];
}


@end

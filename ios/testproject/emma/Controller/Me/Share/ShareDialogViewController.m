//
//  ShareDialogViewController.m
//  emma
//
//  Created by Peng Gu on 8/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ShareDialogViewController.h"
#import "GLDialogViewController.h"
#import "PillGradientButton.h"
#import "AskRateDialog.h"
#import "Logging.h"
#import "User.h"
#import "ShareController.h"
#import "SendFBRequest.h"

#define DEFAULT_SHARE_LINK @"https://glowing.com/features"

@interface ShareDialogViewController ()

@property (nonatomic, weak) IBOutlet PillGradientButton *rateButton;
@property (nonatomic, copy) NSString *facebookShareLink;

- (IBAction)facebookShare:(id)sender;
- (IBAction)emailShare:(id)sender;
- (IBAction)smsShare:(id)sender;
- (IBAction)rateGlow:(id)sender;

@end


@implementation ShareDialogViewController


- (instancetype)initFromNib
{
    return [self initWithNibName:@"ShareDialogViewController" bundle:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.rateButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    self.rateButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}


- (void)present
{
    [[GLDialogViewController sharedInstance] presentWithContentController:self];
    
    User *user = [User currentUser];
    [user.settings update:@"hasSeenShareDialog" value:@(YES)];
    [user save];
}


#pragma mark - IBActions
- (void)facebookShare:(id)sender
{
    [Logging log:BTN_CLK_DIALOG_SHARE_BUTTON eventData:@{@"button_name":@"fb"}];
    
    NSString * url = (self.facebookShareLink) ? self.facebookShareLink : DEFAULT_SHARE_LINK;
    [SendFBRequest requestWithTitle:@"Glow" andMessage:[NSString stringWithFormat:@"Check out Glow, THE women's health app for cycle-tracking, personalized health tips, and even help with trying to conceive. Get it here: %@", url]];
    [self saveSharedState];
}


- (void)emailShare:(id)sender
{
    [Logging log:BTN_CLK_DIALOG_SHARE_BUTTON eventData:@{@"button_name":@"email"}];
    
    [ShareController presentWithShareType:self.shareType shareItem:nil fromViewController:self];
    
    [self saveSharedState];
}


- (void)smsShare:(id)sender
{
    [Logging log:BTN_CLK_DIALOG_SHARE_BUTTON eventData:@{@"button_name":@"sms"}];
    
    [ShareController presentWithShareType:self.shareType shareItem:nil fromViewController:self];
    
    [self saveSharedState];
}


- (void)rateGlow:(id)sender
{
    [Logging log:BTN_CLK_SHARE_DIALOG_RATE];
    [[AskRateDialog getInstance] goToRatePage];
}


#pragma mark - State
- (void)saveSharedState
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:@"hasClickedShareButton"];
    [defaults synchronize];
}


+ (BOOL)alreadyShared
{
    if ([User currentUser].isSecondaryOrSingleMale) {
        return NO;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:@"hasClickedShareButton"];
}


@end









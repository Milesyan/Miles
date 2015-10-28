//
//  AskRateDialog.m
//  emma
//
//  Created by Jirong Wang on 4/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AskRateDialog.h"
#import "GLDialogViewController.h"
#import "User.h"
#import "Logging.h"
#import "AppDelegate.h"

@implementation AskRateDialog

static AskRateDialog *_instance = nil;

+ (AskRateDialog *)getInstance {
    if (!_instance) {
        _instance = [[AskRateDialog alloc] init];
        [_instance subscribe:EVENT_OPEN_RATE_DIALOG selector:@selector(openRateDialog:)];
    }
    return _instance;
}

- (void)openRateDialog:(Event *) event {
    // check if an dialog is opened
    if ([GLDialogViewController sharedInstance].isOpened) {
        return;
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Rate Glow" message:@"Would you like to leave a rating?      It would be very helpful for us!" delegate:self cancelButtonTitle:@"No, Thanks" otherButtonTitles:@"Rate It Now", @"Remind Me in 1 Week", nil];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) pushDialog:alert];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *neverRemind = [Utils dateOfYear:2999 month:12 day:31];
    switch (buttonIndex) {
        case 0:
            // No, Thanks = 0
            // set the remind Time to 2999.12.31
            [defaults setObject:neverRemind forKey:@"remindRateTime"];
            [defaults synchronize];
            [Logging syncLog:BTN_CLK_HOME_ASK_RATE eventData:@{@"click_type": RATE_CLICK_TYPE_NO}];
            break;
            
        case 1:
            // Rate now = 1
            // set the remind Time to 2999.12.31
            [defaults setObject:neverRemind forKey:@"remindRateTime"];
            [defaults synchronize];
            [Logging syncLog:BTN_CLK_HOME_ASK_RATE eventData:@{@"click_type": RATE_CLICK_TYPE_RATE}];
            // to go app store review page
            [self goToRatePage];
            break;
            
        case 2:
            // Remind in 1 week = 2
            [defaults setObject:[NSDate dateWithTimeIntervalSinceNow:REMIND_RATE_DELAY] forKey:@"remindRateTime"];
            [defaults synchronize];
            [Logging syncLog:BTN_CLK_HOME_ASK_RATE eventData:@{@"click_type": RATE_CLICK_TYPE_DELAY}];
            break;
            
        default:
            break;
    }
}

- (void)goToRatePage {
    NSString * url = [NSString stringWithFormat:@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=%@&type=Purple+Software", APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}

@end

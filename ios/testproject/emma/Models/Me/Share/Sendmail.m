//
//  Sendmail.m
//  emma
//
//  Created by Ryan Ye on 6/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIDeviceUtil/UIDeviceUtil.h>
#import "Sendmail.h"
#import "StatusBarOverlay.h"
#import "User+Misc.h"

static MFMailComposeViewController* composeViewController;

@interface Sendmail()
{
    SendEmailCallback cb;
}

@end

@implementation Sendmail

+ (void)prepare {
    if (!composeViewController) {
        composeViewController = [[MFMailComposeViewController alloc] init];
    }
}

+ (Sendmail *)sharedInstance
{
    static Sendmail* _inst;
    if (!_inst) {
        _inst = [[Sendmail alloc] init];
        _inst.addUserInfo = YES;
    }
    
    return _inst;
}

- (void)composeTo:(NSArray *)receivers subject:(NSString *)subject body:(NSString *)body inViewController:(UIViewController *)controller withCallback:(SendEmailCallback)callback {
    cb = callback;
    [self composeTo:receivers subject:subject body:body inViewController:controller];
}

- (void)composeTo:(NSArray *)receivers subject:(NSString *)subject body:(NSString *)body inViewController:(UIViewController *)controller{
    parentViewController = controller;
    [Sendmail prepare];
    composeViewController.mailComposeDelegate = self;
    [composeViewController setToRecipients:receivers];
    if (self.addUserInfo) {
        UIDevice *device = [UIDevice currentDevice];
        User *user = [User currentUser];
        NSString *appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        NSString *userInfoMsg = [NSString stringWithFormat:@"\n\n**My account is %@. I'm using Glow %@ on %@ (iOS %@).**", user.email, appVersion, [UIDeviceUtil hardwareDescription], [device systemVersion]];
        body = [NSString stringWithFormat:@"%@%@", body, userInfoMsg];
    }
    [composeViewController setMessageBody:body isHTML:YES];
    [composeViewController setSubject:subject];

    if (composeViewController && [MFMailComposeViewController canSendMail]) {
        [parentViewController presentViewController:composeViewController animated:YES completion:nil];
    }
}


- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error{
    BOOL success = NO;
    if (result == MFMailComposeResultSent) {
        success = YES;
    }

    if (cb) {
        cb(success);
    } else {
        if (success) {
            [[StatusBarOverlay sharedInstance] postMessage:@"Thank you for your feedback!" duration:3];
        }
    }

    [parentViewController dismissViewControllerAnimated:YES completion:nil];
    parentViewController = nil;
    composeViewController = nil;
}
@end

//
//  SendSMS.m
//  emma
//
//  Created by Eric Xu on 10/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "SendSMS.h"
#import "StatusBarOverlay.h"
#import <MessageUI/MFMessageComposeViewController.h>

@interface SendSMS()
{
    SendSMSCallback cb;
}

@end

static MFMessageComposeViewController* composeViewController;
@implementation SendSMS

+ (void)prepare {
    if (!composeViewController) {
        composeViewController = [[MFMessageComposeViewController alloc] init];
    }
}

+ (SendSMS *)sharedInstance;
{
    static SendSMS* _inst;
    if (!_inst) {
        _inst = [[SendSMS alloc] init];
    }
    return _inst;
}

- (void)composeTo:(NSArray *)receivers body:(NSString *)body inViewController:(UIViewController *)controller withCallback:(SendSMSCallback)callback {
    cb = callback;
    [self composeTo:receivers body:body inViewController:controller];
}

- (void)composeTo:(NSArray *)receivers body:(NSString *)body inViewController:(UIViewController *)controller{
    parentViewController = controller;
    
    [SendSMS prepare];
    composeViewController.messageComposeDelegate = self;
    [composeViewController setRecipients:receivers];
    [composeViewController setBody:body];
    
    if (composeViewController && [MFMessageComposeViewController canSendText]) {
        [controller presentViewController:composeViewController animated:YES completion:nil];
    }
}

#pragma mark - MFMessageControllerDelegate
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    BOOL success = NO;
    switch (result) {
        case MessageComposeResultSent: {
            [[StatusBarOverlay sharedInstance] postMessage:@"Message sent!" duration:3];
            success = YES;
        }
            break;
        case MessageComposeResultCancelled:
            break;
        
        case MessageComposeResultFailed:
            [[StatusBarOverlay sharedInstance] postMessage:@"Failed sending message!" duration:3];
        default:
            break;
    }

    if (cb) {
        cb(success);
    }
    
    [parentViewController dismissViewControllerAnimated:YES completion:nil];
    parentViewController = nil;
    composeViewController = nil;
}

@end

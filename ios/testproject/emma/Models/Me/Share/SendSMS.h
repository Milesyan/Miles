//
//  SendSMS.h
//  emma
//
//  Created by Eric Xu on 10/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMessageComposeViewController.h>

typedef void(^SendSMSCallback)(BOOL success);

@interface SendSMS : NSObject <MFMessageComposeViewControllerDelegate>{
    UIViewController *parentViewController;
}

- (void)composeTo:(NSArray *)receivers body:(NSString *)body inViewController:(UIViewController *)controller withCallback:(SendSMSCallback)callback;
- (void)composeTo:(NSArray *)receivers body:(NSString *)body inViewController:(UIViewController *)controller;
+ (void)prepare;
+ (SendSMS *)sharedInstance;

@end

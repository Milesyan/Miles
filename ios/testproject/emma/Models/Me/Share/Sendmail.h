//
//  Sendmail.h
//  emma
//
//  Created by Ryan Ye on 6/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MessageUI/MFMailComposeViewController.h>

typedef void(^SendEmailCallback)(BOOL success);

@interface Sendmail : NSObject<MFMailComposeViewControllerDelegate> {
//    MFMailComposeViewController* composeViewController;
    UIViewController *parentViewController;
}
@property (nonatomic) BOOL addUserInfo;
- (void)composeTo:(NSArray *)receivers subject:(NSString *)subject body:(NSString *)body inViewController:(UIViewController *)controller;
- (void)composeTo:(NSArray *)receivers subject:(NSString *)subject body:(NSString *)body inViewController:(UIViewController *)controller withCallback:(SendEmailCallback)callback;
+ (Sendmail *)sharedInstance;
+ (void)prepare;
@end

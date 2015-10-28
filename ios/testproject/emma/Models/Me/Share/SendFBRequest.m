//
//  SendFBRequest.m
//  emma
//
//  Created by Eric Xu on 10/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "SendFBRequest.h"
#import <FacebookSDK/FacebookSDK.h>
#import "User.h"
#import "StatusBarOverlay.h"

@implementation SendFBRequest
+ (void)requestWithTitle:(NSString *)title andMessage:(NSString *)message {
    [SendFBRequest requestWithTitle:title andMessage:message withCallback:nil];
}

+ (void)requestWithTitle:(NSString *)title andMessage:(NSString *)message withCallback:(SendFBCallback)callback {
    NSString *fbRequestTitle = title? title: @"Invite friends to Glow!";
    NSString *fbRequestMessage = message? message: @"Recommend Glow for trying to conceive!";
    
    [FBWebDialogs presentRequestsDialogModallyWithSession:[User session]
                                                  message:fbRequestMessage
                                                    title:fbRequestTitle
                                               parameters:nil
                                                  handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *fbErr) {
                                                      if (result == FBWebDialogResultDialogCompleted && !fbErr) {
                                                          NSArray *sentUserIDs = [self retrieveSentFacebookUserIDsFromResultURL:resultURL];
                                                          if (sentUserIDs && sentUserIDs.count > 0) {
                                                              [[StatusBarOverlay sharedInstance] postMessage:@"Request sent!" duration:3];
                                                          }
                                                          
                                                          if (callback) {
                                                              callback(YES, sentUserIDs);
                                                          }
                                                          
                                                          return;
                                                      }
                                                      
                                                      if (fbErr) {
                                                          [[StatusBarOverlay sharedInstance] postMessage:@"Request failed!" duration:3];
                                                      }
                                                      
                                                      if (callback) {
                                                          callback(NO, nil);
                                                      }
                                                  }];
}

+ (NSArray *)retrieveSentFacebookUserIDsFromResultURL:(NSURL *)resultURL
{
    NSString *regexPattern = @"&to%5B\\d+%5D=";
    NSString *seperator = @"[GlowSeperatorString]";
    NSString *idString = [resultURL.absoluteString stringByReplacingOccurrencesOfString:regexPattern withString:seperator options:NSRegularExpressionSearch range:NSMakeRange(0, resultURL.absoluteString.length)];
    NSArray *ids = [idString componentsSeparatedByString:seperator];
    return [ids subarrayWithRange:NSMakeRange(1, ids.count-1)];
}

@end

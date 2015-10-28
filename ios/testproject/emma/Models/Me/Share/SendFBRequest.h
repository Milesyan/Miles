//
//  SendFBRequest.h
//  emma
//
//  Created by Eric Xu on 10/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SendFBCallback)(BOOL success, NSArray *sentFacebookUserIDs);

@interface SendFBRequest : NSObject

+ (void)requestWithTitle:(NSString *)title andMessage:(NSString *)message;
+ (void)requestWithTitle:(NSString *)title andMessage:(NSString *)message withCallback:(SendFBCallback)callback;

@end

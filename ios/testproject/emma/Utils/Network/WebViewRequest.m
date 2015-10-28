//
//  WebViewRequest.m
//  emma
//
//  Created by ltebean on 15-2-4.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "WebViewRequest.h"
#import "User.h"

@implementation WebViewRequest

+ (NSURLRequest *)requestWithPath:(NSString *)path
{
    [NSHTTPCookieStorage sharedHTTPCookieStorage].cookieAcceptPolicy = NSHTTPCookieAcceptPolicyAlways;

    NSString *urlStr = [NSString stringWithFormat:@"%@/%@", EMMA_BASE_URL, path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    User *user = [User currentUser];
    
    NSDictionary *data = @{
                           @"ut":user.encryptedToken,
                           @"app_version":[Utils appVersion],
                           @"device_id":[Utils UUID],
                           @"locale":[Utils localeString],
                           @"model":[Utils modelString]
                           };

    NSData *body = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:nil];
    [request setHTTPBody:body];
    return request;
}

@end

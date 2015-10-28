//
//  OAuth1_0.h
//  emma
//
//  Created by Eric Xu on 3/7/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network.h"

@interface OAuth1_0 : NSObject {
    NSURL *url;
    NSString *signature_secret;
    NSDictionary *params; // these are pre-percent encoded
    NSString *method;
}


- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret accessToken:(NSString *)accessToken tokenSecret:(NSString *)tokenSecret;

+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPathWithoutQuery
                      GETParameters:(NSDictionary *)unencodedParameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;
+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPath
                     POSTParameters:(NSDictionary *)unencodedParameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;
@end

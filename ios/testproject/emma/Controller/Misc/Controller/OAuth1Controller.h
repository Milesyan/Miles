//
//  OAuth1Controller.h
//  emma
//
//  Created by Eric Xu on 3/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^AuthenticateCallback)(NSDictionary *ret, NSError *error);
typedef void(^GetCallback)(NSDictionary *ret, NSError *error);

@interface OAuth1Controller : UIViewController <UIWebViewDelegate>

+ (OAuth1Controller *)sharedInstance;
+ (void)authWithConsumerKey:(NSString *)consumerKey
             consumerSecret:(NSString *)consumerSecret
                    authUrl:(NSString *)authUrl
           requestTokenPath:(NSString *)requestTokenPath
           authenticatePath:(NSString *)authenticatePath
            accessTokenPath:(NSString *)accessTokenPath
                callbackURL:(NSString *)callbackUrl
           andCallbackBlock:(AuthenticateCallback)callback;
+ (void)getFromAPIUrl:(NSString *)apiUrl
                 path:(NSString *)path
           parameters:(NSDictionary *)parameters
      WithConsumerKey:(NSString *)consumerKey
       consumerSecret:(NSString *)consumerSecret
           oauthToken:(NSString *)oauthToken
          oauthSecret:(NSString *)oauthSecret
          andCallback:(GetCallback)getCallback;
@end

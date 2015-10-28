//
//  WalgreensManager.h
//  emma
//
//  Created by Jirong Wang on 12/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Network.h"

@interface WalgreensManager : NSObject

+ (WalgreensManager *)getInstance;
// + (NSDictionary *)getLandingURL;
+ (void)getLandingURL:(JSONResponseHandler)callback;
+ (NSURLRequest *)getRefillRequest:(NSString *)rxNumber;
+ (BOOL)handleWalgreenRefill:(NSURL *)url;
+ (BOOL)isValidRxNumber:(NSString *)rxNumber;

@end

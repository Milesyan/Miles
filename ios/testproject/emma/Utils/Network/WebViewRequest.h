//
//  WebViewRequest.h
//  emma
//
//  Created by ltebean on 15-2-4.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WebViewRequest : NSObject
+ (NSURLRequest *)requestWithPath:(NSString *)path;
@end

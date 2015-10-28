//
//  GLWebViewBridge.h
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLWebViewBridge : NSObject
+ (GLWebViewBridge *)bridgeForWebView:(UIWebView *)webView params:(NSDictionary *)params dataHandler:(void (^)(id))handler;
- (void)sendData:(id)data;
@end

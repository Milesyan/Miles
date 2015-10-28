//
//  GLWebViewBridge.m
//  emma
//
//  Created by ltebean on 15-2-3.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "GLWebViewBridge.h"
#import "WebViewJavascriptBridge.h"

@interface GLWebViewBridge ()
@property(nonatomic,strong) NSDictionary *params;
@property(nonatomic,strong) WebViewJavascriptBridge *bridge;
@end

@implementation GLWebViewBridge

+ (GLWebViewBridge *)bridgeForWebView:(UIWebView *)webView params:(NSDictionary *)params dataHandler:(void(^)(id))handler;
{
    return [[GLWebViewBridge alloc]initWithWebView:webView params:params handler:handler];
}

- (id)initWithWebView:(UIWebView *)webView params:(NSDictionary*)params handler:(void (^)(id))handler
{
    if (self = [super init]) {
        self.params = params;
        self.bridge = [WebViewJavascriptBridge bridgeForWebView:webView handler:^(id data, WVJBResponseCallback responseCallback) {
            handler(data);
        }];
        
        //[WebViewJavascriptBridge enableLogging];
        
        [self.bridge registerHandler:@"userdefaults:set" handler:^(id data, WVJBResponseCallback responseCallback){
            [[NSUserDefaults standardUserDefaults] setObject:data[@"value"] forKey:data[@"key"]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            responseCallback(@200);
        }];
        
        [self.bridge registerHandler:@"userdefaults:get" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback([[NSUserDefaults standardUserDefaults] objectForKey:data]);
        }];
        
        [self.bridge registerHandler:@"param:get" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback(self.params[data]);
        }];
        
        [self.bridge registerHandler:@"param:getAll" handler:^(id data, WVJBResponseCallback responseCallback){
            responseCallback(self.params);
        }];
        
        [self.bridge registerHandler:@"url:open" handler:^(id data, WVJBResponseCallback responseCallback){
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:data]];
        }];
    }
    return self;
}

-(void) sendData:(id) data
{
    [self.bridge send:data];
}

@end

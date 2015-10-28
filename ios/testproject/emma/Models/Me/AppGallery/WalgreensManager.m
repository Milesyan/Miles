//
//  WalgreensManager.m
//  emma
//
//  Created by Jirong Wang on 12/24/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIDeviceUtil/UIDeviceUtil.h>
#import "WalgreensManager.h"
#import "User.h"

@interface WalgreensManager()


@property (nonatomic) NSString * landingURL;
@property (nonatomic) NSString * accessToken;
@property (nonatomic) NSString * walgreensTemplate;
@property (nonatomic) NSDate * lastSyncTime;
// @property (nonatomic) int tryAgainCount;

@end

@implementation WalgreensManager

static WalgreensManager * _instance;
+ (WalgreensManager *)getInstance {
    if (!_instance) {
        _instance = [[WalgreensManager alloc] init];
        _instance.landingURL = nil;
        _instance.accessToken = nil;
        _instance.walgreensTemplate = nil;
        _instance.lastSyncTime = nil;
        // _instance.tryAgainCount = 0;
    }
    return _instance;
}

+ (NSString *)deviceInfo {
    return [UIDeviceUtil hardwareString];
}

+ (void)getLandingURL:(JSONResponseHandler)callback {
    WalgreensManager * wlg = [WalgreensManager getInstance];
    if ((wlg.lastSyncTime) && ([[NSDate date] timeIntervalSinceDate:wlg.lastSyncTime] <= 3600)) {
        // if we synced to walgreen in 1 hour
        if (wlg.accessToken && wlg.landingURL) {
            callback(@{
                @"accessToken":wlg.accessToken,
                @"landingURL": wlg.landingURL,
                @"template":   wlg.walgreensTemplate
            }, nil);
            return;
        }
    }
    
    // repair request data
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:WALGREENS_GET_LANDING_URL]];
    [request setHTTPMethod:@"POST"];
    [request setTimeoutInterval:NETWORK_MULTIPART_TIMEOUT];
    
    NSDictionary * requestBody = @{
        @"transaction": @"refillByScan",
        @"apiKey": WALGREENS_API_KEY,
        @"devinf": [WalgreensManager deviceInfo],
        @"act":    @"mweb5Url",
        @"view":   @"mweb5UrlJSON",
        @"affId":  WALGREENS_API_AFF_ID,
        @"appver": [Utils appVersion]
        };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:nil];
    [request setHTTPBody:requestData];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            callback(nil, error);
        } else {
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeErr];
            if (result) {
                NSString * accessToken = [result objectForKey:@"token"];
                NSString * landingURL  = [result objectForKey:@"landingUrl"];
                NSString * walgreensTemplate = [result objectForKey:@"template"];
                if (accessToken && landingURL) {
                    wlg.accessToken = accessToken;
                    wlg.landingURL  = landingURL;
                    wlg.walgreensTemplate = walgreensTemplate;
                    wlg.lastSyncTime = [NSDate date];
                }
            }
            callback(result, decodeErr);
        }
    }];
}

+ (NSURLRequest *)getRefillRequest:(NSString *)rxNumber {
    WalgreensManager * wlg = [WalgreensManager getInstance];

    NSString * trackingId = [NSString stringWithFormat:@"glow_tracking_%@_%@", [User currentUser].encryptedToken, @([[NSDate date] timeIntervalSince1970])];
    // the url that walgreen called us is
    // glow://handleWalgreensRefill?callBackAction=xx
    // xx in ["cancel", "back", "close", "fillAnother", "refillTryAgain"]
    NSString * scheme = [NSString stringWithFormat:@"%@://handleWalgreensRefill", EMMA_URL_SCHEME];
    
    // walgreens template
    NSString * template = wlg.walgreensTemplate;
    if (!template) {
        template = @"glw";
    }

    NSDictionary * requestBody = @{
        @"appId":             @"refillByScan",
        @"affId":             WALGREENS_API_AFF_ID,
        @"token":             wlg.accessToken,
        @"template":          template,
        @"rxNo":              [self rxNumberWithDash:rxNumber],
        @"appCallBackScheme": scheme,
        @"appCallBackAction": @"callBackAction",
        @"act":               @"chkExpRx",
        @"trackingId":        trackingId,
        @"devinf":            [WalgreensManager deviceInfo],
        @"appver":            [Utils appVersion]
    };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestBody options:0 error:nil];
    //URL Requst Object
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:wlg.landingURL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    
    return request;
}

+ (BOOL)handleWalgreenRefill:(NSURL *)url {
    /*
     * The url that walgreen called us is
     *    glow://handleWalgreensRefill?callBackAction=xx
     *
     * Walgreen pages.
     * 
     * Page 1 , 3 buttons
     *   back    -> back to our app, send callBackAction=back
     *   cancel  -> back to our app, send callBackAction=cancel
     *   submit  -> no action to our app, goes page 2
     *
     * Page 2,  2 buttons
     *   refill  -> back to our app, send callBackAction=fillAnother
     *   done    -> back to our app, send callBackAction=close
     */
    NSString * urlQuery = [url query];
    WalgreensManager * wlg = [WalgreensManager getInstance];
    if ([urlQuery hasPrefix:@"callBackAction="]) {
        NSString * action = [urlQuery substringFromIndex:15];
        
        if ([action isEqualToString:@"back"]) {
            // only close the web view controller
            [Logging log:USER_WALGREENS_ACTION eventData:@{@"action": WALGREENS_ACTION_BACK}];
            [wlg publish:EVENT_WALGREENS_CALLBACK_CLOSE];
        } else if ([action isEqualToString:@"cancel"]) {
            // success, close the web view controller
            [Logging log:USER_WALGREENS_ACTION eventData:@{@"action": WALGREENS_ACTION_CANCEL}];
            [wlg publish:EVENT_WALGREENS_CALLBACK_CLOSE];
        } else if ([action isEqualToString:@"close"]) {
            // only close the web view controller
            [Logging log:USER_WALGREENS_ACTION eventData:@{@"action": WALGREENS_ACTION_CLOSE}];
            [wlg publish:EVENT_WALGREENS_CALLBACK_CLOSE];
        } else if ([action isEqualToString:@"fillAnother"]) {
            // close the web view controller, reopen "scan"
            [Logging log:USER_WALGREENS_ACTION eventData:@{@"action": WALGREENS_ACTION_FILL_ANOTHER}];
            [wlg publish:EVENT_WALGREENS_CALLBACK_REFILL];
        } else if ([action isEqualToString:@"refillTryAgain"]) {
            // close the web view controller, reopen "scan"
            [Logging log:USER_WALGREENS_ACTION eventData:@{@"action": WALGREENS_ACTION_TRY_AGAIN}];
            [wlg publish:EVENT_WALGREENS_CALLBACK_TRY_AGAIN];
        }
        return YES;
    }
    return NO;
}

+ (BOOL)isValidRxNumber:(NSString *)rxNumber
{
    if (rxNumber.length != 12){
        return NO;
    }
    NSCharacterSet *numbersSet = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *stringSet = [NSCharacterSet characterSetWithCharactersInString:rxNumber];
    return [numbersSet isSupersetOfSet:stringSet];
}

+ (NSString *)rxNumberWithDash:(NSString *)rxNumber
{
    NSMutableString *number = [NSMutableString stringWithString:rxNumber];
    [number insertString:@"-" atIndex:7];
    return number;
}


@end

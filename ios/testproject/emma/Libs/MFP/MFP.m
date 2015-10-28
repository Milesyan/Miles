/* -*- mode: objc; tab-width: 2; tab-always-indent: t; basic-offset: 2; comment-column: 0 -*-
   Copyright (c) 2012 MyFitnessPal, LLC. All rights reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/


#import "MFP.h"
#import "MFPRequestDelegate.h"
#import <UIKit/UIKit.h>


static NSString *APIRoot = @"https://api.myfitnesspal.com";
static NSString *MFPRoot = @"https://www.myfitnesspal.com";


// make the urls localizable
static NSString *MFPAppiTunesURLString = @"http://itunes.apple.com/us/app/calorie-counter-diet-tracker/id341232718?mt=8&uo=4";
static NSString *MFPiPadAppiTunesURLString = @"http://itunes.apple.com/us/app/calorie-counter-diet-tracker/id488519281?mt=8&uo=4";
static NSString *MFPHost = @"mfp";
static NSString *MFPRedirectURIPath = @"/authorize/response";
static NSString *MFPOpenAppPath = @"/open";


@interface MFP () <NSURLConnectionDelegate>

@property (nonatomic, copy) NSString *clientId;
@property (nonatomic, strong) NSURLConnection *connection;

@property (nonatomic, strong) MFPCallback successCallback;
@property (nonatomic, strong) MFPCallback failureCallback;

@end



@implementation MFP

+ (MFPAppType)availableMFPApps {
  MFPAppType apps = 0;
  @synchronized (self) {
      @autoreleasepool {
        UIApplication *app = [UIApplication sharedApplication];
        if ([app canOpenURL:[NSURL URLWithString:@"mfphd://oauth2/authorize"]])
          apps |= MFPiPadApp;
        if ([app canOpenURL:[NSURL URLWithString:@"mfp://oauth2/authorize"]])
          apps |= MFPiPhoneApp;
      }
  }
  return apps;
}



+ (NSString *)versionString {
  return @"1.1.1";
}



- (id)initWithClientId:(NSString *)clientId
          responseType:(NSString *)responseType
              delegate:(id <MFPDelegate>)delegate {
  return [self initWithClientId:clientId
                   responseType:responseType
                       delegate:delegate
                urlSchemeSuffix:nil];
}


- (id)initWithClientId:(NSString *)clientId
          responseType:(NSString *)responseType
              delegate:(id <MFPDelegate>)delegate
       urlSchemeSuffix:(NSString *)urlSchemeSuffix {
  self = [super init];

  if (self) {
    _clientId = [clientId copy];
    _responseType = [responseType copy];
    _delegate = delegate;
    if (urlSchemeSuffix)
      _urlSchemeSuffix = [urlSchemeSuffix copy];
    else
      _urlSchemeSuffix = @"";
  }

  return self;
}



- (BOOL)handleOpenURL:(NSURL *)url {
  if ([[url scheme] caseInsensitiveCompare:[self scheme]] != NSOrderedSame)
    return NO;

  NSString *path = [url path];
  if ([path isEqualToString:MFPOpenAppPath]) {
    [_delegate MFPDidOpenApplication:self];
    return YES;
  }

  if ([path isEqualToString:MFPRedirectURIPath]) {
    NSDictionary *params =  [self queryStringToDictionary:[url query]];
    [self handleAuthorizationResponse:params];
    return YES;
  }

  return NO;
}



- (void)handleAuthorizationResponse:(NSDictionary *)response {
  if ([response objectForKey:@"error"]) {
    if ([_delegate respondsToSelector:@selector(MFP:failedToAuthorize:)])
      [_delegate MFP:self failedToAuthorize:response];

    if (_failureCallback) {
      _failureCallback(response);
      _failureCallback = nil;
    }
    return;
  }

  if ([_delegate respondsToSelector:@selector(MFP:didAuthorize:)])
    [_delegate MFP:self didAuthorize:response];

  if (_successCallback) {
    _successCallback(response);
    _successCallback = nil;
  }

}


- (void)authorizeWithScope:(NSString *)scope {
  [self authorizeWithScope:scope onSuccess:nil onFailure:nil];
}

- (BOOL)appIsInstalled {
  @autoreleasepool {
    MFPAppType apps = [MFP availableMFPApps];
    if (apps & MFPiPadApp || apps & MFPiPhoneApp)
      return YES;
  }
  return NO;
}


- (void)installApp {
  if ([self appIsInstalled])
    return;
  
  @autoreleasepool {
    UIApplication *app = [UIApplication sharedApplication];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
      [app openURL:[NSURL URLWithString:MFPiPadAppiTunesURLString]];
    else
      [app openURL:[NSURL URLWithString:MFPAppiTunesURLString]];
  }
  
}


- (void)authorizeWithScope:(NSString *)scope
                 onSuccess:(MFPCallback)successCallback
                 onFailure:(MFPCallback)failureCallback {
  
  @autoreleasepool {
    [self installApp]; // Will not do anything if app is already installed
    UIApplication *app = [UIApplication sharedApplication];
    MFPAppType apps = [MFP availableMFPApps];
    NSString *urlBase = nil;

    if (apps & MFPiPadApp)
      urlBase = @"mfphd://oauth2/authorize?";
    else if (apps & MFPiPhoneApp)
      urlBase = @"mfp://oauth2/authorize?";
   
    GLLog(@"redirect_uri %@", [[self baseAppURLString] stringByAppendingString:MFPRedirectURIPath]);
    NSString *queryString = [self dictionaryToQueryString:@{
      @"display":@"mobile",
      @"access_type":@"offline",
      @"response_type":_responseType,
      @"client_id":_clientId,
      @"scope":scope,
      @"redirect_uri":[[self baseAppURLString] stringByAppendingString:MFPRedirectURIPath]
    }];

    _successCallback = successCallback;
    _failureCallback = failureCallback;

    NSURL *URL = [NSURL URLWithString:[urlBase stringByAppendingString:queryString]];
    [app openURL:URL];
  }
  
}



- (void)revokeAccess {
  [self revokeAccessOnSuccess:nil onFailure:nil];
}



- (void)revokeAccessOnSuccess:(MFPCallback)successCallback
                    onFailure:(MFPCallback)failureCallback {
  MFPCallback onDone = ^(NSDictionary *r){
    if ([_delegate respondsToSelector:@selector(MFPAccessRevoked:)])
      [_delegate MFPAccessRevoked:self];
    if (successCallback)
      successCallback(r);
  };

  NSString *urlString = [NSString stringWithFormat:@"%@/oauth2/revoke/?refresh_token=%@", MFPRoot, _refreshToken];
  [self makeRequestWithURLString:urlString
                      HTTPMethod:@"GET"
                     contentType:nil
                        HTTPBody:nil
                 successCallback:onDone
                 failureCallback:failureCallback];
}



- (void)refreshAccessToken {
  [self refreshAccessTokenOnSuccess:nil onFailure:nil];
}



- (void)refreshAccessTokenOnSuccess:(MFPCallback)successCallback
                          onFailure:(MFPCallback)failureCallback {
  MFPCallback onDone = ^(NSDictionary *r){
    if (successCallback)
      successCallback(r);
    if ([_delegate respondsToSelector:@selector(MFP:accessTokenRefreshed:)])
      [_delegate MFP:self accessTokenRefreshed:r];
  };


  NSDictionary *dict = @{@"refresh_token":_refreshToken, @"grant_type": @"refresh_token"};
  [self makeRequestWithURLString:[NSString stringWithFormat:@"%@/oauth2/token/", MFPRoot]
                      HTTPMethod:@"POST"
                     contentType:@"application/x-www-form-urlencoded"
                        HTTPBody:[_delegate MFP:self dictionaryToJSONString:dict]
                 successCallback:onDone
                 failureCallback:failureCallback];
}



- (void)APIrequestNamed:(NSString *)actionName params:(NSDictionary *)params {
  [self APIrequestNamed:actionName params:params onSuccess:nil onFailure:nil];
}



- (void)APIrequestNamed:(NSString *)actionName
                 params:(NSDictionary *)params
              onSuccess:(MFPCallback)successCallback
              onFailure:(MFPCallback)failureCallback {

  if (!_accessToken)
  {
      if (failureCallback)
      {
          failureCallback(@{@"error":@"access_token not set"});
      }
      return;
  }
  NSString *urlString = [NSString stringWithFormat:@"%@/client_api/json/%@?client_id=%@",
                                  APIRoot, [MFP versionString], _clientId];

  NSMutableDictionary *dict =[params mutableCopy];
  [dict addEntriesFromDictionary:@{@"action":actionName, @"access_token":_accessToken}];

  [self makeRequestWithURLString:urlString
                      HTTPMethod:@"POST"
                     contentType:@"application/json; charset=utf-8"
                        HTTPBody:[_delegate MFP:self dictionaryToJSONString:dict]
                 successCallback:successCallback
                 failureCallback:failureCallback];
}



#pragma mark Utilities

- (NSString *)scheme {
  NSArray *parts = nil;
  if (_urlSchemeSuffix && [_urlSchemeSuffix length] > 0)
    parts = @[@"mfp", _clientId, _urlSchemeSuffix];
  else
    parts = @[@"mfp", _clientId];

  return [parts componentsJoinedByString:@"-"];
}



- (NSString *)baseAppURLString {
  return [NSString stringWithFormat:@"%@://%@", [self scheme], MFPHost];
}



- (void)makeRequestWithURLString:(NSString *)urlString
                      HTTPMethod:(NSString *)method
                     contentType:(NSString *)type
                        HTTPBody:(NSString *)body
                 successCallback:(MFPCallback)successCallback
                 failureCallback:(MFPCallback)failureCallback {
  MFPRequestDelegate *requestDelegate = [MFPRequestDelegate new];
  [requestDelegate setSuccessCallback:successCallback];
  [requestDelegate setFailureCallback:failureCallback];
  [requestDelegate setMFP:self];

  NSURL *url = [NSURL URLWithString:urlString];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  if (method)
    [request setHTTPMethod:method];
  [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
  [request setTimeoutInterval: 30];
  if (type)
    [request setValue:type forHTTPHeaderField:@"Content-type"];
  if (body)
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];

  [_connection cancel];
  _connection = [[NSURLConnection alloc] initWithRequest:request delegate:requestDelegate];
}



- (NSString *)dictionaryToQueryString:(NSDictionary *)dictionary {
  NSMutableArray *components = [[NSMutableArray alloc] initWithCapacity:[dictionary count]];
  @autoreleasepool {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop) {
      key = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      value = [value stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [components addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }];
  }
  return [components componentsJoinedByString:@"&"];
}



- (NSDictionary *)queryStringToDictionary:(NSString *)queryString {
  NSArray *components = [queryString componentsSeparatedByString:@"&"];
  NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:[components count]];
  @autoreleasepool {
    for (NSString *component in components) {
      NSArray *keyValue = [component componentsSeparatedByString:@"="];
      NSString *key = [[keyValue objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      NSString *value = [[keyValue objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      [dictionary setValue:value forKey:key];
    }
  }
  return dictionary;
}



- (void)dealloc {
  [_connection cancel];
}


@end

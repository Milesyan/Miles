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

#import <Foundation/Foundation.h>

@protocol MFPDelegate;

typedef enum MFPAppType : uint16_t {
  MFPiPadApp = 1 << 0,
  MFPiPhoneApp = 1 << 1
} MFPAppType;


typedef void (^MFPCallback)(NSDictionary *data);


@interface MFP : NSObject

@property (nonatomic, readonly, unsafe_unretained) id <MFPDelegate> delegate;
@property (nonatomic, readonly) NSString *responseType;
@property (nonatomic, readonly) NSString *urlSchemeSuffix;
@property (nonatomic, copy) NSString *accessToken;
@property (nonatomic, copy) NSString *refreshToken;

+ (MFPAppType)availableMFPApps;

+ (NSString *)versionString;

- (id)initWithClientId:(NSString *)clientId
          responseType:(NSString *)responseType
              delegate:(id <MFPDelegate>)delegate;

- (id)initWithClientId:(NSString *)clientId
          responseType:(NSString *)responseType
              delegate:(id <MFPDelegate>)delegate
       urlSchemeSuffix:(NSString *)urlSchemeSuffix;

- (BOOL)handleOpenURL:(NSURL *)url;

@end



@interface MFP (oAuth)

- (void)authorizeWithScope:(NSString *)scope;
- (void)authorizeWithScope:(NSString *)scope
                 onSuccess:(MFPCallback)successCallback
                 onFailure:(MFPCallback)failureCallback;

- (void)revokeAccess;
- (void)revokeAccessOnSuccess:(MFPCallback)successCallback
                    onFailure:(MFPCallback)failureCallback;

- (void)refreshAccessToken;
- (void)refreshAccessTokenOnSuccess:(MFPCallback)successCallback
                          onFailure:(MFPCallback)failureCallback;
- (BOOL)appIsInstalled;
- (void)installApp;

@end



@interface MFP (APIRequest)

- (void)APIrequestNamed:(NSString *)actionName
                 params:(NSDictionary *)params;

- (void)APIrequestNamed:(NSString *)actionName
                 params:(NSDictionary *)params
              onSuccess:(MFPCallback)successCallback
              onFailure:(MFPCallback)failureCallback;

@end


@protocol MFPDelegate <NSObject>

- (NSString *)MFP:(MFP *)MFP dictionaryToJSONString:(NSDictionary *)data;
- (NSDictionary *)MFP:(MFP *)MFP JSONStringToDictionary:(NSString *)string;

/* Called whenever your application was opened by an MFP App, the
   appropriate thing to do in response to this is to show a screen
   with instructions on how to link with an MFP App. */
- (void)MFPDidOpenApplication:(MFP *)MFP;

@optional
- (void)MFP:(MFP *)MFP didAuthorize:(NSDictionary *)response;
- (void)MFP:(MFP *)MFP failedToAuthorize:(NSDictionary *)response;


- (void)MFPAccessRevoked:(MFP *)MFP;
- (void)MFP:(MFP *)MFP accessTokenRefreshed:(NSDictionary *)response;


- (void)MFP:(MFP *)MFP requestSucceeded:(NSDictionary *)response;
- (void)MFP:(MFP *)MFP requestFailed:(NSDictionary *)response;


@end

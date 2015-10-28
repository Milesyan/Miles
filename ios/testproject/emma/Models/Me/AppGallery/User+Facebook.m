//
//  User+Facebook.m
//  emma
//
//  Created by Ryan Ye on 12/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import "User+Facebook.h"
#import "Network.h"

@implementation User(Facebook)
+ (FBSession *) session {
    return [FBSession activeSession];
}

+ (void)clearFBSession {
    [[FBSession activeSession] closeAndClearTokenInformation];
    [[FBSessionTokenCachingStrategy defaultInstance] clearToken];
}

+ (void)connectFacebook:(FBConnectCallback)callback {
    [CrashReport leaveBreadcrumb:@"connectFacebook"];
    if ([[FBSession activeSession] isOpen]) {
        return;
    }
    //GLLog(@"session state: %@", [FBSession activeSession]);
    
    [FBSession openActiveSessionWithReadPermissions:EMMA_FB_PERMISSIONS allowLoginUI:YES completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
        GLLog(@"FBSession openWithBehavior session=%@ state=%d error=%@", session, state, error);
        switch (state) {
            case FBSessionStateOpen:
            {
                if (error) {
                    [User clearFBSession];
                    [self publish:EVENT_FB_CONNECT_FAILED data:FB_CONNECT_FAILED_MSG];
                    return;
                }
                [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                    // when cached session is used, we may hit error here
                    GLLog(@"FBRequest get graph.facebook.com/me result:%@ err:%@",result, error);
                    if (error) {
                        // close the session since the session is opened
                        [User clearFBSession];
                        [self publish:EVENT_FB_CONNECT_FAILED data:FB_CONNECT_FAILED_MSG];
                        return;
                    }
                    callback(result);
                }];
            }
                break;
            case FBSessionStateClosedLoginFailed:
            {
                [User clearFBSession];
                [FBSession renewSystemCredentials:^(ACAccountCredentialRenewResult result, NSError *error){}];
                [self publish:EVENT_FB_CONNECT_FAILED data:FB_CONNECT_FAILED_MSG];
            }
                break;
            default:
                break;
        }
    }];
}

+ (void)signInWithFacebook {
    [User connectFacebook:^(NSDictionary<FBGraphUser> *facebookInfo) {
        GLLog(@"signInWithFacebook, fbInfo = %@", facebookInfo);
        [User fetchUserByFacebookID:facebookInfo.objectID dataStore:[DataStore defaultStore] completionHandler:^(User *user, NSError *error) {
            if (!error) {
                if (!user) {
                    [User clearFBSession];
                    [self publish:EVENT_USER_LOGIN_FAILED
                             data:@"There's no Glow account connected with your facebook account. Please sign up."];
                } else {
                    [user login];
                }
            }
        }];
    }];
}

+ (void)signUpWithFacebook {
    [User connectFacebook:^(NSDictionary<FBGraphUser> *fbinfo) {
        GLLog(@"signUpWithFacebook, fbInfo = %@", fbinfo);
        DataStore *ds = [DataStore defaultStore];
        NSDictionary *onboardingInfo = [Settings createPushRequestForNewUserWith:[Utils getDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS]];
        [[Network sharedNetwork] post:@"v2/users/signup/facebook" data:
         @{@"fbinfo": fbinfo, @"onboardinginfo": onboardingInfo}
                         requireLogin: NO
                    completionHandler:^(NSDictionary *result, NSError *err) {
                        
                        NSDictionary *userData = [result objectForKey:@"user"];
                        NSString *errMsg = [userData objectForKey:@"msg"];
                        if (err || errMsg) {
                            [User clearFBSession];
                            [self publish:EVENT_USER_SIGNUP_FAILED data:(errMsg ? errMsg : @"Failed to connect to the server.")];
                            return;
                        }
                        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
                        User *user = [User upsertWithServerData:userData dataStore:ds];
                        user.fbInfo = fbinfo;
                        [user save];
                        [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
                                   parameters:@{FBAppEventParameterNameRegistrationMethod:
                                                    @"Facebook"}];
                        if (user.isFemale && user.isSecondary) {
                            [Utils setDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY withValue:SIGN_UP_WARNING_TYPE_FEMALE_PARTNER];
                        }
                        else if (user.isMale && result[@"disconnected"]) {
                            [Utils setDefaultsForKey:USER_DEFAULTS_SIGN_UP_WARNING_TYPE_KEY withValue:SIGN_UP_WARNING_TYPE_MALE_INVITED_BY_MALE];
                        }
                        [user login];
                    }];
    }];
}

+ (void)signUpAsPartnerWithFacebook {
    [User connectFacebook:^(NSDictionary<FBGraphUser> *fbinfo) {
        GLLog(@"signUpAsPartnerWithFacebook, fbInfo = %@", fbinfo);
        DataStore *ds = [DataStore defaultStore];
        [[Network sharedNetwork] post:@"users/fb_partner"
                                 data:@{@"fbinfo": fbinfo}
                         requireLogin:NO
                    completionHandler:^(NSDictionary *result, NSError *err) {
                        int rc = [result[@"rc"] intValue];
                        NSString *msg = result[@"msg"] ? result[@"msg"] : @"Failed to connect to server.";
                        if (err || rc != RC_SUCCESS ) {
                            [User clearFBSession];
                            [self publish:EVENT_USER_SIGNUP_FAILED data:msg];
                            return;
                        }
                        User *user = [User upsertWithServerData:result[@"user"] dataStore:ds];
                        user.fbInfo = fbinfo;
                        [user save];
                        [FBAppEvents logEvent:FBAppEventNameCompletedRegistration
                                   parameters:@{FBAppEventParameterNameRegistrationMethod:
                                                    @"Facebook_partner"}];
                        [user login];
                    }];
    }];
}

- (void)addFacebook {
    [User connectFacebook:^(NSDictionary<FBGraphUser> *facebookInfo) {
        if (self.fbId) return; // return if already connected with facebook
        NSDictionary *request = [self postRequest:@{@"fbinfo": facebookInfo}];
        [[Network sharedNetwork] post:@"users/add_facebook" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
            [self publish:EVENT_USER_ADD_FACEBOOK_RETURNED];
            if (err) {
                [User clearFBSession];
                [self publish:EVENT_USER_ADD_FACEBOOK_FAILED data:@"Failed to connect to the server."];
            } else if (result[@"error_msg"]) {
                [User clearFBSession];
                [self publish:EVENT_USER_ADD_FACEBOOK_FAILED data:result[@"error_msg"]];
            } else {
                self.fbId = facebookInfo[@"id"];
                self.fbInfo = facebookInfo;
                if (!self.profileImageUrl) {
                    [self loadProfileImage:^(UIImage *image, NSError *err) {
                        [self publish:EVENT_PROFILE_IMAGE_UPDATE data:image];
                    }];
                }
                [self save];
            }
        }];
    }];
}

- (void)disconnectFacebook {
    if (!self.fbId) return;
    NSDictionary *request = [self postRequest:@{@"fbid": self.fbId}];
    [[Network sharedNetwork] post:@"users/disconnect_facebook" data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            [self publish:EVENT_USER_DISCONNECT_FACEBOOK_FAILED data:@"Failed to connect to the server"];
        } else {
            self.fbId = nil;
            self.fbInfo = nil;
            [User clearFBSession];
            [self save];
        }
    }];
}

- (BOOL)isFacebookConnected {
    return self.fbId != nil;
}

+ (void)shareOnFacebook:(NSString *)text fromViewController:(UIViewController*)controller {
    User * u = [User currentUser];
    if ([Utils isNotEmptyString:u.fbId]) {
        [User shareOnFacebookSession:text fromViewController:controller];
    } else {
        if ([[FBSession activeSession] isOpen]) {
            [User shareOnFacebookSession:text fromViewController:controller];
        } else {
            FBSessionLoginBehavior behavior = FBSessionLoginBehaviorWithFallbackToWebView;
            [[FBSession activeSession] openWithBehavior:behavior completionHandler:^(FBSession *session, FBSessionState state, NSError *error){
                // no error, because ios could use cached data
                if (error) {
                    [User clearFBSession];
                    return;
                }
                [User shareOnFacebookSession:text fromViewController:controller];
            }];
        }
    }
}

+ (void)shareOnFacebookSession:(NSString *)text fromViewController:(UIViewController*)controller {
    FBSession *session = [User session];
    FBSessionLoginType loginType = session.accessTokenData.loginType;
    if (loginType == FBSessionLoginTypeSystemAccount) {
        [FBDialogs presentOSIntegratedShareDialogModallyFrom:controller initialText:text image:nil url:nil handler:^(FBOSIntegratedShareDialogResult result, NSError *error) {
            GLLog(@"FBNativeDialog: error=%@", error);
        }];
    } else {
        NSDictionary *params = @{
                                 @"caption" : @"Glow",
                                 @"description" : text,
                                 @"link" : @"https://glowing.com/glow_first"
                                 };
        [FBWebDialogs presentFeedDialogModallyWithSession:session parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *error) {
            GLLog(@"FBWebDialogHandler: url=%@ error=%@", resultURL, error);
        }];
    }
}

+ (void)fetchUserByFacebookID:(NSString *)fbid dataStore:(DataStore *)ds completionHandler:(FetchUserCallback)callback {
    NSString *apiPath = [NSString stringWithFormat:@"users/fb/%@", fbid];
    [[Network sharedNetwork] get:apiPath completionHandler:^(NSDictionary *data, NSError *error){
        User *user = nil;
        if (!error) {
            id userData = [data objectForKey:@"user"];
            if (userData != [NSNull null]) {
                user = [User upsertWithServerData:userData dataStore:ds];
                [user save];
            }
        }
        callback(user, error);
    }];
}

- (void)fetchFacebookInfo:(FetchFacebookInfoCallback)callback {
    FBRequest *request = [[FBRequest alloc] initWithSession:[FBSession activeSession] graphPath:@"/me"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        self.fbInfo = result;
        if (callback) callback(self.fbInfo, error);
    }];
}

- (void)invitePartnerOnFacebook:(NSDictionary *)partnerFbInfo completionHandler:(InvitePartnerCallback)callback {
    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"invitePartnerOnFacebook:%@", partnerFbInfo[@"id"]]];
    NSString *url = @"users/partner/fb";
    NSDictionary *data = [self postRequest:@{
                                             @"fb_id" : partnerFbInfo[@"id"],
                                             @"name" : partnerFbInfo[@"name"],
                                             @"is_mom" : @([self.gender isEqual:FEMALE] == NO)
                                             }];
    [[Network sharedNetwork] post:url data:data requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        [self handleInvitePartnerResponse:result error:err callback:callback];
    }];
}

@end

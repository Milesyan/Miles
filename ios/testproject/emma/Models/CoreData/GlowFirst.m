//
//  GlowFirst.m
//  emma
//
//  Created by Jirong Wang on 6/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GlowFirst.h"
#import "User.h"
#import "DataStore.h"
#import "Network.h"
#import "Errors.h"
#import "Utils.h"
#import "ActivityLevel.h"
#import "UIImage+Resize.h"

@interface GlowFirst()

@property (nonatomic) int32_t creditBalance;  // 100 * $amount
@property (nonatomic) int16_t ended;

@property (nonatomic) int32_t fundGrant;  // 100 * $amount

@property (nonatomic, retain) NSString * ccLast4;
@property (nonatomic, retain) NSString * ccType;
@property (nonatomic) int64_t reviewBefore;

@property (nonatomic, retain) User *user;

@end

@implementation GlowFirst

@dynamic reviewBefore;
@dynamic reviewClaims;
@dynamic creditBalance;
@dynamic ended;
@dynamic fundPaid;
@dynamic fundGrant;
@dynamic fundGrantDeadline;
@dynamic fundStopReason;
@dynamic user;
@dynamic ccLast4;
@dynamic ccType;

+ (GlowFirst *)sharedInstance {
    return [User currentUser].glowFirst;
}

- (NSDictionary *)postRequest:(NSDictionary *)request {
    return [[GlowFirst sharedInstance].user postRequest:request];
}

- (NSString *)username {
    NSString *lastName = [self.user.lastName stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *firstName = [self.user.firstName stringByReplacingOccurrencesOfString:@" " withString:@""];
    return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
}

- (CGFloat)getBalance {
    return self.creditBalance * 1.0 /100;
}
- (CGFloat)getFundGrant {
    return self.fundGrant * 1.0 / 100;
}

- (NSString *)getCreditString:(CGFloat)amount {
    return [NSString stringWithFormat:@"$%.2f", amount];
}
- (NSString *)getBalanceString {
    return [self getCreditString:[self getBalance]];
}
- (NSString *)getFundGrantString {
    return [self getCreditString:[self getFundGrant]];
}

- (BOOL)hasCreditCardOnFile {
    return self.ccLast4 && [self.ccLast4 length] > 0;
}

- (NSString *)redactedCardNumber {
    NSString *last4 = self.ccLast4;
    NSDictionary *cardDigits = @{
        @"Visa": @(16),
        @"MasterCard": @(16),
        @"American Express": @(15),
        @"Discover": @(16),
        @"Diner's Club": @(14),
        @"JCB": @(16)
        };
    int digits;
    NSString *t = [cardDigits objectForKey:self.ccType];
    if (t) {
        digits = [t intValue];
    } else {
        digits = 16;
    }
    if (last4) {
        digits -= 4;
    }
    NSString * stars = [@"" stringByPaddingToLength:digits withString:@"*" startingAtIndex:0];
    if (last4) {
        return [NSString stringWithFormat:@"%@%@", stars, last4];
    } else {
        return stars;
    }
}

- (void)changeCard:(NSString *)number expMonth:(NSUInteger)expMonth expYear:(NSUInteger)expYear cvc:(NSString *)cvc {
    NSString *url = @"users/change_card";
    NSDictionary *request = [self postRequest:@{
                             @"number": number,
                             @"exp_month": @(expMonth),
                             @"exp_year": @(expYear),
                             @"cvc": cvc,
                             @"name": [self username]
                             }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES timeout:NETWORK_PAYMENT_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            NSString * errMsg = [result objectForKey:@"msg"];
            if (rc == RC_SUCCESS) {
                self.ccLast4 = [result objectForKey:@"last4"];
                self.ccType = [result objectForKey:@"type"];
                [self.user save];
            }
            [self publish:EVENT_CARDNUMBER_CHANGED data:@{@"rc": @(rc), @"errMsg": errMsg}];
        } else {
            [self publish:EVENT_CARDNUMBER_CHANGED data:@{@"error": err}];
        }
    }];
}

- (void)syncCardInfo {
    NSString *url = @"users/get_card";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            if (rc == RC_SUCCESS) {
                NSString *last4 = [result objectForKey:@"last4"];
                if ([Utils isEmptyString:last4] && [Utils isEmptyString:self.ccLast4]){
                    return;
                }
                BOOL cardAddOrRemove = YES;
                if ([Utils isNotEmptyString:last4] && [Utils isNotEmptyString:self.ccLast4]) {
                    cardAddOrRemove = NO;
                }
                if (![last4 isEqualToString:self.ccLast4]) {
                    self.ccLast4 = [result objectForKey:@"last4"];
                    self.ccType = [result objectForKey:@"type"];
                    [self.user save];
                    [self publish:EVENT_GET_CARD data:@{@"cardAddOrRemove": @(cardAddOrRemove)}];
                }
            }
        }
    }];
}

- (void)joinFund:(NSString *)number expMonth:(NSUInteger)expMonth expYear:(NSUInteger)expYear cvc:(NSString *)cvc {    
    NSString *url = @"users/join_fund";
    NSDictionary *request = [self postRequest:@{
                             @"number": number,
                             @"exp_month": @(expMonth),
                             @"exp_year": @(expYear),
                             @"cvc": cvc,
                             @"name": [self username]
                             }];
    [[Network sharedNetwork] post:url data:request requireLogin:YES timeout:NETWORK_PAYMENT_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            NSString * errMsg = [result objectForKey:@"msg"];
            NSNumber * statusObj = [result objectForKey:@"ovation_status"];
            if (statusObj && ![statusObj isKindOfClass:[NSNull class]]) {
                NSInteger ovationStatus = [statusObj integerValue];
                if ((ovationStatus == OVATION_STATUS_UNDER_FUND) ||
                    (ovationStatus == OVATION_STATUS_UNDER_FUND_DELAY)) {
                    self.user.ovationStatus = ovationStatus;
                    // clear the fundPaid and fundGrant value, since we join a new fund
                    self.fundGrant = 0;
                    self.fundPaid = 0;
                    self.ended = 0;
                    self.fundStopReason = @"";
                    self.reviewClaims = 0;
                    [self.user save];
                    [self syncCardInfo];
                }
            }
            [self publish:EVENT_JOIN_FUND data:@{@"fundRC": @(rc), @"errMsg": errMsg}];
        } else {
            [self publish:EVENT_JOIN_FUND data:@{@"error": err}];
        }
    }];
}

- (void)syncFundsSummary {
    NSString *url = @"users/funds_summary";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSDictionary *fundsSummary = [result objectForKey:@"funds_summary"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:fundsSummary forKey:@"fundsSummary"];
            [defaults synchronize];
            [self publish:EVENT_FUND_SYNC_SUMMARY];
        }
    }];
}

- (void)syncUserFundSummary {
    if (self.ended) {
        return;
    }
    NSString *url = @"users/user_fund_summary";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSDictionary *summary = [result objectForKey:@"user_fund_summary"];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:summary forKey:@"userFundSummary"];
            [defaults synchronize];
            int isEnded = [[summary objectForKey:@"ended"] intValue];
            if (isEnded) {
                self.ended = isEnded;
                [self.user save];
            }
            [self publish:EVENT_FUND_SYNC_SUMMARY];
        }
    }];
}

- (NSDictionary *)getFundsSummary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *fundsSummary = [defaults objectForKey:@"fundsSummary"];
    
    int amounts = fundsSummary ? [[fundsSummary objectForKey:@"amounts"] intValue] : 0;
    int pregnancies = fundsSummary ? [[fundsSummary objectForKey:@"pregnancies"] intValue] : 0;
    int users_all = fundsSummary ? [[fundsSummary objectForKey:@"users_all"] intValue] : 0;
    
    return @{
        @"amounts": [NSString stringWithFormat:@"$%@", [Utils numberTo4BytesString:amounts]],
        @"pregnancies": [Utils numberTo4BytesString:pregnancies],
        @"users_all": [Utils numberTo4BytesString:users_all]
    };
}

- (NSDictionary *)getUserFundSummary {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *summary = [defaults objectForKey:@"userFundSummary"];
    int potentialGrant = summary ? [[summary objectForKey:@"potential_grant"] intValue] : 0;
    int userAmount = summary ? [[summary objectForKey:@"user_amount"] intValue] : 0;
    
    return @{
        @"potentialGrant": [NSString stringWithFormat:@"$%@", [Utils numberTo4BytesString:potentialGrant]],
        @"userAmount": [NSString stringWithFormat:@"$%@", [Utils numberTo4BytesString:userAmount]]
    };
}

- (void)syncFundGrant {
    NSString *url = @"users/grant_from_fund";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            self.fundGrant = [[result objectForKey:@"grant_from_fund"] intValue];
            self.fundGrantDeadline = [[NSDate alloc] initWithTimeIntervalSince1970:[[result objectForKey:@"grant_deadline"] longLongValue]];
            [self.user save];
            [self publish:EVENT_FUND_SYNC_GRANT];
        }
    }];
}

- (void)syncFundPaid {
    NSString *url = @"users/paid_to_fund";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            self.fundPaid = [[result objectForKey:@"paid_to_fund"] intValue];
            [self.user save];
            [self publish:EVENT_FUND_SYNC_PAID];
        }
    }];
}

- (void)syncFundStopReason {
    NSString *url = @"users/fund_stop_reason";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            self.fundStopReason = [result objectForKey:@"fund_stop_reason"];
            [self.user save];
            [self publish:EVENT_FUND_SYNC_PAID];
        }
    }];
}

- (void)syncCreditBalance {
    NSString *url = @"users/credit_balance";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            self.creditBalance = [[result objectForKey:@"credit_balance"] intValue];
            self.reviewClaims  = [[result objectForKey:@"review_claims"] intValue];
            [self.user save];
            [self publish:EVENT_FUND_SYNC_BALANCE];
        }
    }];
}

- (void)ovationReview:(NSDictionary *)applyRequest{
    NSString *url = @"users/ovation_review_v2";
    NSMutableDictionary * req = [NSMutableDictionary dictionaryWithDictionary:applyRequest];
    if (![req objectForKey:@"name"]) {
        [req setObject:[self username] forKey:@"name"];
    }
    NSDictionary *data = [self postRequest:req];
    [[Network sharedNetwork] post:url data:data requireLogin:YES timeout:NETWORK_PAYMENT_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            if (rc != RC_SUCCESS) {
                NSString * errMsg = [result objectForKey:@"msg"];
                [self publish:EVENT_APPLY_OVATION_REVIEW data:@{@"rc": @(rc), @"errMsg": errMsg}];
            } else {
                NSNumber *ovationStatus = [result objectForKey:@"ovation_status"];
                NSNumber *reviewBefore = [result objectForKey:@"before"];
                self.user.ovationStatus = [ovationStatus intValue];
                self.reviewBefore  = [reviewBefore intValue];
                [self save];
                [self syncCardInfo];
                [self publish:EVENT_APPLY_OVATION_REVIEW data:@{@"rc": @(rc)}];
            }
        } else {
            [self publish:EVENT_APPLY_OVATION_REVIEW data:@{@"rc": @(-1)}];
        }
    }];
}

- (void)getOvationReviewBefore {
    NSString *url = @"users/ovation_review_before";
    NSDictionary *request = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSNumber *reviewBefore = [result objectForKey:@"review_before"];
            self.reviewBefore  = [reviewBefore intValue];
            [self save];
            [self publish:EVENT_GET_OVATION_REVIEW_BEFORE];
        }
    }];
}


- (void)commonPost:(NSString *)url request:(NSDictionary *)request event:(NSString *)event {
    /*
     This func is used for - 
     (1) - only changes OvationReview status
     (2) - resposne only contains RC
     
     input -
        request - post request
        event   - send event in callback
     */
    NSDictionary *newRequest = [self postRequest:request];
    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            if (rc == RC_SUCCESS) {
                // see if "ovation_status" in response
                NSNumber *ovationStatus = [result objectForKey:@"ovation_status"];
                if (ovationStatus) {
                    self.user.ovationStatus = [ovationStatus intValue];
                    [self.user save];
                }
            }
            [self publish:event data:result];
        } else {
            [self publish:event data:@{@"rc": @(RC_NETWORK_ERROR)}];
        }
    }];
}

- (void)userPregnant {
    [self commonPost:@"users/pregnant" request:@{} event:EVENT_FUND_USER_PREGNANT];
}

- (void)enterpriseApply:(NSDictionary *)applyRequest {
    [self commonPost:@"users/enterprise_apply" request:applyRequest event:EVENT_FUND_ENTERPRISE_APPLY];
}

- (void)enterpriseVerify:(NSDictionary *)verifyRequest {
    [self commonPost:@"users/enterprise_verify" request:verifyRequest event:EVENT_FUND_ENTERPRISE_VERIFY];
}

- (void)enterpriseApplyByPhoto:(UIImage *)image {
    UIImage *resizedImage = [image resizedImageWithContentMode:UIViewContentModeScaleAspectFill bounds:CGSizeMake(1024.0, 1024.0) interpolationQuality:kCGInterpolationMedium];
    GLLog(@"resizedImage:%@", resizedImage);

    NSString * url = @"users/enterprise_apply_by_photo";
    NSDictionary *newRequest = [self postRequest:@{}];
                                
    int timestamp = (int)[[NSDate date] timeIntervalSince1970];
    int rand = arc4random() % 1000;
    NSString *filename = [NSString stringWithFormat:@"gf_enterprise_%d%d.jpg", timestamp, rand];
    NSDictionary * imageDict = @{
        filename : resizedImage
        };
    
    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES images:imageDict completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            [self publish:EVENT_FUND_ENTERPRISE_APPLY_BY_PHOTO data:result];
        } else {
            [self publish:EVENT_FUND_ENTERPRISE_APPLY_BY_PHOTO data:@{@"rc": @(RC_NETWORK_ERROR)}];
        }
    }];
}

- (void)startDemo {
    NSString * url = @"users/fund_start_demo";
    NSDictionary *newRequest = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            if (rc == RC_SUCCESS) {
                // see if "ovation_status" in response
                NSNumber *ovationStatus = [result objectForKey:@"ovation_status"];
                self.user.ovationStatus = [ovationStatus intValue];
                [self.user save];
                // "quit_time" in the response
                NSInteger quitTimestamp = [[result objectForKey:@"quit_time"] integerValue];
                if (quitTimestamp > 0) {
                    NSDate * quitDemoDate = [NSDate dateWithTimeIntervalSince1970:quitTimestamp];
                    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:quitDemoDate forKey:USER_DEFAULT_FUND_QUIT_DEMO_DATE];
                    [defaults synchronize];
                }
            }
            [self publish:EVENT_FUND_START_DEMO data:result];
        } else {
            [self publish:EVENT_FUND_START_DEMO data:@{@"rc": @(RC_NETWORK_ERROR)}];
        }
    }];
}

- (void)quitDemo {
    [self commonPost:@"users/fund_quit_demo" request:@{} event:EVENT_FUND_QUIT_DEMO];
}

- (void)enterpriseSendEmail:(NSString *)email content:(NSString *)content cc:(BOOL)ccUser {
    [self commonPost:@"users/fund_send_email_to_enterprise"
             request:@{@"email": email, @"content": content,
                       @"cc_user": ccUser ? @(1) : @(0)}
               event:EVENT_FUND_SEND_EMAIL_TO_ENTERPRISE];
}

- (NSDate *)localFundQuitDemoDate {
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    return (NSDate *)[defaults objectForKey:USER_DEFAULT_FUND_QUIT_DEMO_DATE];
}

- (void)getQuitDemoDate {
    NSString * url = @"users/get_quit_demo_time";
    NSDictionary *newRequest = [self postRequest:@{}];
    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] integerValue];
            if (rc == RC_SUCCESS) {
                // in "quit_time" in the response
                NSInteger quitTimestamp = [[result objectForKey:@"quit_time"] integerValue];
                if (quitTimestamp > 0) {
                    NSDate * quitDemoDate = [NSDate dateWithTimeIntervalSince1970:quitTimestamp];
                    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
                    [defaults setObject:quitDemoDate forKey:USER_DEFAULT_FUND_QUIT_DEMO_DATE];
                    [defaults synchronize];
                    [self publish:EVENT_FUND_GET_QUIT_DEMO_TIME];
                }
            }
        }
    }];
}

- (void)agreeClaimTerms:(NSDictionary *)agreeInfo {
    NSString * url = @"users/fund_agree_claim_terms";
    NSDictionary *newRequest = [self postRequest:@{@"agree_info": agreeInfo}];

    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            // NSInteger rc = [[result objectForKey:@"rc"] intValue];
            [self publish:EVENT_FUND_AGREE_CLAIM_TERM data:result];
            return;
        }
        [self publish:EVENT_FUND_AGREE_CLAIM_TERM data:@{@"rc" :@(RC_NETWORK_ERROR)}];
    }];
}

- (void)createClaim:(NSDictionary *)claimInfo withImages:(NSArray *)images {
    NSString * url = @"users/fund_create_claim";
    NSDictionary *newRequest = [self postRequest:claimInfo];
    
    NSMutableDictionary * imagesDict = [[NSMutableDictionary alloc] init];
    int x = 0;
    for (id img in images) {
        NSString * name = [NSString stringWithFormat:@"image_%d", x];
        x++;
        [imagesDict setObject:img forKey:name];
    }
    [[Network sharedNetwork] post:url data:newRequest requireLogin:YES images:imagesDict completionHandler:^(NSDictionary *result, NSError *err) {
    // [[Network sharedNetwork] post:url data:request timeout:NETWORK_PAYMENT_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            NSInteger rc = [[result objectForKey:@"rc"] intValue];
            if (rc == RC_SUCCESS) {
                [self publish:EVENT_FUND_CLAIM_SUCCESS];
                return;
            }
        }
        [self publish:EVENT_FUND_CLAIM_ERROR];
    }];
}

- (void)adminSetFundPage:(NSInteger)pageId {
    /*
        NOTE - this is set the fund status, not ovation_review_status
            fund_status is used in the fund
            ovation_review_status is used for showing the pages for user
     */
    if (!FUND_DEBUG_SWITCH) {
        return;
    }
    NSString *url = @"users/admin_set_fund_page";
    NSDictionary *request = [self postRequest:@{@"new_page": @(pageId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (!err) {
            int rc = [[result objectForKey:@"rc"] intValue];
            if (rc == RC_SUCCESS) {
                int ovationStatus = [[result objectForKey:@"ovation_status"] intValue];
                self.user.ovationStatus = ovationStatus;
                [self.user save];
                [self publish:EVENT_FUND_RENEW_PAGE data:@{@"rc": @(RC_SUCCESS)}];
            } else {
                [self publish:EVENT_FUND_RENEW_PAGE data:@{@"rc": @(RC_NETWORK_ERROR)}];
            }
        }
    }];
}

@end

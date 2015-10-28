//
//  GlowFirst.h
//  emma
//
//  Created by Jirong Wang on 6/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "BaseModel.h"

#define USER_DEFAULT_FUND_QUIT_DEMO_DATE @"fundQuitDemoDate"

@class User;

@interface GlowFirst : BaseModel

@property (nonatomic, retain) NSDate * fundGrantDeadline;
@property (nonatomic) int32_t reviewClaims;
@property (nonatomic, retain) NSString * fundStopReason;
@property (nonatomic) int32_t fundPaid;

+ (GlowFirst *)sharedInstance;

- (BOOL)hasCreditCardOnFile;
- (CGFloat)getBalance;
- (CGFloat)getFundGrant;
- (NSString *)getCreditString:(CGFloat)amount;
- (NSString *)getBalanceString;
- (NSString *)getFundGrantString;

- (void)changeCard:(NSString *)number expMonth:(NSUInteger)expMonth expYear:(NSUInteger)expYear cvc:(NSString *)cvc;
- (void)syncCardInfo;
- (NSString *)redactedCardNumber;

- (void)joinFund:(NSString *)number expMonth:(NSUInteger)expMonth expYear:(NSUInteger)expYear cvc:(NSString *)cvc;

- (void)syncFundsSummary;
- (void)syncUserFundSummary;
- (NSDictionary *)getFundsSummary;
- (NSDictionary *)getUserFundSummary;
- (void)syncFundGrant;
- (void)syncFundPaid;
- (void)syncFundStopReason;
- (void)syncCreditBalance;
- (void)ovationReview:(NSDictionary *)applyRequest;
- (void)getOvationReviewBefore;
- (void)userPregnant;
- (void)enterpriseApply:(NSDictionary *)applyRequest;
- (void)enterpriseVerify:(NSDictionary *)verifyRequest;
- (void)enterpriseApplyByPhoto:(UIImage *)image;
- (void)startDemo;
- (void)quitDemo;
- (NSDate *)localFundQuitDemoDate;
- (void)getQuitDemoDate;
- (void)enterpriseSendEmail:(NSString *)email content:(NSString *)content cc:(BOOL)ccUser;
- (void)agreeClaimTerms:(NSDictionary *)acceptInfo;
- (void)createClaim:(NSDictionary *)claimInfo withImages:(NSArray *)images;

- (void)adminSetFundPage:(NSInteger)pageId;

@end

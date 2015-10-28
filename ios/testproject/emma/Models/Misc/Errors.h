//
//  Errors.h
//  emma
//
//  Created by Jirong Wang on 5/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#ifndef emma_Errors_h
#define emma_Errors_h

#define RC_SUCCESS                 0
#define RC_NETWORK_ERROR           2   // not returned by server
#define RC_UNKNOWN_ERROR           3
#define RC_USER_NOT_EXIST          4

#define RC_OPERATION_NOT_ALLOWED   11

#define RC_CC_REMOTE_CREATE_ERROR 1001
#define RC_CC_NOT_EXIST           1002
#define RC_CC_ALREADY_USED        1003
#define RC_CC_USED_BY_OTHER       1005

#define RC_CC_CREATE_ERROR        1006
#define RC_CC_CHARGE_ERROR        1007

#define RC_FUND_ALREADY_IN_FUND   2001
#define RC_FUND_NOT_EXIST         2002
#define RC_FUND_USER_NOT_EXIST    2003
#define RC_FUND_STATUS_ERROR      2004
#define RC_FUND_REFUND_ERROR      2005
#define RC_FUND_ALREADY_END       2006
#define RC_OVATION_ALREADY_REVIEW 2007

#define RC_ENTERPRISE_COMPANY_NOT_FOUND  2101
#define RC_ENTERPRISE_WORKING_EMAIL_USED 2102
#define RC_ENTERPRISE_USER_NOT_FOUND     2103
#define RC_ENTERPRISE_WRONG_VERIFY_CODE  2104
#define RC_ENTERPRISE_ALREADY_VERIFIED   2105
#define RC_ENTERPRISE_NOT_VERIFIED       2106
#define RC_ENTERPRISE_VERIFY_CODE_EXPIRE 2107

// Signup error
#define RC_USER_EMAIL_ALREADY_IN_USE 3001
#define RC_SIGNUP_NOT_PARTNER     3002
#define RC_USER_FATHER_SIGNUP_AS_MOTHER 3028
#define RC_USER_MALE_SIGNUP_AS_MOTHER 3029

#define RC_FULFILLMENT_EXCEED_LIMIT 5001

@interface Errors : NSObject

+ (NSDictionary *)errorMessages;
+ (NSString *)errorMessage:(NSInteger)rc;

@end

#endif

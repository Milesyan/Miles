//
//  Errors.m
//  emma
//
//  Created by Jirong Wang on 5/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#import "Errors.h"

@implementation Errors

+ (NSDictionary *)errorMessages {
    return @{
        @(RC_SUCCESS)                  : @"Success.",
        @(RC_NETWORK_ERROR)            : @"Network error!",
        @(RC_OPERATION_NOT_ALLOWED)    : @"The operation is not allowed.",
        @(RC_CC_CREATE_ERROR)          : @"Error in create card.",
        @(RC_CC_CHARGE_ERROR)          : @"Error in charging card.",
    };
}

+ (NSString *)errorMessage:(NSInteger)rc {
    NSString *msg = [[Errors errorMessages] objectForKey:@(rc)];
    return msg ? msg : [NSString stringWithFormat:@"Unknown error! RC = %ld", rc];
}

@end

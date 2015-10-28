//
//  GLSSOService.h
//  kaylee
//
//  Created by Bob on 14-7-8.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const GLSSOServiceAppSchama;
extern NSString *const GLSSOServiceAppInstalledAppsKey;

@interface GLSSOServiceLoginStatus : NSObject
@property (nonatomic) NSString *schema;
@property (nonatomic) NSString *token;
@property (nonatomic) NSString *firstname;
@property (nonatomic) NSString *lastname;

@end



@interface GLSSOServiceCore : NSObject
@property (nonatomic, copy) NSComparisonResult (^preferedLoginStatusComparater)(GLSSOServiceLoginStatus *lhs, GLSSOServiceLoginStatus *rhs);
+ (instancetype)sharedInstance;
- (void)saveCurrentAppLoginStatusWithFirstname:(NSString *)firstname lastname:(NSString *)lastname token:(NSString *)token;
- (void)removeCurrentAppLoginStatus;
- (GLSSOServiceLoginStatus *)loginStatus;

@end

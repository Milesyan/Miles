//
//  GLSSOService.m
//  kaylee
//
//  Created by Bob on 14-7-8.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLSSOService.h"
#import "GLSSOServiceCore.h"
#import "User.h"

NSString *const GLSSOServiceAppSchama = EMMA_URL_SCHEME;
NSString *const GLSSOServiceAppInstalledAppsKey = INSTALLED_APPS_KEY;

@implementation GLSSOService

+ (void)load
{
    [[self class] sharedInstance];
}

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^
                  {
                      sharedInstance = [self new];
                  });
    
    return sharedInstance;
}

#pragma mark -
- (id)init
{
    self = [super init];
    if (self)
    {
        [GLSSOServiceCore sharedInstance].preferedLoginStatusComparater = ^NSComparisonResult(GLSSOServiceLoginStatus *lhs, GLSSOServiceLoginStatus *rhs)
        {
            NSArray *preferedOrder = @[@"lexie", @"kaylee"];
            int lhsIndex = 1024;
            int rhsIndex = 1024;
            {
                for (int i = 0; i < preferedOrder.count; i++)
                {
                    if ([lhs.schema hasPrefix:preferedOrder[i]])
                    {
                        lhsIndex = i;
                        break;
                    }
                }
            }
            {
                for (int i = 0; i < preferedOrder.count; i++)
                {
                    if ([rhs.schema hasPrefix:preferedOrder[i]])
                    {
                        rhsIndex = i;
                        break;
                    }
                }
            }
            return [@(lhsIndex) compare:@(rhsIndex)];
        };

        [self subscribe:EVENT_USER_LOGGED_OUT selector:@selector(updateService)];
        [self subscribe:EVENT_PROFILE_MODIFIED selector:@selector(updateService)];
    }
    return self;
}

#pragma mark - Helpers
- (void)refreshKeychainItem
{
    NSString *token = [User currentUser].encryptedToken;
    [[GLSSOServiceCore sharedInstance] saveCurrentAppLoginStatusWithFirstname:[User currentUser].firstName lastname:[User currentUser].lastName token:token];
}

- (void)updateService
{
    if ([User currentUser])
    {
        [self refreshKeychainItem];
    }
    else
    {
        [[GLSSOServiceCore sharedInstance] removeCurrentAppLoginStatus];
    }
}

@end

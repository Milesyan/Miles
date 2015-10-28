//
//  GLSSOService.m
//  kaylee
//
//  Created by Bob on 14-7-8.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLSSOServiceCore.h"
#import <UICKeyChainStore/UICKeyChainStore.h>

@implementation GLSSOServiceLoginStatus

@end

@implementation GLSSOServiceCore

//#ifdef DEBUG
//+ (void)load
//{
//    [[[self class] sharedInstance] loginStatus];
//}
//#endif

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
        
    }
    return self;
}

#pragma mark - Helpers
+ (NSString *)bundleSeedID {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge id)(kSecClassGenericPassword), kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge id)(kSecAttrAccessGroup)];
    NSArray *components = [accessGroup componentsSeparatedByString:@"."];
    NSString *bundleSeedID = [[components objectEnumerator] nextObject];
    CFRelease(result);
    return bundleSeedID;
}

- (void)debug
{
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    NSArray *secItemClasses = [NSArray arrayWithObjects:
                               (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecClassInternetPassword,
                               (__bridge id)kSecClassCertificate,
                               (__bridge id)kSecClassKey,
                               (__bridge id)kSecClassIdentity,
                               nil];
    for (id secItemClass in secItemClasses) {
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];
        
        CFTypeRef result = NULL;
        SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (result != NULL) CFRelease(result);
    }
}

- (void)clearAllKeysForAllApp
{
    NSArray *services = [self services];
    for (NSString *key in services)
    {
        UICKeyChainStore *store =[UICKeyChainStore keyChainStoreWithService:key accessGroup:[[self class] accessGroup]];
        [store removeAllItems];
    }
}

#pragma mark -

+ (NSString *)accessGroup
{
    NSString *seedID = [[self class] bundleSeedID];
    return [seedID stringByAppendingString:@".com.glowing.shared"];
}

- (NSString *)appSchemea
{
    return GLSSOServiceAppSchama;
}

- (NSArray *)services
{
    UICKeyChainStore *store =[UICKeyChainStore keyChainStoreWithService:GLSSOServiceAppInstalledAppsKey accessGroup:[[self class] accessGroup]];
    NSArray *items = [store allItems];
    items = [items valueForKeyPath:@"value"];
    return items;
}

- (UICKeyChainStore *)keychain
{
    static UICKeyChainStore *store;
    if (!store)
    {
        store = [UICKeyChainStore keyChainStoreWithService:[self appSchemea] accessGroup:[[self class] accessGroup]];
    }
    return store;
}

- (UICKeyChainStore *)installedAppsKeychain
{
    static UICKeyChainStore *store;
    if (!store)
    {
        store = [UICKeyChainStore keyChainStoreWithService:GLSSOServiceAppInstalledAppsKey accessGroup:[[self class] accessGroup]];
    }
    return store;
}

#pragma mark -
- (void)saveCurrentAppLoginStatusWithFirstname:(NSString *)firstname lastname:(NSString *)lastname token:(NSString *)token
{
    [self keychain][@"firstname"] = firstname;
    [self keychain][@"lastname"] = lastname;
    [self keychain][@"token"] = token;
    [self keychain][@"scheme"] = [self appSchemea];
    [self installedAppsKeychain][[self appSchemea]] = [self appSchemea];
}

- (void)removeCurrentAppLoginStatus
{
    [[self keychain] removeAllItems];
    [[self installedAppsKeychain] removeItemForKey:[self appSchemea]];
}

- (NSArray *)loginStatuses
{
#ifdef DEBUG
    [self debug];
#endif
    NSMutableArray *result = [@[] mutableCopy];
    NSArray *services = [self services];
    for (NSString *key in services)
    {
        UICKeyChainStore *store =[UICKeyChainStore keyChainStoreWithService:key accessGroup:[[self class] accessGroup]];
        if (store[@"token"])
        {
            GLLog(@"Found service for %@ name: %@ %@ token %@ scheme: %@",key,store[@"firstname"], store[@"lastname"],store[@"token"], store[@"scheme"]);
            if ([key isEqual:[self appSchemea]])
            {
                continue;
            }
            if (store[@"scheme"] && store[@"scheme"].length > 0)
            {
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://check.com/123", store[@"scheme"]]];
                if ([UIApplication sharedApplication] && ![[UIApplication sharedApplication] canOpenURL:url])
                {
                    GLLog(@"Found service for %@ but app no longer exsit",key);
                    continue;
                }
            }
            GLSSOServiceLoginStatus *status = [GLSSOServiceLoginStatus new];
            status.token = store[@"token"];
            status.firstname = store[@"firstname"];
            status.lastname = store[@"lastname"];
            status.schema = store[@"scheme"];
            [result addObject:status];
        }
        else
        {
            GLLog(@"Not found service for %@",key);
        }
    }
    if (self.preferedLoginStatusComparater)
    {
        [result sortUsingComparator:self.preferedLoginStatusComparater];
    }
    return result;
}

- (GLSSOServiceLoginStatus *)loginStatus
{
    return [[self loginStatuses] firstObject];
}

@end

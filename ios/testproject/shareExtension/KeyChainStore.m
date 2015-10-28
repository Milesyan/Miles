//
//  KeyChainStore.m
//  emma
//
//  Created by ltebean on 15/6/1.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "KeyChainStore.h"
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "Config.h"


@implementation KeyChainStore
+ (NSString *)accessGroup
{
    NSString *seedID = [[self class] bundleSeedID];
    return [seedID stringByAppendingString:@".com.glowing.shared"];
}

+ (NSString *)userToken
{
    UICKeyChainStore *store =[UICKeyChainStore keyChainStoreWithService:INSTALLED_APPS_KEY accessGroup:[[self class] accessGroup]];
    NSArray *items = [store allItems];
    
    items = [items valueForKeyPath:@"value"];
    for (NSString *key in items) {
        UICKeyChainStore *store =[UICKeyChainStore keyChainStoreWithService:key accessGroup:[[self class] accessGroup]];
        if ([key isEqual:EMMA_URL_SCHEME] && store[@"token"]) {
            return store[@"token"];
        }
    }
    return nil;
    
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


@end

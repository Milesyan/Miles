//
//  GLNameFormatter.m
//  kaylee
//
//  Created by Bob on 14-6-16.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLNameFormatter.h"

@import AddressBook;

@implementation GLNameFormatter

+ (NSString *)stringFromFirstName:(NSString *)firstName lastName:(NSString *)lastName
{
    ABRecordRef record = ABPersonCreate();
    if (record)
    {
        CFAutorelease(record);
    }
    ABRecordSetValue(record, kABPersonFirstNameProperty,
                     (__bridge CFStringRef)firstName, NULL);
    ABRecordSetValue(record, kABPersonLastNameProperty,
                     (__bridge CFStringRef)lastName, NULL);
    NSString *displayName = (__bridge NSString *)ABRecordCopyCompositeName(record);
    if (displayName)
    {
        CFAutorelease((__bridge CFTypeRef)(displayName));
    }
    return displayName ?: @"";
}

@end

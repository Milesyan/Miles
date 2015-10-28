//
//  GLNameFormatter.h
//  kaylee
//
//  Created by Bob on 14-6-16.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLNameFormatter : NSFormatter
+ (NSString *)stringFromFirstName:(NSString *)firstName lastName:(NSString *)lastName;

@end

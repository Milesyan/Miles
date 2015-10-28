//
//  GLSSOService.h
//  kaylee
//
//  Created by Bob on 14-7-8.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLSSOServiceCore.h"

@interface GLSSOService : NSObject

+ (instancetype)sharedInstance;
- (void)updateService;

@end

//
//  GLLoggerConfig.m
//  kaylee
//
//  Created by Bob on 14-9-23.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLLoggerConfig.h"

#ifdef ENABLE_KEYWORD_FILTER_ON_LOG
NSString *ENABLE_KEYWORD_FILTER_ON_LOG_VALUE = ENABLE_KEYWORD_FILTER_ON_LOG;
#else
NSString *ENABLE_KEYWORD_FILTER_ON_LOG_VALUE = nil;
#endif

#ifdef ENABLE_THESE_CLASS_LOG
NSString *ENABLE_THESE_CLASS_LOG_VALUE = ENABLE_THESE_CLASS_LOG;
#else
NSString *ENABLE_THESE_CLASS_LOG_VALUE = nil;
#endif


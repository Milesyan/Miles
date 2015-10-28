//
//  GLLog.h
//  kaylee
//
//  Created by Allen Hsu on 5/6/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#ifdef DEBUG
#   define GLLog(fmt, ...) GLLogMacroFunc(fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define GLLog(...)
#   define NSLog(...)
#endif

void GLLogMacroFunc(NSString* fmt, const char* prettyFunc, int line, ...);

@interface GLLogger : NSObject
+ (void)setLoggedClasses:(NSString *)classes;
+ (void)setLoggedKeywords:(NSString *)keywords;
+ (void)logWithFormat:(NSString *)format source:(NSString *)source line:(NSInteger)line args:(va_list)argList;
+ (void)setShowRegisteredClassLogOnly:(BOOL)value;
@end


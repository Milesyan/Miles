//
//  GLLog.m
//  kaylee
//
//  Created by Bob on 14-7-2.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLLog.h"
#import "GLUtils.h"
#import "NSString+Utils.h"
#import <objc/runtime.h>

@protocol GLRegisteredDynamicLogging
+ (BOOL)logMe;
@end

void GLLogMacroFunc(NSString* fmt,const char* prettyFunc, int line, ...)
{
    va_list arglist;
    va_start( arglist, line );
    [GLLogger logWithFormat:fmt source:@(prettyFunc) line:line args:arglist];
    va_end(arglist);
}


@implementation GLLogger

static NSArray *whiteListClassName = nil;
static BOOL showRegisteredClassLogOnly = NO;
static NSArray *keywordFilter = nil;

+ (void)setLoggedClasses:(NSString *)classes
{
    NSMutableArray *arr = [[classes componentsSeparatedByString:@","] mutableCopy];
    for (int i = 0; i < arr.count; i++)
    {
        arr[i] = [arr[i] trim];
    }
    whiteListClassName = arr.count == 0 ? nil : [arr copy];
    if (whiteListClassName.count > 0) {
        showRegisteredClassLogOnly = YES;
    } else {
        showRegisteredClassLogOnly = NO;
    }
}

+ (void)setLoggedKeywords:(NSString *)keywords
{
    NSMutableArray *arr = [[keywords componentsSeparatedByString:@","] mutableCopy];
    for (int i = 0; i < arr.count; i++)
    {
        arr[i] = [arr[i] trim];
    }
    keywordFilter = arr.count == 0 ? nil : [arr copy];
}

+ (void)logWithFormat:(NSString *)format source:(NSString *)source line:(NSInteger)line args:(va_list)argList
{
    NSString *str = [[NSString alloc] initWithFormat:format arguments:argList];
    if (keywordFilter)
    {
        BOOL result = NO;
        for (NSString *keyword in keywordFilter)
        {
            if ([str rangeOfString:keyword].location != NSNotFound)
            {
                result = YES;
                break;
            }
        }
        if (!result)
        {
            return;
        }
    }
    if (showRegisteredClassLogOnly)
    {
        NSArray *stack = [NSThread callStackSymbols];
        Class cls;
        if (stack.count >= 3)
        {
            NSString *classCaller;
            NSString *sourceString = stack[2];
            NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@" -[]+?.,"];
            NSMutableArray *array = [NSMutableArray arrayWithArray:[sourceString  componentsSeparatedByCharactersInSet:separatorSet]];
            [array removeObject:@""];
            if (array.count >= 4)
            {
                classCaller = array[3];
                cls = NSClassFromString(classCaller);
            }
        }
        if (![GLLogger shouldShowLogForClass:cls])
        {
            return;
        }
    }
    NSLog(@"(%@ LINE: %ld) %@",source, (long)line, str);//this is sync
}

+ (void)setShowRegisteredClassLogOnly:(BOOL)value
{
    showRegisteredClassLogOnly = value;
}


#pragma mark -

+ (BOOL)shouldShowLogForClass:(Class)aClass
{
    NSString *className = NSStringFromClass(aClass);
    NSUInteger index = [whiteListClassName indexOfObject:className];
    if (index != NSNotFound)
    {
        return YES;
    }
    if ([self isRegisteredClass:aClass])
    {
        return [aClass logMe];
    }
    
    return NO;
}

+ (BOOL)isRegisteredClass:(Class)cls
{
    SEL getterSel = @selector(logMe);
    
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
    BOOL result = NO;
    
    unsigned int methodCount, i;
    Method *methodList = class_copyMethodList(object_getClass(cls), &methodCount);
    
    if (methodList != NULL)
    {
        for (i = 0; i < methodCount; ++i)
        {
            SEL currentSel = method_getName(methodList[i]);
            
            if (currentSel == getterSel)
            {
                result = YES;
                break;
            }
        }
        
        free(methodList);
    }
    
    return result;
    
#else

    Method getter = class_getClassMethod(cls, getterSel);
    
    if ((getter != NULL))
    {
        return YES;
    }
    
    return NO;
    
#endif
}

+ (NSArray *)registeredClasses
{
    NSUInteger numClasses, i;
    
    // We're going to get the list of all registered classes.
    // The Objective-C runtime library automatically registers all the classes defined in your source code.
    //
    // To do this we use the following method (documented in the Objective-C Runtime Reference):
    //
    // int objc_getClassList(Class *buffer, int bufferLen)
    //
    // We can pass (NULL, 0) to obtain the total number of
    // registered class definitions without actually retrieving any class definitions.
    // This allows us to allocate the minimum amount of memory needed for the application.
    
    numClasses = (NSUInteger)MAX(objc_getClassList(NULL, 0), 0);
    
    // The numClasses method now tells us how many classes we have.
    // So we can allocate our buffer, and get pointers to all the class definitions.
    
    Class *classes = numClasses ? (Class *)malloc(sizeof(Class) * numClasses) : NULL;
    if (classes == NULL) return nil;
    
    numClasses = (NSUInteger)MAX(objc_getClassList(classes, (int)numClasses), 0);
    
    // We can now loop through the classes, and test each one to see if it is a DDLogging class.
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:numClasses];
    
    for (i = 0; i < numClasses; i++)
    {
        Class cls = classes[i];
        
        if ([self isRegisteredClass:cls])
        {
            [result addObject:cls];
        }
    }
    
    free(classes);
    
    return result;
}

+ (NSArray *)registeredClassNames
{
    NSArray *registeredClasses = [self registeredClasses];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[registeredClasses count]];
    
    for (Class cls in registeredClasses)
    {
        [result addObject:NSStringFromClass(cls)];
    }
    
    return result;
}

@end
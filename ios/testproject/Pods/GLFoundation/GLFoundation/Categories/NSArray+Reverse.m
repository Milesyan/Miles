//
//  NSArray+Reverse.m
//  Pods
//
//  Created by Eric Xu on 12/14/14.
//
//

#import "NSArray+Reverse.h"

@implementation NSArray (Reverse)
- (NSArray *)reversedArray {
    return [[self reverseObjectEnumerator] allObjects];
}

@end

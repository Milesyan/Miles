//
//  pubSubTest.h
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

@interface pubSubTest : SenTestCase
- (void)block:(NSInteger)condition;
- (void)unblock:(NSInteger)condition;
@end

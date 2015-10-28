//
//  PredictorTest.m
//  emma
//
//  Created by Xin Zhao on 13-3-7.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "PredictorTest.h"
#import "Interpreter.h"
#import "Utils.h"

@interface PredictorTest() {
    NSConditionLock *condLock;
    NSTimeInterval timeout;
}
- (void)block:(NSInteger)condition;
- (void)unblock:(NSInteger)condition;
@end

@implementation PredictorTest
- (void)setUp {
    [super setUp];
    condLock = [NSConditionLock new];
    timeout = 1.0f;
}

- (void)block:(NSInteger)condition {
    BOOL result = [condLock lockWhenCondition:condition beforeDate:[NSDate dateWithTimeIntervalSinceNow:timeout]];
    STAssertTrue(result, @"Async operation timed out.");
}

- (void)unblock:(NSInteger)condition {
    [condLock unlockWithCondition:condition];
}

- (void)testDateWithDateLabel {
    NSDate *d1 = [Utils dateOfYear:2013 month:2 day:30];
    NSDate *d2 = [Utils dateWithDateLabel:@"2013/02/30"];
    STAssertEqualDate(d1, d2, nil);
}

- (void)testDatesUtils {
    NSString *datestrAfter = [Utils dateLabelAfterDateLabel:@"2013/02/27" withDays:2];
    STAssertTrue([datestrAfter isEqual:@"2013/03/01"], nil);
    
    NSString *datestrBefore = [Utils dateLabelBeforeDateLabel:@"2013/02/27" withDays:2];
    STAssertTrue([datestrBefore isEqual:@"2013/02/25"], nil);
    
    NSNumber *days = [Utils daysBeforeDateLabel:@"2013/02/26" sinceDateLabel:@"2013/03/02"];
    GLLog(@"testDatesUtil %@", days);
    STAssertTrue([days intValue] == -4, nil);
    
    NSArray *dateLabels = @[@"2013/12/12", @"2014/01/01", @"2014/07/01"];
    id maxDateLabel = [Utils maxDateLabelIn:dateLabels];
    GLLog(@"testDatesUtil %@", maxDateLabel);
    STAssertTrue([maxDateLabel isEqual:@"2014/07/01"], nil);
}

- (void)testSomething {
    //Interpreter *interpreter = [[Interpreter alloc] init];
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSMutableDictionary dictionaryWithObjectsAndKeys: @0, @"b", nil], @"a", nil];
    NSMutableDictionary *s = [d objectForKey:@"a"];
    [s setValue:@1 forKey:@"b"];
    double dn = 20.0;
    NSNumber *n = [NSNumber numberWithInt:dn / 10];
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[@"v",@"s"] options:0 error:nil];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    GLLog(@"test sth: %@", str);
    data = [@"[\"v\", \"s\"]" dataUsingEncoding:NSUTF8StringEncoding];
    NSArray *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    GLLog(@"test sth: %@", dict);
    GLLog(@"test NSNull: %@", [NSNull null] ? @1 : @0);
    GLLog(@"test print nil: %@", nil);
    GLLog(@"test print NSNull: %@", [NSNull null]);
}

- (void)testGetVar {
    NSArray *dsl = @[@"v", @"s"];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testGetVar result: %@", s);
    STAssertTrue([s intValue] == 1, nil);
}

- (void)testSetVar {
    NSArray *dsl = @[@"=", @"s", @5];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testSetVar result: %@", s);
    STAssertTrue([[interpreter.localVars objectForKey:@"s"] integerValue] == 5, nil);
}

- (void)testGet1D {
    NSArray *dsl = @[@"[]", @"s", @3];
    NSArray *local1DVar = @[@[], @1, @"2", @NO];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local1DVar, @"s", nil]];
    GLLog(@"testGet1D result: %@", s);
    STAssertTrue([s isEqual:@NO], nil);
}

- (void)testGet2D {
    NSArray *dsl = @[@"[][]", @"s", @3, @"x"];
    NSArray *local2DVar = @[@NO, @1, @"2", [NSDictionary dictionaryWithObjectsAndKeys:@99, @"x", @88, @"y", nil]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testGet2D result: %@", s);
    STAssertTrue([s isEqual:@99], nil);
}

- (void)testSet1D {
    NSArray *dsl = @[@"[]=", @"s", @"2", @"x"];
    NSMutableDictionary *local1DVar = [NSMutableDictionary dictionaryWithDictionary:@{@NO: @1, @"2": @[@99, @"x", @88, @"y"]}];
    Interpreter *interpreter = [[Interpreter alloc] init];
    [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local1DVar, @"s", nil]];
    GLLog(@"testGet1D result: %@", interpreter.localVars);
    STAssertTrue([[[interpreter.localVars objectForKey:@"s"] objectForKey:@"2"] isEqual:@"x"], nil);
}

- (void)testSet2D {
    NSArray *dsl = @[@"[][]=", @"s", @3, @2, @777];
    NSArray *local2DVar = @[@NO, @1, @"2", [NSMutableDictionary dictionaryWithObjectsAndKeys:@99, @"x", @88, @"y", nil]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testSet2D result: %@", interpreter.localVars);
    STAssertTrue([[[[interpreter.localVars objectForKey:@"s"] objectAtIndex:3] objectForKey:@2] isEqual:@777], nil);
}


- (void)testPlus {
    NSArray *dsl = @[@"+", @[@"v", @"s"], @5];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testPlus result: %@", s);
    STAssertTrue([s intValue] == 6, nil);
    
    dsl = @[@"+", @"2013/02/28", @5];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testMinus result: %@", s);
    STAssertTrue([s isEqual:@"2013/03/05"], nil);
}

- (void)testMinu {
    NSArray *dsl = @[@"-", @[@"v", @"s"], @5];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testMinus result: %@", s);
    STAssertTrue([s intValue] == -4, nil);
    
    dsl = @[@"-", @"2013/02/28", @5];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testMinus result: %@", s);
    STAssertTrue([s isEqual:@"2013/02/23"], nil);
    
    dsl = @[@"-", @"2013/02/28", @"2013/02/20"];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testMinus result: %@", s);
    STAssertTrue([s intValue] == 8, nil);
}

- (void)testEquals {
    NSArray *dsl = @[@"==", @5, @[@"v", @"s"]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@5, @"s", nil]];
    GLLog(@"testEquals result: %@", s);
    STAssertTrue([s isEqual:@YES], nil);

    dsl = @[@"==", @"hahaha", @"hohoho"];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testEquals result: %@", s);
    STAssertTrue([s isEqual:@NO], nil);
}

- (void)testNotEquals {
    NSArray *dsl = @[@">", @5, @[@"v", @"s"]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testNotEquals result: %@", s);
    STAssertTrue([s isEqual:@YES], nil);
    
    dsl = @[@"<", @5, @5];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testNotEquals result: %@", s);
    STAssertTrue([s isEqual:@NO], nil);
}

- (void)testMax {
    NSArray *dsl = @[@"max", @8, @7, @4];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testMax result: %@", s);
    STAssertTrue([s isEqual:@8], nil);
    
    dsl = @[@"max", @"2012/12/21", @"1999/07/01", @"2046/01/01"];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testMax result: %@", s);
    STAssertTrue([s isEqual:@"2046/01/01"], nil);
}

- (void)testAvgAndRound {
    NSArray *dslWithRound = @[@"round", @[@"avg", @3, @[@"v",@"s"], @"x"]];
    NSArray *dslWithoutRound = @[@"avg", @3, @[@"v",@"s"], @"x"];
    NSArray *local2DVar = @[[NSMutableDictionary dictionaryWithObjectsAndKeys:@1, @"x", @88, @"y", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@4, @"x", @88, @"y", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@5, @"x", @88, @"y", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@7, @"x", @88, @"y", nil]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dslWithRound withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testAvgAndRound result: %@", s);
    STAssertEquals([s intValue], 3, nil);
    s = [interpreter exeDsl:dslWithoutRound withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testAvgAndRound result: %@", s);
    STAssertEqualsWithAccuracy([s floatValue], 10.0f / 3, 0.000001f, nil);
}

- (void)testGetCount {
    NSArray *dsl = @[@"len", @[@"v", @"s"]];
    NSArray *local1DVar = @[@[], @1, @"2", @NO];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local1DVar, @"s", nil]];
    GLLog(@"testGetCount result: %@", s);
    STAssertTrue([s isEqual:@4], nil);
}

- (void)testFindClosestPb {
    NSArray *dsl = @[@"closest", @"2013/03/06", @[@"v",@"s"]];
    NSArray *local2DVar = @[[NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/01/06", @"pb", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/02/28", @"pb", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/03/11", @"pb", nil],
                            [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/04/01", @"pb", nil]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testFindClosestPb result: %@", s);
    STAssertEquals([s intValue], 2, nil);
    
    local2DVar = @[[NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/03/05", @"pb", nil],
                    [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/03/22", @"pb", nil],
                    [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/04/11", @"pb", nil],
                    [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/05/01", @"pb", nil]];
    s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testFindClostestPb result: %@", s);
    STAssertEquals([s intValue], 0, nil);
    
    local2DVar = @[[NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/01/05", @"pb", nil],
                   [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/01/22", @"pb", nil],
                   [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/02/11", @"pb", nil],
                   [NSMutableDictionary dictionaryWithObjectsAndKeys:@"2013/03/04", @"pb", nil]];
    s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:local2DVar, @"s", nil]];
    GLLog(@"testFindClostestPb result: %@", s);
    STAssertEquals([s intValue], 3, nil);
}


- (void)testReturn {
    NSArray *dsl = @[@"return", @5];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testReturn result: %@", s);
    STAssertTrue([s integerValue] == 5, nil);

    dsl = @[@"return", @[@"v", @"s"]];
    s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"s", nil]];
    GLLog(@"testReturn result: %@", s);
    STAssertTrue([s integerValue] == 1, nil);

}

- (void)testIf {
    NSArray *dsl = @[@"if", @YES, @3, @4];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testIf result: %@", s);
    STAssertTrue([s integerValue] == 3, nil);

    dsl = @[@"if", @NO, @3, @4];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testIf result: %@", s);
    STAssertTrue([s integerValue] == 4, nil);

    
    dsl = @[@"if", @NO, @3,  @YES, @[@"=", @"a", @1], @4];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testIf result: %@", s);
    STAssertTrue(s == nil, nil);
    
    dsl = @[@"if", @NO, @3,  @YES, @[@"return", @5], @4];
    s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testIf result: %@", s);
    STAssertTrue([s integerValue] == 5, nil);
}

- (void)testSeq {
    NSArray *dsl = @[@"seq", @[@"=", @"a", @1], @[@"return", @[@"v", @"b"]], @[@"=", @"a", @2]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@1, @"b", nil]];
    GLLog(@"testSeq result: %@", interpreter.localVars);
    STAssertTrue([[interpreter.localVars objectForKey:@"a"] integerValue] == 1, nil);
    STAssertTrue([s integerValue] == 1, nil);
}

- (void)testFor {
    NSArray *dsl = @[@"for", @"x", @1, @9, @[@"=", @"a", @[@"v", @"x"]], @[@"return", @2]];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testFor result: %@", interpreter.localVars);
    STAssertTrue([[interpreter.localVars objectForKey:@"a"] integerValue] == 1, nil);
    STAssertTrue([s integerValue] == 2, nil);
}

- (void)testLogicAnd {
    NSArray *dsl = @[@"&&", @YES, @1];
    Interpreter *interpreter = [[Interpreter alloc] init];
    id s = [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testFor result: %@", interpreter.localVars);
    STAssertTrue([s boolValue] == YES, nil);
    
    dsl = @[@"&&", @YES, @1, @[@"v", @"b"]];
    s = [interpreter exeDsl:dsl withArgs:[NSDictionary dictionaryWithObjectsAndKeys:@NO, @"b", nil]];
    GLLog(@"testFor result: %@", interpreter.localVars);
    STAssertTrue([s boolValue] == NO, nil);
}

- (void)testEmptyPrediction {
    NSMutableArray *prediction = [Utils emptyPrediction];
    GLLog(@"testEmptyPrediction %@", prediction);
    STAssertTrue([prediction count] == 13, nil);
}

- (void)testInitDictionary {
    NSArray *dsl = @[@"initdict", @"d"];
    Interpreter *interpreter = [[Interpreter alloc] init];
    [interpreter exeDsl:dsl withArgs:nil];
    GLLog(@"testInitdict result: %@", interpreter.localVars);
    //STAssertTrue([s boolValue] == YES, nil);

}

@end

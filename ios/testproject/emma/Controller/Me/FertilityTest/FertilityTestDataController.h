//
//  FertilityTestDataController.h
//  emma
//
//  Created by Peng Gu on 7/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FertilityTestDataController : NSObject

@property (nonatomic, assign) BOOL isOnboarding;
@property (nonatomic, strong) NSDictionary *answeredTests;
@property (nonatomic, assign, readonly) NSInteger numberOfAnsweredQuestions;

- (instancetype)initWithTableView:(UITableView *)tableView onboarding:(BOOL)onboarding;

- (BOOL)saveData;

@end

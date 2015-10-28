//
//  AppPurposesManager.h
//  emma
//
//  Created by Xin Zhao on 13-12-11.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "User.h"

//@interface AppPurposesSwitchResult : NSObject
//
//@property (nonatomic) BOOL canSwitch;
//@property (nonatomic) NSArray *missingFieldPaths;
//
//@end

@interface AppPurposesManager : NSObject

@property (nonatomic, weak) UIViewController *viewController;
@property (nonatomic, strong) User *user;
@property (nonatomic, assign) BOOL promoPregnancyApp;

- (instancetype)initWithViewController:(UIViewController *)viewController user:(User *)user;

- (NSArray *)missedSettingsForPurpose:(AppPurposes)purpose;
- (void)switchingToPurpose:(AppPurposes)purpose;
- (void)openPromoPregnancyApp;

- (NSString *)descriptionForCurrentStatus;

@end

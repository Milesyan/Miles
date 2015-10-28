//
//  AppDelegate.h
//  emma
//
//  Created by Ryan Ye on 1/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AppsFlyerTracker.h"
#import <UIKit/UIKit.h>
#import "User.h"
#import "FacebookSDK/FacebookSDK.h"
#import "KKPasscodeLock.h"

typedef enum {
    AppUpgradeDialogPresentTypeRemind = 0,
    AppUpgradeDialogPresentTypeEnforce
} AppUpgradeDialogPresentType;

@interface AppOpenData : NSObject
@property (nonatomic) NSNumber * openType;
@property (nonatomic) NSNumber * data1;
@property (nonatomic) NSNumber * data2;
@property (nonatomic) NSString * url;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate, KKPasscodeViewControllerDelegate, AppsFlyerTrackerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (readonly) User *user;
@property (readonly) FBSession *session;
@property (strong, nonatomic) UIViewController *viewControllerToPresentAfterMain;

- (void)pushDialog:(id)dialog;
- (void)setRotationEnabled:(BOOL)enabled;
+ (UIViewController*) topMostController;
@end

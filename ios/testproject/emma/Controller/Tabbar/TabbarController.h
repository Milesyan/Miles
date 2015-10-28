//
//  TabbarController.h
//  emma
//
//  Created by Eric Xu on 10/11/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define TABBAR_NAME_HOME   @"home"
#define TABBAR_NAME_GENIUS @"genius"
#define TABBAR_NAME_COMM   @"comm"
#define TABBAR_NAME_ALERT  @"alert"
#define TABBAR_NAME_ME     @"me"

@interface TabbarController : UITabBarController

@property (nonatomic) BOOL hidden;

+ (TabbarController *)getInstance:(UIViewController *)viewController;
- (void)reloadTabbarsForced:(BOOL)forced;
- (void)rePerformFundSegue;
- (void)selectFundPage;
- (void)goPregnantPage;
- (void)selectForumPage;
- (void)selectGeniusPage;
- (void)selectHomePage;
- (void)selectMePage;
- (void)selectAlertPage;

- (void)goToFertitliyTreatmentPage:(id)sender;

- (void)hideWithAnimation:(BOOL)animation;
- (void)showWithAnimation:(BOOL)animation;
- (void)selectPageIndex:(NSUInteger)index;
- (void)updateCommunityNewRedDot;

- (void)showRedDotViewOnTab:(NSString *)tabName;
- (void)hideRedDotViewOnTab:(NSString *)tabName;

@end

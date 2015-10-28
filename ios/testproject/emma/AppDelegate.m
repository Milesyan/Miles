//
//  AppDelegate.m
//  emma
//
//  Created by Ryan Ye on 1/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLCommunity/Forum.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <GLFoundation/GLUtils.h>

#ifndef DEBUG
#import <Rollout/Rollout.h>
#endif


#import "EmmaForum.h"
#import "AppsFlyerTracker.h"
#import "AppDelegate.h"
#import "KKPasscodeLock.h"
#import "StatusBarOverlay.h"
#import "AppUpgradeDialog.h"
#import "ChartData.h"
#import "Logging.h"
#import "User.h"
#import "User+Misfit.h"
#import "UIStoryboard+Emma.h"
#import "Sendmail.h"
#import "LocalNotification.h"
#import "TabbarController.h"
#import "ForumTopicDetailViewController.h"
#import "ForumTopicsViewController.h"
#import "PushableDialog.h"
#import "Nutrition.h"
#import "DataStore.h"
#import "Forum.h"
#import "RestoreDataViewController.h"
#import "LocalResourceHttpURLProtocol.h"
#import "BannerNotificationView.h"
#import "GLSSOService.h"
#import "PushablePresenteeNavigationController.h"
#import "ForumHotViewController.h"
#import "WalgreensManager.h"
#import "StartupViewController.h"
#import "WatchDataController.h"
#import <GLPeriodEditor/GLPeriodEditorAppearance.h>
#import "RatingCell.h"
#import "HealthKitManager.h"

#define UPDATED_TO_VERSION_40 @"UPDATED_TO_VERSION_40"

#define LAST_ACTIVE_TIME @"lastActiveTime"

//10 minutes

@interface PasscodeWindow : UIWindow<KKPasscodeViewControllerDelegate> {
    UIImageView *imageView;
    KKPasscodeViewController *vc;
    UINavigationController *nav;
    BOOL presented;
}
@end

@implementation PasscodeWindow
- (id)initWithFrame:(CGRect)frame delegate:(AppDelegate *)delegate {
    self = [super initWithFrame:frame];
    if (self) {
        self.hidden = NO;
        self.opaque = YES;
        self.backgroundColor = [UIColor clearColor];
        self.windowLevel = UIWindowLevelAlert + 2.0f;
        [self makeKeyAndVisible];
        
        UIViewController *rvc = [[UIViewController alloc] initWithNibName:nil bundle:nil];
        
        [self setRootViewController:rvc];
        
        vc = [[KKPasscodeViewController alloc] initWithNibName:nil bundle:nil];
        vc.mode = KKPasscodeModeEnter;
        vc.delegate = delegate;

        if ([vc respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
            [vc setEdgesForExtendedLayout:UIRectEdgeNone];
        }

        nav = [[UINavigationController alloc] initWithRootViewController:vc];
    }
    return self;
}

- (void)presentPasscodeWindow {
    if (presented) return;
    presented = YES;
    self.hidden = NO;
    [self.rootViewController presentViewController:nav animated:NO completion:^(void){}];
}

- (void)dismissPasscodeWindow {
    presented = NO;
    self.hidden = YES;
//    UIViewController *navigationController = self.rootViewController.view.window == nil ? self.rootViewController.presentedViewController : self.rootViewController;
    [self.rootViewController dismissViewControllerAnimated:NO completion:nil];
}

@end

@implementation AppOpenData

@end

@interface AppDelegate() {
    PasscodeWindow *passcodeWindow;
    NSMutableArray *dialogsAfterPasscode;
    BOOL rotationEnabled;
}
- (void)customizeSkin;
@end

@implementation AppDelegate

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply
{
    NSLog(@"Peng debug received request from watch: %@", userInfo);
    [[WatchDataController sharedInstance] handleWatchRequest:userInfo withReply:reply];
}


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL clearData = [[NSUserDefaults standardUserDefaults] boolForKey:CLEAR_CACHE_ON_LAUNCH];
    if (clearData) {
        [Utils clearAllAppData];
    }
    
    // if this is updating to 4.0.0, we do symptoms migration
//    BOOL updatedToVersion40 = [[NSUserDefaults standardUserDefaults] boolForKey:UPDATED_TO_VERSION_40];
//    if (!updatedToVersion40 && [[Utils appVersion] isEqualToString:@"4.0.0"]) {
//        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:UPDATED_TO_VERSION_40];
//        [SymptomMigrationPolicy migrateSymptoms];
//    }
    
    // init watch data controller
    WatchDataController *watchDataController = [WatchDataController sharedInstance];
    if (![User currentUser]) {
        [watchDataController passWatchData];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Setup Rollout.io
#ifndef DEBUG
    [Rollout setupWithDebug:NO];
#endif
    
    [CrashReport start];
    
    [self publish:EVENT_APP_DID_LAUNCH];
    
    GLLog(@"app did finish launching with options: %@", launchOptions);
    #ifdef EMMA_RESTORE_FROM_DATA_SNAPSHOT
    self.window.rootViewController = [[RestoreDataViewController alloc] initWithUserToken:EMMA_RESTORE_FROM_DATA_SNAPSHOT];
    return YES;
    #endif
    self.window.backgroundColor = [UIColor whiteColor];

    [Utils startProfileTimer];
    [[KKPasscodeLock sharedLock] setDefaultSettings];
    [KKPasscodeLock sharedLock].eraseOption = NO;
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:50 * 1024 * 1024 diskCapacity:100 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
    [NSURLProtocol registerClass:[LocalResourceHttpURLProtocol class]];
    
    [self customizeSkin];
    [NSObject setPubSubQueue:[NSOperationQueue mainQueue]];
    [StatusBarOverlay sharedInstance];
    
    EmmaForum *forum = [[EmmaForum alloc] init];
    [[Forum sharedInstance] setDelegate:forum];
    [[Forum sharedInstance] setBaseURL:EMMA_BASE_URL];
    
    if ([User currentUser]) {
        [[User currentUser] applyDailyDataFrom:DEFAULT_PB_LABEL];
        //transmit hidden DL keys with a new key
        User *u = [User currentUser];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults boolForKey:USER_DEFAULTS_KEY_PREDICTION_SWITCH_INITED]) {
            u.settings.predictionSwitch = 1;
            [defaults setBool:YES forKey:USER_DEFAULTS_KEY_PREDICTION_SWITCH_INITED];
        }
        GLLog(@"Before Token %@",u.encryptedToken);
        [u updateUserTokenWithCompletionHandler:^(NSError *e)
         {
             GLLog(@"After Token %@",u.encryptedToken);
         }];
        [Utils transmitHiddenDailyLogDefaultsForUserId:[u.id stringValue]
            token:u.encryptedToken];
        // migrate old reminders
        [Reminder migrateOldRemindersForUser:u];
    }
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound) categories:nil]];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    
    // app upgrade dialog
    [AppUpgradeDialog getInstance];
    
    // launchTimes
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *launchTimes = [defaults objectForKey:@"launchTimes"];
    int _ltimes = launchTimes ? [launchTimes intValue] : 0;
    [defaults setObject:@(_ltimes + 1) forKey:@"launchTimes"];
    
    // first launch date
    NSDate *firstLaunch = [defaults objectForKey:@"firstLaunch"];
    if (!firstLaunch) {
        [defaults setObject:[NSDate date] forKey:@"firstLaunch"];
        [Logging syncLog:IOS_APP_FIRST_LAUNCH eventData:nil];
    }

    // Remind Rate Time
    NSDate *remindRateTime = [defaults objectForKey:@"remindRateTime"];
    if (!remindRateTime) {
        [defaults setObject:[NSDate date] forKey:@"remindRateTime"];
    }
    
    [defaults removeObjectForKey:LAST_ACTIVE_TIME];
    [defaults removeObjectForKey:NUTRITION_DATA_MANUALLY_SYNCED];
    
    [defaults synchronize];
    
    NSDictionary *remoteNotif = [launchOptions objectForKey: UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotif) {
        NSLog(@"Peng debug handle launch with notification");
        [self handleLaunchWithNotification:application userInfo:remoteNotif];
    }
    
    dialogsAfterPasscode = [NSMutableArray array];

    if ([MFMailComposeViewController canSendMail]) {
        [Sendmail prepare];        
    }

    application.statusBarHidden = NO;

//    GLLog(@"localNotifications:%@", [[UIApplication sharedApplication] scheduledLocalNotifications]);

    [self checkComeBackStuff];
//    if ([self user]) {
//        [[self user] syncUserDefaults];
//    }
   
    [AppsFlyerTracker sharedTracker].appsFlyerDevKey = @"s5wN9UNju6jPo2WQ6dXZDJ";
    [AppsFlyerTracker sharedTracker].appleAppID = APP_ID;
    
    [[GLSSOService sharedInstance] updateService];
    
    // in case it was set to yes
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION withValue:nil];

    [RatingCell logLaunch];
    
    // fix invalid data with date 0000/00/00
    [UserDailyData clearDataOnZeroDate];
    
    return YES;
}


- (void)customizeSkin
{
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor whiteColor];
    shadow.shadowOffset = CGSizeMake(0, 0);
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [Utils semiBoldFont:24],
                            NSForegroundColorAttributeName: UIColorFromRGB(0x5b5b5b),
                            NSShadowAttributeName: shadow
    };
    [[UINavigationBar appearance] setTitleTextAttributes:attrs];
    // slider skin
    UIImage *sliderMaxImage = [[UIImage imageNamed:@"slider-gray-right"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
    UIImage *sliderMinImage = [[UIImage imageNamed:@"slider-orange-left"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    UIImage *thumbImage = [UIImage imageNamed:@"slider-dial"];
    [[UISlider appearance] setMaximumTrackImage:sliderMaxImage forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:sliderMinImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateHighlighted];
    
    //tabbar skin
    [[UITabBar appearance] setSelectionIndicatorImage:[Utils imageWithColor:UIColorFromRGBA(0x11223300) andSize:CGSizeMake(30, 30)]];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColorFromRGB(0x6c6dd3)}
                                             forState:UIControlStateSelected];

    [[UINavigationBar appearance] setTintColor:UIColorFromRGB(0x6c6dd3)];
    // Button text color in UISearchBar
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName: GLOW_COLOR_PURPLE} forState:UIControlStateNormal];
    
    if ([[UINavigationBar class] instancesRespondToSelector:@selector(setBackIndicatorImage:)])
    {
        UINavigationBar* appearanceNavigationBar = [UINavigationBar appearance];
        appearanceNavigationBar.backIndicatorImage = [UIImage imageNamed:@"back-with-padding"];
        appearanceNavigationBar.backIndicatorTransitionMaskImage = [UIImage imageNamed:@"back-with-padding"];
    }
    [self setupStatusBarStyles];
    
    [GLPeriodEditorAppearance setupAppearance];
}

- (void)setupStatusBarStyles {
    [JDStatusBarNotification setDefaultStyle:^JDStatusBarStyle *(JDStatusBarStyle *style) {
        style.barColor = GLOW_COLOR_PURPLE;
        style.textColor = [UIColor whiteColor];
        style.font = [GLTheme boldFont:13.0];
        style.animationType = JDStatusBarAnimationTypeFade;
        style.textShadow = nil;
        style.textVerticalPositionAdjustment = 0.0;
        style.progressBarColor = GLOW_COLOR_LIGHT_PURPLE;
        style.progressBarHeight = 20.0;
        style.progressBarPosition = JDStatusBarProgressBarPositionTop;
        return style;
    }];
    
    [JDStatusBarNotification addStyleNamed:GLStatusBarStyleError prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
        style.barColor = [UIColor darkGrayColor];
        style.textColor = [UIColor whiteColor];
        style.font = [GLTheme boldFont:13.0];
        style.animationType = JDStatusBarAnimationTypeFade;
        style.textShadow = nil;
        style.textVerticalPositionAdjustment = 0.0;
        style.progressBarColor = [UIColor grayColor];
        style.progressBarHeight = 20.0;
        style.progressBarPosition = JDStatusBarProgressBarPositionTop;
        return style;
    }];
    
    [JDStatusBarNotification addStyleNamed:GLStatusBarStyleWarning prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
        style.barColor = [UIColor darkGrayColor];
        style.textColor = [UIColor whiteColor];
        style.font = [GLTheme boldFont:13.0];
        style.animationType = JDStatusBarAnimationTypeFade;
        style.textShadow = nil;
        style.textVerticalPositionAdjustment = 0.0;
        style.progressBarColor = [UIColor grayColor];
        style.progressBarHeight = 20.0;
        style.progressBarPosition = JDStatusBarProgressBarPositionTop;
        return style;
    }];
    
    [JDStatusBarNotification addStyleNamed:GLStatusBarStyleSuccess prepare:^JDStatusBarStyle *(JDStatusBarStyle *style) {
        style.barColor = GLOW_COLOR_GREEN;
        style.textColor = [UIColor whiteColor];
        style.font = [GLTheme boldFont:13.0];
        style.animationType = JDStatusBarAnimationTypeFade;
        style.textShadow = nil;
        style.textVerticalPositionAdjustment = 0.0;
        style.progressBarColor = GLOW_COLOR_GREEN;
        style.progressBarHeight = 20.0;
        style.progressBarPosition = JDStatusBarProgressBarPositionTop;
        return style;
    }];
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [self publish:EVENT_APP_BECOME_INACTIVE];
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    GLLog(@"applicationDidEnterBackground");
    if (IOS9_OR_ABOVE) {
        [[HealthKitManager sharedInstance] pushPeriods];
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:LAST_ACTIVE_TIME];
    [defaults synchronize];
    [Logging syncLog:IOS_APP_EXIT eventData:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    GLLog(@"applicationWillEnterForeground");
    [self checkComeBackStuff];
}

- (void)checkComeBackStuff {
    if ([User currentUser]) {
        [[User currentUser] updateLastSeen];
        if ([self user].onboarded) {
            [[self user] refresh];
        }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *lastActiveTime = [defaults objectForKey:LAST_ACTIVE_TIME];
    float secondsSinceLastActive = APP_ACTIVE_TIMEOUT+1;
    if (lastActiveTime) {
        secondsSinceLastActive = [[NSDate date] timeIntervalSince1970] - [lastActiveTime timeIntervalSince1970];
    }
    
    if ([[KKPasscodeLock sharedLock] isPasscodeRequired] && self.user && secondsSinceLastActive > APP_ACTIVE_TIMEOUT) {
        [dialogsAfterPasscode removeAllObjects];
        if (!passcodeWindow) {
            passcodeWindow = [[PasscodeWindow alloc] initWithFrame:CGRectMake(0, 20, SCREEN_WIDTH, SCREEN_HEIGHT - 20) delegate:self];
        }
        [passcodeWindow makeKeyAndVisible];
        [passcodeWindow presentPasscodeWindow];
        
        for (UIWindow* window in [UIApplication sharedApplication].windows) {
            NSArray* subviews = window.subviews;
            if ([subviews count] > 0)
                if ([[subviews objectAtIndex:0] isKindOfClass:[UIAlertView class]]) {
                    UIAlertView *alert = [subviews objectAtIndex:0];
                    [alert dismissWithClickedButtonIndex:0 animated:NO];
                    [dialogsAfterPasscode addObject:alert];
                }
            
        }
    }
    
    [defaults setObject:[NSDate date] forKey:LAST_ACTIVE_TIME];
    [defaults synchronize];
    
    [Logging log:IOS_APP_OPEN];
    
    //[self publish:EVENT_APP_BECOME_ACTIVE];
    
    // add cookie
    if (![Utils isEmptyString:WEB_ACCESS_TOKEN]) {
        // cookie could not shared to safari
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
        
        NSURL * url = [NSURL URLWithString:EMMA_BASE_URL];
        NSString * domain = [url host];
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        [cookieProperties setObject:WEB_TOKEN_COOKIE_NAME forKey:NSHTTPCookieName];
        [cookieProperties setObject:WEB_ACCESS_TOKEN forKey:NSHTTPCookieValue];
        [cookieProperties setObject:domain forKey:NSHTTPCookieDomain];
        [cookieProperties setObject:domain forKey:NSHTTPCookieOriginURL];
        [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
        [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
        
        // set expiration to one month from now or any NSDate of your choosing
        // this makes the cookie sessionless and it will persist across web sessions and app launches
        /// if you want the cookie to be destroyed when your app exits, don't set this
        [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval: 3600 * 12] forKey:NSHTTPCookieExpires];
        NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
    }
    
    if ([self user]) {
        [[self user] doInitalCalorieAndNutritionSync];
        [Forum fetchGroupsPageCallback:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDidClickNewSectionInCommunity];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDidClickCommunityTab];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self publish:EVENT_FORUM_NEED_UPDATE_RED_DOT];
    
    // FB events
    NSString *fbId = [[NSBundle mainBundle] infoDictionary][@"FacebookAppID"];
    GLLog(@"Facebook ID:%@", fbId);
    [FBSettings setDefaultAppID:fbId];
    NSString *appVersion = [Utils appVersion];
    [FBSettings setAppVersion:appVersion];
    [FBAppEvents activateApp];
    
    [[AppsFlyerTracker sharedTracker] trackAppLaunch];
    [[AppsFlyerTracker sharedTracker] loadConversionDataWithDelegate:self]; //Delegate is below
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [self.session handleDidBecomeActive];
    
    // Notify pregnant users to install our kaylee app
    if ([self user]) {
        BOOL isPregnant = [self user].settings.currentStatus == AppPurposesAlreadyPregnant;
        BOOL installedKaylee = [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:KAYLEE_URL_SCHEME]];
        
        if (isPregnant && !installedKaylee) {
            BannerNotificationView *notifView = [[BannerNotificationView alloc] initFromNib];
            typeof(notifView) __weak weakNotifView = notifView;
            notifView.tapAction = ^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DOWNLOAD_PREGNANCY_APP_URL]];
                [weakNotifView dismissWithDelay:0 duration:0];
            };
            [notifView show];
        }
    }
    [self publish:EVENT_APP_BECOME_ACTIVE];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.session close];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    //emma://
    if ([url.scheme isEqual:EMMA_URL_SCHEME]) {
        GLLog(@"URL: %@", url);
        if ([url.host isEqualToString:URL_HOST_RESET_PASSWORD] && url.query && [url.query hasPrefix:@"ut="]) {
            NSString *ut = [url.query substringFromIndex:3];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:kResetPassword];
            [defaults setObject:ut forKey:kResetPasswordUserToken];
            
            [defaults synchronize];
        } else if ([url.host isEqualToString:URL_HOST_FORUM_TOPIC]) {
            if (url.pathComponents.count > 1 && [User currentUser]) {
                NSString *idString = [url.pathComponents objectAtIndex:1];
                GLLog(@"%@", idString);
                NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                NSNumber *idNumber = [nf numberFromString:idString];
                ForumTopic *topic = [[ForumTopic alloc] init];
                topic.identifier = [idNumber unsignedLongLongValue];
                ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
                topicViewController.topic = topic;
                UINavigationController *topicNavController = [[UINavigationController alloc] initWithRootViewController:topicViewController];
                UIViewController *topController = self.window.rootViewController;
                while (![topController isKindOfClass:[TabbarController class]] && topController.presentedViewController) {
                    topController = topController.presentedViewController;
                }
                if ([topController isKindOfClass:[TabbarController class]]) {
                    if ([topController presentedViewController]) {
                        [topController dismissViewControllerAnimated:NO completion:nil];
                    }
                    [topController presentViewController:topicNavController animated:YES completion:nil];
                } else {
                    self.viewControllerToPresentAfterMain = topicNavController;
                }
            }
        } else if ([url.host isEqualToString:URL_HOST_FORUM_GROUP]) {
            if (url.pathComponents.count > 1 && [User currentUser]) {
                NSString *idString = [url.pathComponents objectAtIndex:1];
                GLLog(@"%@", idString);
                NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                NSNumber *gid = [nf numberFromString:idString];
                if ([gid unsignedLongLongValue] > 0) {
                    ForumGroup *group = [[ForumGroup alloc] initWithDictionary:@{@"id": gid, @"name": @"Group", @"category_id":@0}];
                    ForumTopicsViewController *vc = [ForumTopicsViewController pushableControllerBy:group];
                    GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
                    nav.navigationBar.translucent = NO;
                    UIViewController *topController = [GLUtils keyWindow].rootViewController;
                    while (![topController isKindOfClass:[TabbarController class]] && topController.presentedViewController) {
                        topController = topController.presentedViewController;
                    }
                    if ([topController isKindOfClass:[TabbarController class]]) {
                        if ([topController presentedViewController]) {
                            [topController dismissViewControllerAnimated:NO completion:nil];
                        }
                        [topController presentViewController:nav animated:NO completion:nil];
                    } else {
                        self.viewControllerToPresentAfterMain = nav;
                    }
                }
            }
        }
        else if ([url.host isEqual:@"misfit_connect"]) {
            NSString *code = url.pathComponents[1];
            return [User misfitHandleForConnectWithCode:code];
        }
        else if ([url.host isEqual:@"misfit_signup"]) {
            NSString *code = url.pathComponents[1];
            return [User misfitHandleForSignupWithCode:code];
        }
        else if ([url.host isEqual:@"misfit_signin"]) {
            NSString *code = url.pathComponents[1];
            return [User misfitHandleForSigninWithCode:code];
        } else if ([url.host isEqual:@"handleWalgreensRefill"]) {
            return [WalgreensManager handleWalgreenRefill:url];
        }
        return YES;
    }
    else if ([url.scheme isEqual:@"mfp-glow"]) {
        return [[User getMFPConnection] handleOpenURL:url];
    }
    
    else {
        return [self.session handleOpenURL:url];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSDictionary * userInfo = notification.userInfo;
    if ([[userInfo objectForKey:NOTIF_USERINFO_KEY_TYPE] isEqual:NOTIF_USERINFO_VAL_TYPE_REMINDER]) {
        NSNumber * uId = [userInfo objectForKey:NOTIF_USERINFO_KEY_USER_ID];
        id moreInfo    = [userInfo objectForKey:NOTIF_USERINFO_KEY_INFO];
        if (uId && moreInfo) {
            [Logging log:IOS_APP_OPEN_FROM_REMINDER eventData:@{
                @"user_id": uId,
                @"reminder_type": moreInfo
            }];
        }
    }
}

- (User *)user {
    return [User currentUser];
}

- (FBSession *)session {
    return [User session];
}

- (void)didPasscodeEnteredCorrectly:(KKPasscodeViewController*)viewController
{
    [passcodeWindow dismissPasscodeWindow];
    for (id dialog in dialogsAfterPasscode) {
        [self dispatchDialog:dialog];
    }
    [dialogsAfterPasscode removeAllObjects];
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    NSString *tokenString = [[[[deviceToken description]stringByReplacingOccurrencesOfString: @"<" withString: @""]stringByReplacingOccurrencesOfString: @">" withString: @""]stringByReplacingOccurrencesOfString: @" " withString: @""];

	GLLog(@"My token is: %@, %@", deviceToken, tokenString);
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:tokenString forKey:@"apnsDeviceToken"];
    [defaults synchronize];
    // update the user's apns token
    User * user = [User currentUser];
    if (user && tokenString) {
        [user update:@"apnsDeviceToken" value:tokenString];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	GLLog(@"Failed to get token, error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    /*
     Do nothing if app is active or in background.
     If app is in background, iOS default behavior is bringing it to fontend with previous stored status.
    */
    GLLog(@"didReceiveRemoteNotification %@", userInfo);
    NSLog(@"Peng debug did receive remote notification %@", userInfo);
    [Logging log:BTN_CLK_OPEN_APP_IN_PUSH_NOTIFICATION];
    if (userInfo) {
        NSNumber * openType = [userInfo objectForKey:@"opType"];
        if (!openType) return;
        
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        [dict setObject:openType forKey:@"opType"];
        NSNumber * data1 = [userInfo objectForKey:@"d1"];
        NSNumber * data2 = [userInfo objectForKey:@"d2"];
        NSString * url   = [userInfo objectForKey:@"url"];
        if (data1) {
            [dict setObject:data1 forKey:@"data_1"];
        }
        if (data2) {
            [dict setObject:data2 forKey:@"data_2"];
        }
        if (url) {
            [dict setObject:url forKey:@"url"];
        }
        [self publish:EVENT_APP_RECEIVE_NOTIFICATION data:dict];
    }
}

- (void)handleLaunchWithNotification:(UIApplication *)application userInfo:(NSDictionary *)userInfo {
    /*
     * Including local (reminder) and remote (APNs) notification 
     */
    [Logging log:BTN_CLK_OPEN_APP_IN_PUSH_NOTIFICATION];
    if (userInfo) {
        [Utils setDefaultsForKey:APP_OPEN_WITH_OPTION withValue:[userInfo objectForKey:@"opType"]];
        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
        NSNumber * data1 = [userInfo objectForKey:@"d1"];
        NSNumber * data2 = [userInfo objectForKey:@"d2"];
        NSString * url   = [userInfo objectForKey:@"url"];
        if (data1) {
            [dict setObject:data1 forKey:@"data_1"];
        }
        if (data2) {
            [dict setObject:data2 forKey:@"data_2"];
        }
        if (url) {
            [dict setObject:url forKey:@"url"];
        }
        [Utils setDefaultsForKey:APP_OPEN_EXT_DATA withValue:dict];
    }
}

- (void)handleLaunchWithIconBadgeNumber:(UIApplication *)application {
    // This function is no longer used, since we don't want to launch GG even if icon badge number is non-zero
    if (application.applicationIconBadgeNumber > 0) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:@(APP_OPEN_TYPE_ALERT) forKey:APP_OPEN_WITH_OPTION];
        [defaults synchronize];
    }
}

- (void)pushDialog:(id)dialog {
    if (!passcodeWindow || passcodeWindow.hidden){
        [self dispatchDialog:dialog];
    } else {
        [dialogsAfterPasscode addObject:dialog];
    }
}

- (void)dispatchDialog:(id)modal {
    if ([modal isKindOfClass:[UIAlertView class]]){
        [(UIAlertView *)modal show];
    } else if ([modal isKindOfClass:[NSDictionary class]]) {
        id dialog = [modal objectForKey:@"dialog"];
        if ([dialog isKindOfClass:[AppUpgradeDialog class]]){
            if ([[modal objectForKey:@"type"] unsignedIntValue] == AppUpgradeDialogPresentTypeEnforce) {
                [dialog presentWithEnforce];
            } else {
                [dialog presentWithRemind];
            }
        }
    }
    else if ([modal conformsToProtocol:@protocol(PushableDialog)]) {
        id<PushableDialog> dialog = (id<PushableDialog>) modal;
        [dialog present];
    }
}

- (void)setRotationEnabled:(BOOL)enabled {
    rotationEnabled = enabled;
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
//    UIViewController *topController = [GLUtils keyWindow].rootViewController;
//    
//    while (topController.presentedViewController) {
//        topController = topController.presentedViewController;
//    }
//    
//    UIViewController *tcr = self.window.rootViewController;
//    while (tcr.presentedViewController) {
//        tcr = tcr.presentedViewController;
//    }
//    
//    GLLog(@"top c %@ top from r %@", topController, tcr);
//    GLLog(@"presenting %@", tcr.presentingViewController);
//    NSUInteger orientations = UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft;
//
    if (!rotationEnabled) {
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
}

- (void) onConversionDataReceived:(NSDictionary*) installData {
    if ([Utils getDefaultsForKey:DEFAULTS_ADSFLYER_INSTALL]) {
        return;
    }
    if (installData) {
        NSMutableDictionary *mutableInstallData = [installData mutableCopy];
        NSString *appsFlyerUid = [[AppsFlyerTracker sharedTracker] getAppsFlyerUID];
        mutableInstallData[@"appsflyer_uid"] = appsFlyerUid ? appsFlyerUid : @"";
        [Utils setDefaultsForKey:DEFAULTS_ADSFLYER_INSTALL withValue:mutableInstallData];
        [Logging syncLog:INSTALLED_WITH_ADS eventData:@{@"data_needs_preprocess":mutableInstallData}];
    }
}

- (void) onConversionDataRequestFailure:(NSError *)error{


}

#pragma mark - AddsFlyer tracker delegate

+ (UIViewController*) topMostController
{
    UIViewController *topController = [GLUtils keyWindow].rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end

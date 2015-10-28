//
//  UIStoryboard+Emma.m
//  emma
//
//  Created by Ryan Ye on 3/21/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UIStoryboard+Emma.h"

@implementation UIStoryboard (Emma)

+ (UIViewController *)startUp {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"startUp"];
}

+ (UIViewController *)welcome {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"welcome"];
}

+ (UIViewController *)confirmInfo {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"confirmInfo"];
}

+ (UIViewController *)main {
    return [[UIStoryboard storyboardWithName:@"tabbar" bundle:nil] instantiateInitialViewController];

//    return [[UIStoryboard storyboardWithName:@"main" bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)fund {
    return [[UIStoryboard storyboardWithName:@"fund" bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)clinicsNearby {
    return [[UIStoryboard storyboardWithName:@"me" bundle:nil] instantiateViewControllerWithIdentifier:@"clinicsNearby"];
}

+ (UIViewController *)webView {
    return [[UIStoryboard storyboardWithName:@"me" bundle:nil] instantiateViewControllerWithIdentifier:@"webView"];
}

+ (UIViewController *)recoverPassword {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"resetPassword"];
}

+ (UIViewController *)chart {
    return [[UIStoryboard storyboardWithName:@"chart" bundle:nil] instantiateViewControllerWithIdentifier:@"chart"];
}

+ (UIViewController *)genius {
    return [[UIStoryboard storyboardWithName:@"genius" bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)me {
    return [[UIStoryboard storyboardWithName:@"me" bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)settings {
    return [[UIStoryboard storyboardWithName:@"settings" bundle:nil] instantiateInitialViewController];
}

+ (UIViewController *)help {
    return [[UIStoryboard storyboardWithName:@"me" bundle:nil] instantiateViewControllerWithIdentifier:@"helpCenter"];
}

+ (UIViewController *)congrats
{
    return [[UIStoryboard storyboardWithName:@"me" bundle:nil] instantiateViewControllerWithIdentifier:@"congrats"];
}


+ (UIViewController *)firstPeriod {
    return [[UIStoryboard storyboardWithName:@"period" bundle:nil] instantiateViewControllerWithIdentifier:@"firstPeriod"];
}

+ (UIViewController *)signUp {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"signUp"];
}

+ (UIViewController *)makeUpOnboardingInfo {
    return [[UIStoryboard storyboardWithName:@"onboarding" bundle:nil] instantiateViewControllerWithIdentifier:@"makeUpOnboardingInfo"];
}


+ (UIViewController *)buyTestkitGoodsInfo {
    return [[UIStoryboard storyboardWithName:@"fulfillment" bundle:nil]
            instantiateViewControllerWithIdentifier:@"goodsInfo"];
}

+ (UIViewController *)walgreensScanner
{
    return [[UIStoryboard storyboardWithName:@"walgreens" bundle:nil]
            instantiateViewControllerWithIdentifier:@"WalgreensScannerViewController"];
}

+ (UIViewController *)alert
{
    return [[UIStoryboard storyboardWithName:@"alert" bundle:nil]
            instantiateInitialViewController];
}

+ (UIViewController *)dailyLog
{
    return [[UIStoryboard storyboardWithName:@"home" bundle:nil]instantiateViewControllerWithIdentifier:@"dailyLog"];
}

@end



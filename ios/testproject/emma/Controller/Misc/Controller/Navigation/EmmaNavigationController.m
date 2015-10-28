//
//  EmmaNavigationController.m
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "EmmaNavigationController.h"

@interface EmmaNavigationController ()

@end

@implementation EmmaNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    __weak EmmaNavigationController *weakSelf = self;
    self.delegate = weakSelf;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIViewController *lastViewController = [self.viewControllers lastObject];
    if ([lastViewController respondsToSelector:@selector(preferredStatusBarStyle)]) {
        return [lastViewController preferredStatusBarStyle];
    } else if ([super respondsToSelector:@selector(preferredStatusBarStyle)]) {
        return [super preferredStatusBarStyle];
    }
    return UIStatusBarStyleDefault;
}

#pragma mark - UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [navigationController.navigationBar setBarTintColor:[UIColor whiteColor]];
    [navigationController.navigationBar setTintColor:UIColorFromRGB(0x6c6dd3)];
    NSMutableDictionary *attributes = [navigationController.navigationBar.titleTextAttributes mutableCopy];
    attributes[NSForegroundColorAttributeName] = UIColorFromRGB(0x5b5b5b);
    [navigationController.navigationBar setTitleTextAttributes:[attributes copy]];
    
//    id<EmmaNavigationControllerDelegate> vc = (id<EmmaNavigationControllerDelegate>)viewController;
//    if ([vc respondsToSelector:@selector(setupNavigationBarAppearance)]) {
//        [vc setupNavigationBarAppearance];
//    }
}


@end

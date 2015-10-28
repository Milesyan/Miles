//
//  DebugViewController.m
//  emma
//
//  Created by ltebean on 15-5-8.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "DebugViewController.h"
#import "User.h"
#import "NetworkLoadingView.h"
#import "TabbarController.h"
#import "UserDailyData.h"
#import "DebugDataViewController.h"
#import "StatusHistory.h"

@interface DebugViewController ()
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *dailyDataDate;
@end

@implementation DebugViewController
+ (instancetype)instance
{
    return [[UIStoryboard storyboardWithName:@"debug" bundle:nil] instantiateViewControllerWithIdentifier:@"debug"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self subscribe:EVENT_USER_LOGGED_IN selector:@selector(userLoggedIn:)];
    [self subscribe:EVENT_USER_LOGIN_FAILED selector:@selector(loginFailed:)];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.title = [User currentUser].email;
    self.dailyDataDate.text = [[NSDate date] toDateLabel];
}


- (IBAction)signIn:(id)sender {
    [NetworkLoadingView showWithDelay:5];
    NSString *email = self.emailField.text;
    NSString *password = self.passwordField.text;
    [User signInWithEmail:@{USERINFO_KEY_EMAIL:email, USERINFO_KEY_PASSWORD:password}];

}

- (void)userLoggedIn:(Event *)evt {
    [NetworkLoadingView hide];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        [self.tabbarVC reloadTabbarsForced:YES];
    }];
}

- (void)loginFailed:(Event *)event {
    [NetworkLoadingView hide];
    NSString *message = nil;
    if ([event.data isKindOfClass:[NSError class]]) {
        message = [(NSError *)event.data description];
    } else {
        message = (NSString *)event.data;
    }
    [self alert:message];
}


- (IBAction)queryDailyData:(id)sender {
    
    UserDailyData *data = [UserDailyData getUserDailyData:self.dailyDataDate.text forUser:[User currentUser]];
    if (data) {
        NSString* description = [data description];
        [self performSegueWithIdentifier:@"showData" sender:description];
    } else {
        [self alert:@"No data found"];
    }

}

- (IBAction)showUser:(id)sender {
    NSString* description = [[User currentUser].settings description];
    [self performSegueWithIdentifier:@"showData" sender:description];
}

- (IBAction)showUserSettings:(id)sender {
    NSString* description = [[User currentUser].statusHistory description];
    [self performSegueWithIdentifier:@"showData" sender:description];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showData"]) {
        DebugDataViewController *vc = segue.destinationViewController;
        vc.text = sender;
    }
}

- (IBAction)back:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)alert:(NSString *)message
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end

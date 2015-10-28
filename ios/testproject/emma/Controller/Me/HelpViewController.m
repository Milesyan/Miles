//
//  HelpViewController.m
//  emma
//
//  Created by Xin Zhao on 13-4-2.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ChartViewController.h"
#import "HelpViewController.h"
#import "HomeViewController.h"
#import "WebViewController.h"
#import "PillGradientButton.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "Logging.h"
#import <MessageUI/MFMailComposeViewController.h>
#import "FundHomeViewController.h"

@interface HelpViewController ()
@property (retain, nonatomic) PillGradientButton *feedbackButton;
@end

@implementation HelpViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setNeedsLayout];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // logging
    [CrashReport leaveBreadcrumb:@"HelpViewController"];
    [Logging log:PAGE_IMP_HELP];
}

#pragma mark - Handlers
- (void)whatIsGlowFundSelected {
    GLLog(@"fbb pressed");
    FundHomeViewController *controller = (FundHomeViewController *)[UIStoryboard fund];
    controller.fromHelpViewController = YES;
    [self.navigationController pushViewController:controller animated:YES from:self];
}

- (void)startTutorialSelected {
    UIViewController *firstViewController = [self.tabBarController.viewControllers objectAtIndex:0];
    if ([firstViewController isKindOfClass:[UINavigationController class]]) {
        firstViewController = ((UINavigationController *)firstViewController).visibleViewController;
    }

    if ([firstViewController respondsToSelector:@selector(beginTutorial)]) {
        self.tabBarController.selectedIndex = 0;
        [firstViewController performSelector:@selector(beginTutorial)];
    }
}

#pragma mark - Table view delegate
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [@[@"Help", @"Glow First", @"Stay in touch", @"Terms"] objectAtIndex:section];
}

- (void)openUrl:(NSString *)url {
    WebViewController *controller = (WebViewController *)[UIStoryboard webView];
    [self.navigationController pushViewController:controller animated:YES from:self];
    [controller openUrl:url];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // logging first
    [self logCellPressed:cell.tag];
    
    switch (cell.tag) {
        case 1:
            [self startTutorialSelected];
            break;
        case 2:
            [self openUrl:[Utils makeUrl:FAQ_URL]];
            break;
        case 3:
            [self whatIsGlowFundSelected];
            break;
        case 5:
        {
            [self openUrl:[Utils makeUrl:THE_WEB_URL]]; 
        }
            break;
        case 6:
        {
            
            [self openUrl:[Utils makeUrl:FACEBOOK_URL]];
        }
            break;
        case 7:
        {
            [self openUrl:[Utils makeUrl:TWITTER_URL]];    
        }
            break;
        case 8:
        {
            [self openUrl:[Utils makeUrl:TOS_URL]];    
        }
            break;
        case 9:
        {
            [self openUrl:[Utils makeUrl:PRIVACY_POLICY_URL]];    
        }
            break;
        case 10:
        {
            [self openUrl:[Utils makeUrl:BLOG_URL]];
        }
            break;
        default:
            break;
    }
}

- (void)logCellPressed:(NSInteger)tag {
    NSDictionary *cellEvents = @{
        @1: BTN_CLK_HELP_TUTORIAL,
        @2: BTN_CLK_HELP_FAQ,
        @3: BTN_CLK_HELP_WHATS_FUND,
        @4: BTN_CLK_HELP_CLINICS_NEAR,
        @5: BTN_CLK_HELP_GO_WEB,
        @6: BTN_CLK_HELP_GO_FACEBOOK,
        @7: BTN_CLK_HELP_GO_TWITTER,
        @8: BTN_CLK_HELP_TERMS_SERVICE,
        @9: BTN_CLK_HELP_POLICY,
        @10: BTN_CLK_HELP_GO_BLOG
        };
    
    NSString * event = (NSString *)[cellEvents objectForKey:@(tag)];
    [Logging log:event];
}

@end

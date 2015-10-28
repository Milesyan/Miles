//
//  ForumIntroduceFollowViewController.m
//  Pods
//
//  Created by Peng Gu on 6/2/15.
//
//

#import "ForumIntroduceFollowViewController.h"
#import <GLFoundation/GLDialogViewController.h>
#import <GLFoundation/UIImage+Utils.h>
#import "Forum.h"

@interface ForumIntroduceFollowViewController ()

@end

@implementation ForumIntroduceFollowViewController


+(BOOL)presentIfTheFirstTimeWithCheckoutAction:(CheckoutButtonAction)action
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *firstLaunch = [Forum appInstallDate];
    NSTimeInterval timeSinceFirstLaunch = [[NSDate date] timeIntervalSinceDate:firstLaunch];
    
    if (!firstLaunch || timeSinceFirstLaunch < 3 * 24 * 3600) {
        return NO;
    }
    
    BOOL hasShown = [defaults boolForKey:@"hasShownForumFollowFeature"];
    
    if (!hasShown) {
        ForumIntroduceFollowViewController *vc = [[ForumIntroduceFollowViewController alloc] initFromNib];
        vc.checkoutAction = action;
        [[GLDialogViewController sharedInstance] presentWithContentController:vc];
        
        [defaults setBool:YES forKey:@"hasShownForumFollowFeature"];
        [defaults synchronize];
        return YES;
    }
    return NO;
}


- (instancetype)initFromNib
{
    return [self initWithNibName:@"ForumIntroduceFollowViewController" bundle:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.checkoutButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}


- (IBAction)checkoutGlowProfile:(id)sender
{
    if (self.checkoutAction) {
        self.checkoutAction();
    }
    
    [[GLDialogViewController sharedInstance] close];
}

@end

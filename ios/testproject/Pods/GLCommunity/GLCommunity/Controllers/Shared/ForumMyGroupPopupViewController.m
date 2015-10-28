//
//  ForumMyGroupPopupViewController.m
//  GLCommunity
//
//  Created by Allen Hsu on 1/30/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLPillGradientButton.h>
#import <GLFoundation/GLDialogViewController.h>
#import "ForumMyGroupPopupViewController.h"
#import "ForumEvents.h"

@interface ForumMyGroupPopupViewController ()

@property (weak, nonatomic) IBOutlet GLPillGradientButton *button;

@end

@implementation ForumMyGroupPopupViewController

+ (ForumMyGroupPopupViewController *)viewController
{
    return [[ForumMyGroupPopupViewController alloc] initWithNibName:@"ForumMyGroupPopupViewController" bundle:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.button setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didClickButton:(id)sender {
    [self publish:EVENT_FORUM_GOTO_MY_GROUP];
    [self dismiss];
}

- (void)present
{
    [[GLDialogViewController sharedInstance] presentWithContentController:self];
}

- (void)dismiss
{
    [[GLDialogViewController sharedInstance] close];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  WelcomeToCommunityDialogViewController.m
//  emma
//
//  Created by Peng Gu on 8/28/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLDialogViewController.h>
#import <GLFoundation/GLPillGradientButton.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/NSString+Markdown.h>
#import "WelcomeToCommunityDialogViewController.h"
#import "Forum.h"

@interface WelcomeToCommunityDialogViewController ()

@property (nonatomic, weak) IBOutlet GLPillGradientButton *button;
@property (weak, nonatomic) IBOutlet UIImageView *bannerImageView;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;

- (IBAction)buttonClicked:(id)sender;

@end


@implementation WelcomeToCommunityDialogViewController


+ (WelcomeToCommunityDialogViewController *)presentDialogOnlyTheFirstTime
{
    NSString *key = [NSString stringWithFormat:@"kDidSeeWelcomeDialog - %llu", [[Forum currentForumUser] identifier]];
    if (![[NSUserDefaults standardUserDefaults] boolForKey:key]) {
        WelcomeToCommunityDialogViewController *vc = [[WelcomeToCommunityDialogViewController alloc] initFromNib];
        [vc present];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return vc;
    }
    return nil;
}


- (instancetype)initFromNib
{
    return [self initWithNibName:@"WelcomeToCommunityDialogViewController" bundle:nil];
}


- (void)viewDidLoad
{   
    [super viewDidLoad];
    [self.button setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    self.button.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    self.bannerImageView.image = [Forum bannerImageForWelcomeDialog];
    
    self.textLabel.attributedText = [NSString markdownToAttributedText:[Forum textForWelcomeDialog] fontSize:14.0 color:[UIColor blackColor]];
}


- (void)present
{
    [[GLDialogViewController sharedInstance] presentWithContentController:self];
}


- (void)buttonClicked:(id)sender
{
    if (self.getStartedAction) {
        self.getStartedAction();
    }
    
    [[GLDialogViewController sharedInstance] close];
}


@end

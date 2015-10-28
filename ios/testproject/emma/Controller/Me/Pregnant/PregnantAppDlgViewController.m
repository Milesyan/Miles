//
//  PregnantAppDlgViewController.m
//  emma
//
//  Created by Jirong Wang on 7/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "PregnantAppDlgViewController.h"
#import "PillGradientButton.h"

@interface PregnantAppDlgViewController ()

@property (strong, nonatomic) IBOutlet PillGradientButton *downloadButton;

- (IBAction)downloadButtonClicked:(id)sender;

@end

@implementation PregnantAppDlgViewController

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
    // Do any additional setup after loading the view from its nib.
    // set button color
    [self.downloadButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    self.downloadButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)downloadButtonClicked:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DOWNLOAD_PREGNANCY_APP_URL]];
}

- (void)present {
    self.dialog = [GLDialogViewController sharedInstance];
    [self.dialog presentWithContentController:self];
}

@end

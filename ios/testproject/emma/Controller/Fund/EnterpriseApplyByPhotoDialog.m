//
//  EnterpriseApplyByPhotoViewController.m
//  emma
//
//  Created by Jirong Wang on 1/29/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "EnterpriseApplyByPhotoDialog.h"
#import "GLDialogViewController.h"
#import "CrashReport.h"

@interface EnterpriseApplyByPhotoDialog ()

@property (nonatomic, strong) GLDialogViewController *dialog;

@end

@implementation EnterpriseApplyByPhotoDialog


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)present {
    [CrashReport leaveBreadcrumb:@"EnterpriseApplyByPhotoDialog"];
    self.dialog = [GLDialogViewController sharedInstance];
    [self.dialog presentWithContentController:self];
}

@end

//
//  PushablePresenteeNavigationController.m
//  emma
//
//  Created by Xin Zhao on 7/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLPushablePresenteeNavigationController.h"

@interface GLPushablePresenteeNavigationController ()

@property (strong, nonatomic) GLPushableInteractor *panTarget;

@end

@implementation GLPushablePresenteeNavigationController

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
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

# pragma mark - GLPushablePresentee protocal
- (void)setInteractorAsPanTarget:
    (id<GLPushableViewControllerPanTarget>)panTarget
{
    self.panTarget = (GLPushableInteractor*)panTarget;
    UIScreenEdgePanGestureRecognizer *gestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.panTarget action:@selector(userDidPan:)];
    gestureRecognizer.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:gestureRecognizer];
}

@end

//
//  GLCameraViewController.m
//  GLUIKit
//
//  Created by Allen Hsu on 8/19/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import "GLCameraViewController.h"
#import "UIView+Helpers.h"
#import "GLUtils.h"

@interface GLCameraViewController ()

@property (assign, nonatomic) BOOL needTransition;

@end

@implementation GLCameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.mediaTypes = @[(NSString *)kUTTypeImage];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            self.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
    }
    return self;
}

- (id)initWithImagePickerDelegate:(id <UIImagePickerControllerDelegate>)imagePickerDelegate
{
    self = [self init];
    if (self) {
        self.imagePickerDelegate = imagePickerDelegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        self.cameraOverlayView = [self generateOverlayView];
    }
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(didCaptureItem:) name:@"_UIImagePickerControllerUserDidCaptureItem" object:nil];
    [nc addObserver:self selector:@selector(didRejectItem:) name:@"_UIImagePickerControllerUserDidRejectItem" object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (UIView *)generateOverlayView
{
    UIView *overlay = nil;
    overlay = [[UIView alloc] initWithFrame:CGRectMake(self.view.width - 60.0, self.view.height - 60.0, 50.0, 50.0)];
    
    // Album Button
    UIButton *albumBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    albumBtn.frame = CGRectMake(0.0, 0.0, 50.0, 50.0);
    [albumBtn setImage:[UIImage imageNamed:@"gl-foundation-photo-album"] forState:UIControlStateNormal];
    [albumBtn addTarget:self action:@selector(chooseFromLibrary:) forControlEvents:UIControlEventTouchUpInside];
    
    [overlay addSubview:albumBtn];
    
    //    if (self.autoCrop) {
    //        // Square Indicator
    //        CGFloat squareSize = overlay.width;
    //        UIView *square = [[UIView alloc] initWithFrame:CGRectMake(0.0, (overlay.height - squareSize) / 2.0, squareSize, squareSize)];
    //        square.layer.borderColor = [[UIColor colorWithWhite:1.0 alpha:0.6] CGColor];
    //        square.layer.borderWidth = 1.0;
    //
    //        UIView *topOverlay = [[UIView alloc] initWithFrame:CGRectMake(0.0, 69.0, squareSize, square.top - 69.0)];
    //        topOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    //
    //        UIView *bottomOverlay = [[UIView alloc] initWithFrame:CGRectMake(0.0, square.bottom, squareSize, overlay.height - 73.0 - square.bottom)];
    //        bottomOverlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    //
    //        [overlay addSubview:square];
    //        [overlay addSubview:topOverlay];
    //        [overlay addSubview:bottomOverlay];
    //    }
    
    return overlay;
}

- (void)didCaptureItem:(NSNotification *)notification
{
    self.cameraOverlayView.userInteractionEnabled = NO;
    [UIView animateWithDuration:0.25 animations:^{
        self.cameraOverlayView.alpha = 0.0;
    } completion:^(BOOL finished) {
        self.cameraOverlayView.hidden = YES;
    }];
}

- (void)didRejectItem:(NSNotification *)notification
{
    self.cameraOverlayView.hidden = NO;
    self.cameraOverlayView.userInteractionEnabled = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.cameraOverlayView.alpha = 1.0;
    } completion:^(BOOL finished) {
    }];
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

- (IBAction)chooseFromLibrary:(id)sender
{
    if (self.viewControllers.count > 1) {
        return;
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
            self.cameraOverlayView.userInteractionEnabled = NO;
        }
        self.needTransition = YES;
        self.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
}

- (IBAction)useCamera:(id)sender
{
    if (self.viewControllers.count > 1) {
        return;
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.needTransition = YES;
        self.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.cameraOverlayView.userInteractionEnabled = YES;
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        if (navigationController.viewControllers.count <= 1) {
            if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                UIBarButtonItem *cameraButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(useCamera:)];
                viewController.navigationItem.leftBarButtonItem = cameraButton;
                viewController.navigationItem.leftBarButtonItem.enabled = NO;
            }
        }
    } else if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        self.cameraOverlayView.userInteractionEnabled = YES;
        self.cameraOverlayView.hidden = NO;
        self.cameraOverlayView.alpha = 1.0;
    }
    if (self.needTransition) {
        self.needTransition = NO;
        [UIView transitionWithView:self.view duration:0.4 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (self.sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        if (navigationController.viewControllers.count <= 1) {
            viewController.navigationItem.leftBarButtonItem.enabled = YES;
        }
    } else if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        [[self.cameraOverlayView superview] bringSubviewToFront:self.cameraOverlayView];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if ([self.imagePickerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [self.imagePickerDelegate imagePickerControllerDidCancel:picker];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([self.imagePickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingMediaWithInfo:)]) {
        [self.imagePickerDelegate imagePickerController:picker didFinishPickingMediaWithInfo:info];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

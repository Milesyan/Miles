//
//  DialogViewController.m
//  emma
//
//  Created by Ryan Ye on 3/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLDialogViewController.h"
#import "GLAnimationSequence.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+FindAndResignFirstResponder.h"
#import "UIView+GLMotionEffects.h"
#import "GLLog.h"
#import "NSObject+PubSub.h"
#import "GLUtils.h"

@interface GLDialogViewController ()

@property (nonatomic, strong)IBOutlet UIView *contentView;
@property (nonatomic, strong)IBOutlet UIView *maskView;
@property (nonatomic, strong)IBOutlet UIButton *closeButton;
@property (nonatomic, strong)UIViewController *contentController;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UIView *blurEffectView;

@property (nonatomic)BOOL opened;

- (IBAction)closeButtonClicked:(id)sender;
- (void)dialogShowAnimation;
@end

@implementation GLDialogViewController

+ (GLDialogViewController *)sharedInstance {
    static GLDialogViewController *_dialog = nil;
    if (!_dialog) {
        _dialog = [[GLDialogViewController alloc] initWithNibName:@"GLDialogViewController" bundle:nil];
    }
    return _dialog;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.contentView addMotionEffectWithMovement:CGPointMake(10, 10)];
    
    self.contentController.view.layer.cornerRadius = 5.0f;
    self.contentController.view.clipsToBounds = YES;
    self.contentView.layer.cornerRadius = 5.0f;
    self.contentView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.contentView.layer.shadowOffset = CGSizeMake(0, 3.0);
    self.contentView.layer.shadowOpacity = 0.5f;
    self.contentView.layer.shouldRasterize = YES;
    self.contentView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    // Do any additional setup after loading the view from its nib.
    
    UITapGestureRecognizer *tapOnMask = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMask:)];
    UITapGestureRecognizer *tapOnContent = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnContent:)];
    UITapGestureRecognizer *tapOnScrollView = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnMask:)];
    [self.scrollView addGestureRecognizer:tapOnScrollView];
    self.maskView.userInteractionEnabled = YES;
    [self.maskView addGestureRecognizer:tapOnMask];
    
    self.dialogView.userInteractionEnabled = YES;
    [self.dialogView addGestureRecognizer:tapOnContent];
    self.scrollView.contentSize = self.scrollView.bounds.size;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)tapOnMask:(UITapGestureRecognizer *)gesture
{
    id firstResponder = [self.view findFirstResponder];
    if ([firstResponder isKindOfClass:[UITextField class]] || [firstResponder isKindOfClass:[UITextView class]])
    {
        [self.view endEditing:YES];
    }
    else
    {
        if (self.shouldDismissByTappingOutside)
        {
            [self closeButtonClicked:nil];
        }
    }
}

- (void)tapOnContent:(UITapGestureRecognizer *)gesture
{
    CGPoint location = [gesture locationInView:self.contentView];
    CGRect frame = self.contentView.bounds;
    if (!CGRectContainsPoint(frame, location))
    {
        [self tapOnMask:gesture];
    }
    else
    {
        [self.view endEditing:YES];
    }
}

- (IBAction)closeButtonClicked:(id)sender {
    if (self.closeButton.hidden)
    {
        return;
    }
    [self close];
    [self publish:EVENT_DIALOG_CLOSE_BUTTON_CLICKED];
}

- (BOOL)isOpened {
    return self.opened ? YES : NO;
}

- (void)close {
    [self.view endEditing:YES];
    self.opened = NO;
    [self.contentController willMoveToParentViewController:nil];
    [UIView animateWithDuration:0.3 animations:^{
        // drop down
        self.dialogView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), self.view.frame.size.height * 1.5);
        self.maskView.alpha = 0.0;
        if (self.blurEffectView) {
            self.blurEffectView.alpha = 0;
        }
    } completion:^(BOOL finished) {
        [self removeBlurEffect];
        [self.view removeFromSuperview];
        [self.contentController.view removeFromSuperview];
        [self.contentController removeFromParentViewController];
        self.contentController = nil;
        [self publish:EVENT_DIALOG_DISMISSED];
    }];
}

- (void)presentWithContentController:(UIViewController*)controller {
    [self presentWithContentController:controller canClose:YES];
}

- (void)presentWithContentController:(UIViewController*)controller canClose:(BOOL)canClose {
    self.opened = YES;
    self.contentController = controller;
    [self addChildViewController:controller];
    
    UIWindow *window = [GLUtils keyWindow];
    [self addBlurEffect:window animated:YES];
    if (IOS8_OR_ABOVE) {
        [self.maskView.superview bringSubviewToFront:self.maskView];
    }
    [window addSubview:self.view];
    self.view.frame = window.bounds;
    NSArray *views = self.contentView.subviews;
    for (UIView *v in views)
    {
        [v removeFromSuperview];
    }
    [self.contentView addSubview:controller.view];
    controller.view.layer.cornerRadius = 5.0f;
    controller.view.clipsToBounds = YES;
    CGSize winSize = window.bounds.size;
    CGSize contentSize = controller.view.frame.size;
    CGFloat contentX = (winSize.width - contentSize.width) / 2;
    self.contentView.frame = CGRectMake(contentX, 14, contentSize.width, contentSize.height);
    self.closeButton.center = CGPointMake(self.contentView.frame.origin.x + 5, self.contentView.frame.origin.y + 5);
    self.closeButton.hidden = canClose ? NO : YES;
    
    CGSize dialogSize = CGSizeMake(winSize.width, contentSize.height + 28);
    self.dialogView.frame = CGRectMake(0, - dialogSize.height, dialogSize.width, dialogSize.height);
    
    [self dialogShowAnimation];
    self.scrollView.contentSize = self.scrollView.bounds.size;
    [controller didMoveToParentViewController:self];
}

- (void)dialogShowAnimation {
    self.dialogView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), - self.dialogView.frame.size.height / 2);
    self.maskView.alpha = 0.0;
    [GLAnimationSequence performAnimations:@[
                                             [GLAnimationBlock duration:0.3 animations:^{
        GLLog(@"dialogView drop down");
        // drop down
        self.dialogView.center = CGPointMake(CGRectGetMidX([UIScreen mainScreen].bounds), self.view.frame.size.height / 2);
        if (!IOS8_OR_ABOVE) {
            self.maskView.alpha = 0.5;
        } else {
            self.maskView.alpha = 0.01;
        }
    }],
                                             [GLAnimationBlock duration:0.1 animations:^{
        GLLog(@"dialogView bounce up");
        // bounce up
        self.dialogView.center = CGPointMake(self.dialogView.center.x, self.dialogView.center.y - 5);
        self.dialogView.transform = CGAffineTransformMakeRotation(M_PI * .5 / 180);
    }],
                                             [GLAnimationBlock duration:0.1 animations:^{
        GLLog(@"dialogView fall down and rotate the other way");
        // fall down and rotate the other way
        self.dialogView.center = CGPointMake(self.dialogView.center.x, self.dialogView.center.y + 5);
        self.dialogView.transform = CGAffineTransformMakeRotation(M_PI * -.3 / 180);
    }],
                                             [GLAnimationBlock duration:0.1 animations:^{
        self.dialogView.transform = CGAffineTransformIdentity;
    }]
                                             ]];
}

- (void)flipWithBlock:(GLFlipAnimationBlock)block
{
    self.contentView.layer.shouldRasterize = NO;
    [UIView transitionWithView:self.dialogView duration:0.5 options:UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionTransitionFlipFromRight animations:^{
        if (block) {
            block();
        }
    } completion:^(BOOL finished) {
        self.contentView.layer.shouldRasterize = YES;
    }];
}

- (void)sizeToFit
{
    UIWindow *window = [GLUtils keyWindow];
    [window addSubview:self.view];
    self.view.frame = window.bounds;
    CGSize winSize = window.bounds.size;
    CGSize contentSize = self.contentController.view.frame.size;
    CGFloat contentX = (winSize.width - contentSize.width) / 2;
    self.contentView.frame = CGRectMake(contentX, 14, contentSize.width, contentSize.height);
    self.closeButton.center = CGPointMake(self.contentView.frame.origin.x + 5, self.contentView.frame.origin.y + 5);
    
    CGSize dialogSize = CGSizeMake(winSize.width, contentSize.height + 28);
    CGRect dialogFrame = self.dialogView.frame;
    dialogFrame.size.width = dialogSize.width;
    dialogFrame.size.height = dialogSize.height;
    self.dialogView.frame = dialogFrame;
}


- (void)keyboardWillShow:(NSNotification *)notification
{
    self.scrollView.alwaysBounceVertical = YES;
    CGRect keyboardRectInWindow = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGSize keyboardSize = [self.view convertRect:keyboardRectInWindow fromView:nil].size;
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = keyboardSize.height + 20;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
    
    UIView *firstResponder = [self.view findFirstResponder];
    
    CGRect scrollToVisibleRect = [self.scrollView convertRect:firstResponder.bounds fromView:firstResponder];
    [self.scrollView scrollRectToVisible:scrollToVisibleRect animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    UIEdgeInsets scrollInsets = self.scrollView.contentInset;
    scrollInsets.bottom = 0.0;
    self.scrollView.contentInset = scrollInsets;
    self.scrollView.scrollIndicatorInsets = scrollInsets;
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    self.scrollView.alwaysBounceVertical = NO;
}

- (void)addBlurEffect:(UIView *)view animated:(BOOL)animated {
    if (IOS8_OR_ABOVE) {
        if (!self.blurEffectView) {
            UIBlurEffect *blurEffect;
            blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blurEffectView;
            blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blurEffectView.frame = view.bounds;
            self.blurEffectView = blurEffectView;
        }

        if (animated) {
            self.blurEffectView.alpha = 0.0;
            [view addSubview:self.blurEffectView];
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 self.blurEffectView.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 //
                             }];
        } else {
            self.blurEffectView.alpha = 0.85;
            [view addSubview:self.blurEffectView];
        }
    }
}

- (void)removeBlurEffect {
    if (IOS8_OR_ABOVE) {
        if (self.blurEffectView) {
            [self.blurEffectView removeFromSuperview];
        }
    }
}
@end

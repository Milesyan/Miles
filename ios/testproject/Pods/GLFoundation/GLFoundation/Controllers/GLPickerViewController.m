//
//  PickerViewController.m
//  emma
//
//  Created by Ryan Ye on 7/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLPickerViewController.h"
#import "GLUtils.h"
#import <Masonry/Masonry.h>

@interface GLPickerViewController ()
@property (nonatomic, strong)IBOutlet UIView *maskView;
@property (nonatomic, strong)UIViewController *contentController;
@property (readonly)UIView *contentView;
@end

@implementation GLPickerViewController

+ (GLPickerViewController *)sharedInstance {
    static GLPickerViewController *_picker = nil;
    if (!_picker) {
        _picker = [[GLPickerViewController alloc] initWithNibName:@"GLPickerViewController" bundle:nil];
    }
    return _picker;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (UIView *)contentView {
    return self.contentController.view;
}

- (void)presentWithContentController:(UIViewController*)controller {
    if (self.contentController) {
        return;
    }

    self.contentController = controller;
    [self addChildViewController:controller];
    
    UIWindow *window = [GLUtils keyWindow];
    [window addSubview:self.view];
    self.view.frame = window.bounds;
    [self.view addSubview:controller.view];
    [controller.view mas_makeConstraints:^(MASConstraintMaker *maker)
    {
        maker.leading.equalTo(self.view);
        maker.trailing.equalTo(self.view);
        maker.bottom.equalTo(self.view);
        maker.height.equalTo(@(controller.view.bounds.size.height));
    }];
    [controller.view layoutIfNeeded];
    CGSize winSize = window.bounds.size; 
    CGSize contentSize = controller.view.frame.size;
    self.contentView.center = CGPointMake(winSize.width / 2, winSize.height + contentSize.height/2);
    self.maskView.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
       self.maskView.alpha = 0.5;
       self.contentView.center = CGPointMake(winSize.width / 2, winSize.height - contentSize.height/2);
    }];
    [controller didMoveToParentViewController:self];
}

- (void)dismiss {
    [self.contentController willMoveToParentViewController:nil];
    UIWindow *window = [GLUtils keyWindow];
    CGSize winSize = window.bounds.size;
    [UIView animateWithDuration:0.3 animations:^{
        // drop down
        self.contentView.center = CGPointMake(winSize.width / 2, self.view.frame.size.height + self.contentView.frame.size.height/2);
        self.maskView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self.contentView removeFromSuperview];
        [self.contentController removeFromParentViewController];
        self.contentController = nil;
    }];
}

@end

//
//  DropdownMessageController.m
//  emma
//
//  Created by Ryan Ye on 4/2/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLFoundation.h"
#import "GLDropdownMessageController.h"
#import "NSString+Markdown.h"

#define MESSAGE_Y 84


@interface GLDropdownMessageController () {
    IBOutlet UILabel *messageLabel;
}
@end

@implementation GLDropdownMessageController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.cornerRadius = self.view.layer.frame.size.height / 2;
    // Do any additional setup after loading the view from its nib.
}

+ (GLDropdownMessageController *)sharedInstance {
    static GLDropdownMessageController *_controller = nil;
    if (!_controller) {
        _controller = [[GLDropdownMessageController alloc] init];
    }
    return _controller;
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval
    inWindow:(UIView *)parentWindow {
    [self postMessage:message duration:timeInterval position:84
        inView:parentWindow];
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval inView:(UIView *)parentView {
    [self postMessage:message duration:timeInterval position:MESSAGE_Y inView:parentView];
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval position:(CGFloat)posY inView:(UIView *)parentView {
    self.view.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, -40);
    self.view.alpha = 1.0;
    messageLabel.attributedText = [NSString markdownToAttributedText:message fontSize:15.0 color:[UIColor whiteColor]];
    messageLabel.textAlignment = NSTextAlignmentCenter;
    messageLabel.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width - 25;
    CGSize size = [messageLabel sizeThatFits:CGSizeMake(messageLabel.preferredMaxLayoutWidth, 1024)]; //[self.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    self.view.bounds = CGRectMake(0, 0, size.width + 20, size.height + 15);
    [self.view layoutSubviews];
    [parentView addSubview:self.view];
    [UIView animateWithDuration:0.5 animations:^{
        self.view.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, posY);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:timeInterval options:0 animations:^{
            self.view.alpha = 0;
        } completion: nil];
    }];
}

- (void)clearMessage {
    [self.view.layer removeAllAnimations];
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 0;
    } completion: nil];
}
@end
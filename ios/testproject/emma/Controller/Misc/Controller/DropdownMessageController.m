//
//  DropdownMessageController.m
//  emma
//
//  Created by Ryan Ye on 4/2/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DropdownMessageController.h"

#define MESSAGE_Y 84
#define SINGLE_LINE_H 21
#define PADDING_Y 9

@interface DropdownMessageController () {
    IBOutlet UILabel *messageLabel;
}
@end

@implementation DropdownMessageController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.cornerRadius = self.view.layer.frame.size.height / 2;
    // Do any additional setup after loading the view from its nib.
}

+ (DropdownMessageController *)sharedInstance {
    static DropdownMessageController *_controller = nil;
    if (!_controller) {
        _controller = [[DropdownMessageController alloc] init];
    }
    return _controller;
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval inWindow:(UIView *)parentWindow {
    [self postMessage:message duration:timeInterval position:84 inView:parentWindow];
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval inView:(UIView *)parentView {
    [self postMessage:message duration:timeInterval position:MESSAGE_Y inView:parentView];
}

- (void)postMessage:(NSString *)message duration:(NSTimeInterval)timeInterval position:(CGFloat)posY inView:(UIView *)parentView {

    self.view.size = (CGSize){self.view.size.width, SINGLE_LINE_H + PADDING_Y};

    self.view.center = CGPointMake(SCREEN_WIDTH/2, -40);
    self.view.alpha = 1.0;
//    messageLabel.text = message;
    messageLabel.attributedText = [Utils markdownToAttributedText:message fontSize:15.0 color:[UIColor whiteColor]];
    messageLabel.textAlignment = NSTextAlignmentCenter;

    int lines = [message componentsSeparatedByString:@"\n"].count;
    self.view.size = (CGSize){self.view.size.width,
        lines * SINGLE_LINE_H + PADDING_Y};

    [parentView addSubview:self.view];
    [UIView animateWithDuration:0.5 animations:^{
        self.view.center = CGPointMake(SCREEN_WIDTH/2,
            posY + (self.view.size.height - SINGLE_LINE_H - PADDING_Y) / 2);
    }completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:timeInterval options:nil animations:^{
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

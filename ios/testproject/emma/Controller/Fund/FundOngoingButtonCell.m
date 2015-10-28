//
//  FundOngoingButtonCell.m
//  emma
//
//  Created by Jirong Wang on 12/16/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundOngoingButtonCell.h"
#import "Logging.h"

@interface FundOngoingButtonCell ()

@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) IBOutlet UIView *buttonBG;

@property (nonatomic) BOOL isPregnantButton;

- (IBAction)actionButtonUp:(id)sender;
- (IBAction)actionButtonDown:(id)sender;

@end

@implementation FundOngoingButtonCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.actionButton.layer.cornerRadius = 70;
    self.buttonBG.layer.cornerRadius = 70;
    self.actionButton.transform =  CGAffineTransformMakeScale(.0, .0);
    self.buttonBG.transform =  CGAffineTransformMakeScale(.0, .0);
    self.isPregnantButton = YES;
}

- (IBAction)actionButtonUp:(id)sender {
    GLLog(@"stop button pressed");
    if (self.isPregnantButton) {
        [Logging log:BTN_CLK_FUND_PREGNANT];
        [self publish:EVENT_USER_CLK_PREGNANT];
    } else {
        // TODO, logging quit demo button
        // [Logging log:BTN_CLK_FUND_PREGNANT];
        [self publish:EVENT_FUND_QUIT_DEMO_PRESSED];
    }
    //    [self publish:EVENT_PREGNANT_PRESSED];
    self.actionButton.backgroundColor = UIColorFromRGB(0xe84f89);
}

- (IBAction)actionButtonDown:(id)sender {
    self.actionButton.backgroundColor = UIColorFromRGB(0xd8497f);
}

- (void)animateIn {
    if (self.circleOn) {
        return;
    } else {
        self.circleOn = YES;
    }
    
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.actionButton.transform = CGAffineTransformMakeScale(1.0, 1.0);
                         self.buttonBG.transform = CGAffineTransformMakeScale(1.0, 1.0);
                     } completion:nil];
}

- (void)animateOut {
    if (self.circleOn) {
        self.circleOn = NO;
    } else {
        return;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.actionButton.transform = CGAffineTransformMakeScale(.0, .0);
        self.buttonBG.transform = CGAffineTransformMakeScale(.0, .0);
    } completion:nil];
}

- (void)setIsPregnantButton:(BOOL)isPregnantButton {
    _isPregnantButton = isPregnantButton;
    NSString * text = isPregnantButton ? @"**Because I am pregnant!**" : @"**Exit demo**";
    NSAttributedString * attributedText = [Utils markdownToAttributedText:text fontSize:19 lineHeight:19 color:[UIColor whiteColor] alignment:NSTextAlignmentCenter];
    [self.actionButton setAttributedTitle:attributedText forState:UIControlStateNormal];
    [self.actionButton setAttributedTitle:attributedText forState:UIControlStateHighlighted];
}

@end

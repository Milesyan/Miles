//
//  ScannerFocusView.m
//  emma
//
//  Created by ltebean on 14-12-26.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ScannerFocusView.h"

#define BORDER_WIDTH 1
#define LINE_WIDTH 50

@interface ScannerFocusView()
@property (nonatomic) BOOL loaded;
@property (nonatomic,strong) UIView *scanLine;
@property (nonatomic) BOOL stopAnimating;
@end

@implementation ScannerFocusView


- (void)setup
{
    if(self.loaded){
        return;
    }
    
    self.backgroundColor = [UIColor clearColor];
    
    // left top
    UIView *line1 = [self makeHorizontalLine];
    [self addSubview:line1];
    
    UIView *line2 = [self makeVerticalLine];
    [self addSubview:line2];
    
    // left bottom
    UIView *line3 = [self makeHorizontalLine];
    line3.top = self.height - BORDER_WIDTH;
    [self addSubview:line3];

    UIView *line4 = [self makeVerticalLine];
    line4.top = self.height - LINE_WIDTH;
    [self addSubview:line4];

    // right top
    UIView *line5 = [self makeHorizontalLine];
    line5.left = self.width - LINE_WIDTH;
    [self addSubview:line5];

    UIView *line6 = [self makeVerticalLine];
    line6.left = self.width - BORDER_WIDTH;
    [self addSubview:line6];
    
    // right bottom
    UIView *line7 = [self makeHorizontalLine];
    line7.top = self.height - BORDER_WIDTH;
    line7.left = self.width - LINE_WIDTH;
    [self addSubview:line7];
    
    UIView *line8 = [self makeVerticalLine];
    line8.top = self.height - LINE_WIDTH;
    line8.left = self.width - BORDER_WIDTH;
    [self addSubview:line8];
    
    self.scanLine = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.width, 1)];
    self.scanLine.backgroundColor = [UIColor redColor];
    [self addSubview:self.scanLine];
    
    self.loaded = YES;

}

- (void)startAnimation
{
    self.stopAnimating = NO;
    [self playAnimation];
}

- (void)playAnimation
{
    if (self.stopAnimating) {
        return;
    }
    self.stopAnimating = NO;
    [UIView animateWithDuration:2.0
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         self.scanLine.transform = CGAffineTransformMakeTranslation(0, self.height-2);
                     } completion:^(BOOL finished) {
                         self.scanLine.transform = CGAffineTransformIdentity;
                         [self playAnimation];
                     }];
}

- (void)stopAnimation
{
    self.stopAnimating = YES;
}


- (UIView *)makeVerticalLine
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, BORDER_WIDTH, LINE_WIDTH)];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

- (UIView *)makeHorizontalLine
{
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, LINE_WIDTH, BORDER_WIDTH)];
    view.backgroundColor = [UIColor whiteColor];
    return view;
}

@end

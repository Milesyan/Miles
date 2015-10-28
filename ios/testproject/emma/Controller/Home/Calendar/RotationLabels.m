//
//  RotationLabels.m
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "RotationLabels.h"

#define MAX_LABLE_COUNT 3
#define TRANSITION_TIME 0.4f
#define SHOWING_TIME 1.5f


@implementation RotationLabels {
    NSInteger numOfRotatingLabels;
    CADisplayLink *labelsRotationDL;
}


- (void)prepareLabelsForView:(UIView *)view
{
    labelsRotationDL = nil;
    self.labelArray = [@[] mutableCopy];
    for (NSInteger i = 0; i < MAX_LABLE_COUNT; i++) {
        UILabel *label = [[UILabel alloc] init];
        [label setTextColor:[UIColor whiteColor]];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setBackgroundColor:[UIColor clearColor]];
        label.alpha = 0;
        [self.labelArray addObject:label];
        [view addSubview:label];
    }
    ((UILabel*) self.labelArray[0]).alpha = 1.f;
}


- (void)setFrame:(CGRect)frame
{
    for (UILabel *label in self.labelArray) {
        [label setFrame:frame];
    }
}


- (void)setTipStrings:(NSArray *)tips {
    numOfRotatingLabels = MIN(3, [tips count]);
    for (NSInteger i = 0; i < numOfRotatingLabels; i++) {
        [self.labelArray[i] setNumberOfLines:0];
        [self.labelArray[i] setAttributedText:tips[i]];
        [self.labelArray[i] setTextAlignment:NSTextAlignmentCenter];
    }
    [self show];
}


- (void)hide {
    for (UILabel *label in self.labelArray) {
        label.alpha = 0;
    }
}


static NSInteger currentLabelIndex = 0;
- (void)show
{
    currentLabelIndex = currentLabelIndex >= numOfRotatingLabels
    ? 0 : currentLabelIndex;
    
    [self hide];
    ((UILabel *) self.labelArray[currentLabelIndex]).alpha = 1.f;
}


- (void)setCurrentLabelIndex:(NSInteger)index
{
    currentLabelIndex = index;
}


#pragma mark - Tips animation
- (void)doLabelRotation
{
    currentLabelIndex = currentLabelIndex >= numOfRotatingLabels ? 0 : currentLabelIndex;
    NSInteger labelIndexFadeIn = currentLabelIndex + 1 >= numOfRotatingLabels ? 0 : currentLabelIndex + 1;
    
    [self show];
    
    if (labelIndexFadeIn != currentLabelIndex)
    {
        [UIView animateWithDuration:0.25f animations:^{
            ((UILabel *) self.labelArray[currentLabelIndex]).alpha = 0;
            ((UILabel *) self.labelArray[labelIndexFadeIn]).alpha = 1.f;
        } completion:^(BOOL finished){
            currentLabelIndex++;
        }];
    }
}

//- (void)tapToScale
//{
//    tipsAlpha += alphaInterval;
//    if (tipsAlpha > numOfRotatingLabels * (TRANSITION_TIME + SHOWING_TIME)) {
//        tipsAlpha = 0.0f;
//    }
//
//    [self show];
//
////    GLLog(@"zx debug tips alp %f", tipsAlpha);
//}


- (void)stopRotation {
    [labelsRotationDL invalidate];
    labelsRotationDL = nil;
}

@end

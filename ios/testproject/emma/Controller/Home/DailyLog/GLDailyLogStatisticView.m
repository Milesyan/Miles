//
//  GLDailyLogStatisticView.m
//  kaylee
//
//  Created by Eric Xu on 11/18/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import "GLDailyLogStatisticView.h"
#import "Tooltip.h"
#import "HealthAwareness.h"

@implementation GLDailyLogStatisticView


- (void)awakeFromNib
{
    self.shadow.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
    [self setupTintColor];
    
    [self.physicalView.superview setTapActionWithBlock:^{
        [self publish:EVENT_GO_PHYSICAL];
    }];
    [self.emotionalView.superview setTapActionWithBlock:^{
        [self publish:EVENT_GO_EMOTIONAL];
    }];
    [self.fertilityView.superview setTapActionWithBlock:^{
        [self publish:EVENT_GO_FERTILITY];
    }];
    
    [self.overallView.superview setTapActionWithBlock:^{
        [Tooltip tip:@"Today's health awareness"];
    }];
    
    self.itemsContainer.aWidth = IS_IPHONE_6_PLUS ? 332 : (IS_IPHONE_6 ? 315 : 290);
}

- (void)setupTintColor {
    NSArray *views = @[self.physicalView, self.emotionalView, self.fertilityView];
    for (DACircularProgressView *each in views) {
        [each setRoundedCorners:YES];
        [each setClockwiseProgress:YES];
        [each setTintColor:GLOW_COLOR_PINK];
        [each setProgressTintColor:UIColorFromRGB(0xF65F4D)];
        [each setTrackTintColor:UIColorFromRGBA(0xF65F4D50)];
        [each setThicknessRatio:0.2];
    }
}

- (void)clearStates
{
    [self.overallView setProgress:0 animated:NO];
    
    NSArray *views = @[self.physicalView, self.emotionalView, self.fertilityView];
    for (DACircularProgressView *each in views) {
        [each setProgress:0 animated:NO];
    }
    
    views = @[self.physicalValueLabel, self.emotionalValueLabel,
              self.fertilityValueLabel, self.overallValueLabel];
    
    for (UILabel *each in views) {
        each.text = @"0%";
    }
}

- (void)displayLayer:(CALayer *)layer {
    [super displayLayer:layer];
    if (!IOS8_OR_ABOVE) {
        // fix iOS7 problem
        NSArray *views = @[self.physicalView, self.emotionalView, self.fertilityView];
        for (DACircularProgressView *each in views) {
            [each setTintColor:GLOW_COLOR_PINK];
            [each setProgressTintColor:UIColorFromRGB(0xF65F4D)];
            [each setTrackTintColor:UIColorFromRGBA(0xF65F4D50)];
        }
    }
}

- (void)reloadWithDailyData:(NSDictionary *)data
{
    NSDictionary *scores = [HealthAwareness allScore:data];
    float pScore =    [scores[kPhysicalAwareness] floatValue];
    float eScore =    [scores[kEmotionalAwareness] floatValue];
    float fScore =    [scores[kFertilityAwareness] floatValue];
    float allScore =  [scores[kHealthAwareness] floatValue];
    
    [self.emotionalView setProgress:eScore animated:YES];
    [self.emotionalValueLabel setText:[NSString stringWithFormat:@"%d%%", (int)((eScore)*100)]];
    
    [self.fertilityView setProgress:fScore animated:YES];
    [self.fertilityValueLabel setText:[NSString stringWithFormat:@"%d%%", (int)((fScore)*100)]];
    
    [self.physicalView setProgress:pScore animated:YES];
    [self.physicalValueLabel setText:[NSString stringWithFormat:@"%d%%", (int)((pScore)*100)]];
    
    [self.overallView setProgress:allScore animated:YES];
    [self.overallValueLabel setText:[NSString stringWithFormat:@"%d%%", (int)((allScore)*100)]];
}




@end

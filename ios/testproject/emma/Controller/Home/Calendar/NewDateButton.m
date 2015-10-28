//
//  NewDateButton.m
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "NewDateButton.h"
#import "RotationLabels.h"


@implementation NewDateButton

- (id)init {
    self = [super init];
    if (self) {
        self.topLabel = [[UILabel alloc] init];
        [self.topLabel setTextColor:[UIColor whiteColor]];
        [self.topLabel setTextAlignment:NSTextAlignmentCenter];
        [self.topLabel setBackgroundColor:[UIColor clearColor]];
        self.rotationTips = [[RotationLabels alloc] init];
        [self.rotationTips prepareLabelsForView:self];
        
        self.bottomLabel = [[UILabel alloc] init];
        [self.bottomLabel setTextColor:[UIColor whiteColor]];
        [self.bottomLabel setTextAlignment:NSTextAlignmentCenter];
        [self.bottomLabel setBackgroundColor:[UIColor clearColor]];
        attributedTipsArray = [@[] mutableCopy];
        self.breakLine = [[UIView alloc] init];
        self.breakLine.backgroundColor = UIColorFromRGBA(0xEEEEEEEE);
        
        self.animateLabel = ({
            UILabel *label = [[UILabel alloc] init];
            [label setTextColor:[UIColor whiteColor]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setBackgroundColor:[UIColor clearColor]];
            label.alpha = 0;
            label;
        });
        
        [self addSubview:self.topLabel];
        [self addSubview:self.bottomLabel];
        [self addSubview:self.breakLine];
        [self addSubview:self.animateLabel];
        
        self.isNormal = YES;
        self.layer.masksToBounds = NO;
        self.backgroundColor = [UIColor clearColor];
        
        self.glowLayer = ({
            CAGradientLayer *layer = [CAGradientLayer layer];
            layer.colors = [NSArray arrayWithObjects:(id)[[UIColor blackColor] CGColor],
                            (id)[[UIColor clearColor] CGColor], nil];
            layer.startPoint = CGPointZero;
            layer.endPoint = CGPointMake(1, 1);
            layer;
        });
        // [self.layer addSublayer:self.glowLayer];
    }
    return self;
}

- (void)addTarget:(id)target action:(SEL)selector {
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:target
                                   action:selector];
    [self addGestureRecognizer:tap];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.glowLayer.frame = self.frame;
    self.layer.cornerRadius = frame.size.height/2;
    float width = frame.size.width;
    
    [self.topLabel setFrame:CGRectMake(0, width/5, width, width/5)];
    if (self.isNormal) {
        [self.bottomLabel setFrame:CGRectMake(0, width*2/5, width, width * 2/5)];
        [self.rotationTips setFrame:CGRectMake(0, width*2/5, width, width * 2/5)];
    } else {
        [self.bottomLabel setFrame:CGRectMake(0, width*2/5, width, width * 2.5/5)];
        [self.rotationTips setFrame:
         CGRectMake(0, width*2/5, width, width * 2.5/5)];
    }
    self.animateLabel.frame = self.bottomLabel.frame;
    [self.breakLine setFrame:CGRectMake(width/10, width*2/5, width * 4/5, 0.5)];
}


- (void)setDate:(NSDate *)date
{
    _date = date;
    
    NSDateComponents *comps = [self.calendar components:NSDayCalendarUnit|NSWeekdayCalendarUnit fromDate:date];
    
    self.day = [NSString stringWithFormat:@"%ld", (long)comps.day];
    self.weekday = [[self.formatter.shortWeekdaySymbols objectAtIndex:comps.weekday-1] uppercaseString];
    
    self.isNormal = NO;
    [self showAsNormalButton];
}


- (void)setTips:(NSArray *)tips
{
    //attributedTips
    //NSArray *attributedTips = @[
    [attributedTipsArray removeAllObjects];
    
    for (NSString *tip in tips) {
        [attributedTipsArray addObject:[Utils markdownToAttributedText:tip
                                                              fontSize:14 color:[UIColor whiteColor]]];
    }
    if (!self.isNormal) {
        [self.rotationTips setTipStrings:attributedTipsArray];
    }
}


- (void)setBottomAnimateTip:(NSString *)tip
{
    if (tip)
    {
        [self.rotationTips hide];
        self.animateLabel.alpha = 1;
        NSAttributedString *attributedTip = [Utils markdownToAttributedText:tip
                                                                   fontSize:14
                                                                      color:[UIColor whiteColor]];
        [self.animateLabel setNumberOfLines:0];
        [self.animateLabel setAttributedText:attributedTip];
        [self.animateLabel setTextAlignment:NSTextAlignmentCenter];
    }
    else
    {
        [self.rotationTips show];
        self.animateLabel.text = nil;
        self.animateLabel.alpha = 0;
    }
}

- (void)hideBottomAnimateTip
{
    [self.rotationTips show];
    self.animateLabel.text = nil;
    self.animateLabel.alpha = 0;
}

- (void)showAsNormalButton
{
    if (self.isNormal) {
        return;
    }
    
    self.isNormal = YES;
    
    [self.topLabel setText:self.weekday];
    [self.topLabel setFont:[Utils defaultFont:9]];
    
    self.bottomLabel.hidden = NO;
    [self.bottomLabel setText:self.day];
    [self.bottomLabel setFont:[Utils boldFont:24]];
    
    self.animateLabel.alpha = 0;
    [self.breakLine setAlpha:0];
    
    CGPoint center = self.center;
    CGRect f = CGRectMake(center.x - BUTTON_WIDTH_NORMAL/2, center.y - BUTTON_WIDTH_NORMAL/2, BUTTON_WIDTH_NORMAL, BUTTON_WIDTH_NORMAL);
    self.frame = f;
    
    //[self.rotationTips stopRotation];
    [self.rotationTips hide];
    
}


- (void)showAsCentralButton
{
    if (!self.isNormal) {
        return;
    }
    self.isNormal = NO;
    
    NSAttributedString *attrStr = [Utils markdownToAttributedText:[NSString stringWithFormat:@"%@ **%@**", self.weekday, self.day] fontSize:15 color:[UIColor whiteColor]];
    [self.topLabel setAttributedText: attrStr];
    [self.topLabel setTextAlignment:NSTextAlignmentCenter];
    
    self.bottomLabel.hidden = YES;
    self.animateLabel.alpha = 0;
    [self.rotationTips setTipStrings:attributedTipsArray];
    
    [self.breakLine setAlpha:1.0];
    
    CGPoint center = self.center;
    CGRect f = CGRectMake(center.x - BUTTON_WIDTH_CENTRAL/2, center.y - BUTTON_WIDTH_CENTRAL/2, BUTTON_WIDTH_CENTRAL, BUTTON_WIDTH_CENTRAL);
    self.frame = f;
    
    //[self.rotationTips show];
    //[self startScaleAnimationToLength:0];
    
    [self.rotationTips show];
}

- (void)updateForPosition:(float)offsetX
{
    CGFloat centerX = (self.tag - PAGE_INDEX_BASE + 0.5) * TINY_PAGE_WIDTH;
    CGFloat position = centerX - offsetX - SCREEN_WIDTH/2;
    NSInteger sign = position >= 0 ? 1 : -1;
    CGFloat distance = position * sign;
    if (distance >= TINY_PAGE_WIDTH) {
        self.center = CGPointMake(centerX + sign * BUTTON_CENTER_SHIFT, BUTTONS_CENTER_Y);
        if(distance >= 2 * TINY_PAGE_WIDTH) {
            self.alpha = 0.8;
        } else {
            self.alpha = 1.0 - 0.2 * (distance / TINY_PAGE_WIDTH - 1);
        }
        self.layer.transform = CATransform3DIdentity;
        [self showAsNormalButton];
        return;
    }
    position = position / TINY_PAGE_WIDTH;
    distance = sign * position;
    self.center = CGPointMake(centerX + BUTTON_CENTER_SHIFT * position, BUTTONS_CENTER_Y);
    self.alpha = 1.0;
    
    BOOL isCentral = distance < 0.5;
    BOOL isCentralCandidate = !isCentral;
    
    if (isCentral) {
        [self showAsCentralButton];
    } else {
        [self showAsNormalButton];
    }
    
    sign = isCentralCandidate? sign: sign * -1;
    NSInteger reverse = isCentralCandidate? -1: 1;
    if (distance > 0.5) {
        reverse = reverse* -1;
    }
    
    float x2 = fabsf((distance - 0.5)) / 0.5;
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 1.0 / -500 * reverse;
    transform = CATransform3DRotate(transform, (x2 - 1) * M_PI_2, 0.0f, 1.0f * sign, 0.0f);
    
    if (isCentralCandidate) {
        float factor = distance > 0.5 ? 3 - 2 * distance : 1 + 2 * distance;
        transform = CATransform3DScale(transform, factor, factor, 1);
    } else {
        transform = CATransform3DScale(transform, 1, 1, 1);
    }
    self.layer.transform = transform;
}
//
//- (void) pauseLabelRotationAnimation {
//    GLLog(@"zx debug pause");
//    [self.rotationTips stopRotation];
//}
//
//- (void) rotateTips {
//    GLLog(@"zx debug continue");
//    [self.rotationTips labelRotation];
//}


@end


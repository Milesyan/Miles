//
//  DateButton.m
//  emma
//
//  Created by Peng Gu on 11/4/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DateButton.h"
#import <objc/runtime.h>
#import "User+DailyData.h"
#import "UserMedicalLog.h"
#import "Appointment.h"

#pragma mark -
#pragma mark - Interface DateButton
@interface DateButton ()

@property (nonatomic, assign) BOOL selected;
@property (nonatomic, assign) float width;
@property (nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@property (nonatomic, strong) UIImageView *firstIcon;
@property (nonatomic, strong) UIImageView *secondIcon;
@property (nonatomic, strong) UIImageView *thirdIcon;

@end

#pragma mark -
#pragma mark - Implementation DateButton
@implementation DateButton

@synthesize date = _date;
@synthesize calendar = _calendar;
@synthesize formatter;

@dynamic hitTestEdgeInsets;


- (id)init {
    self = [super init];
    if (self) {
        [self internalInit];
    }
    return self;
}


- (void)internalInit
{
    self.textColor = [UIColor whiteColor];
    self.textAlignment = NSTextAlignmentCenter;
    self.shadowColor = UIColorFromRGBA(0x46);
    self.shadowOffset = CGSizeMake(0.0, 1.5);
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = NO;
    [self setHitTestEdgeInsets:UIEdgeInsetsMake(-5, -5, -5, -5)];
    
    
    CGFloat offset = (IS_IPHONE_6_PLUS ? 14 : (IS_IPHONE_6 ? 14 : 12));
    CGFloat originX = DEFAULT_CELL_WIDTH - offset;
    CGFloat originY = DEFAULT_CELL_WIDTH - offset + 1;
    
    self.firstIcon = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 13, 13)];
    
    originX -= offset - 1;
    self.secondIcon = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 13, 13)];

    originX -= offset - 1;
    self.thirdIcon = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 13, 13)];
    
    [self addSubview:self.firstIcon];
    [self addSubview:self.secondIcon];
    [self addSubview:self.thirdIcon];
}


- (void)setDate:(NSDate *)date
{
    _date = date;
    
    NSDateComponents *comps = [[Utils calendar] components:NSDayCalendarUnit|NSMonthCalendarUnit|NSMonthCalendarUnit fromDate:date];
    [self setText:[NSString stringWithFormat:@"%ld", (long)comps.day]];
}


- (void)updateIcons
{
    [self clearIcons];
    
    if (self.hasMedication) {
        [self addIcon:[UIImage imageNamed:@"calendar-medication"]];
    }
    if (self.hasAppointment) {
        [self addIcon:[UIImage imageNamed:@"calendar-appointment"]];
    }
    if (self.hasSex) {
        [self addIcon:[UIImage imageNamed:@"calendar-sex"]];
    }
    
    if (!self.hasMedication && !self.hasAppointment && !self.hasSex && self.hasLog) {
        [self addIcon:[UIImage imageNamed:@"calendar-check"]];
    }
}


- (void)addIcon:(UIImage *)image
{
    if (!self.firstIcon.image) {
        self.firstIcon.image = image;
    }
    else if (!self.secondIcon.image) {
        self.secondIcon.image = image;
    }
    else if (!self.thirdIcon.image) {
        self.thirdIcon.image = image;
    }
}


- (void)clearIcons
{
    self.firstIcon.image = nil;
    self.secondIcon.image = nil;
    self.thirdIcon.image = nil;
}


#pragma mark -
-(CGFloat)radiusForBounds:(CGRect)bounds
{
    return fminf(bounds.size.width, bounds.size.height) / 2;
}

-(void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.layer.cornerRadius = [self radiusForBounds:frame];
}

static const NSString *KEY_HIT_TEST_EDGE_INSETS = @"HitTestEdgeInsets";

-(void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = [NSValue value:&hitTestEdgeInsets withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

-(UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS);
    if(value) {
        UIEdgeInsets edgeInsets; [value getValue:&edgeInsets]; return edgeInsets;
    }else {
        return UIEdgeInsetsZero;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if(UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.userInteractionEnabled || self.hidden) {
        return [super pointInside:point withEvent:event];
    }
    
    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);
    
    return CGRectContainsPoint(hitFrame, point);
}
@end
//
//  DailyLogCellTypeBase.m
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//


#import "DailyLogCellTypeBase.h"
#import "Logging.h"
#import "UserDailyData.h"
#import "User.h"

#define BUTTON_WIDTH 36
#define BUTTON_PADDING 10

@interface DailyLogCellTypeBase()
@property (nonatomic, strong) UIImageView* hiddenIndicator;
@end

@implementation DailyLogCellTypeBase

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setSelectionStyle:UITableViewCellSelectionStyleNone];
        [self setClipsToBounds:YES];
        [self setup];
    }
    return self;
}

- (void)setup {

}

- (UIImageView *)hiddenIndicator
{
    if (_hiddenIndicator) {
        return _hiddenIndicator;
    }
    CGFloat size = 32;
    _hiddenIndicator = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
    _hiddenIndicator.image = [UIImage imageNamed:@"hidden-indicator"];
    _hiddenIndicator.top = 0;
    _hiddenIndicator.left = SCREEN_WIDTH - size;
    [self addSubview:_hiddenIndicator];
    return _hiddenIndicator;
}


- (void)setDataKey:(NSString *)dataKey {
    if ([User currentUser].partner && [UserDailyData isSensitiveItem:dataKey]) {
        self.hiddenIndicator.hidden = NO;
    } else {
        self.hiddenIndicator.hidden = YES;
    }
    _dataKey = dataKey;
    [self internalConfig];
}

- (void)configWithTemplate:(NSDictionary *)template {
//    label.text = [template valueForKey:@"label"];
//    [label sizeToFit];
}

- (void)internalConfig {

}

- (void)setValue:(NSObject*)value forDate:(NSDate *)date{
    self.date = date;
}

- (IBAction)buttonTouched:(id) sender {
    GLLog(@"buttonTouched: %@", sender);
    GLLog(@"exclusiveButtons: %@", exclusiveButtons);
    UIButton *button = (UIButton *)sender;

    for (UIButton *b in exclusiveButtons) {
        if (b != button && b.selected) {
            b.selected = NO;
        }
    }
    [self.delegate findAndResignFirstResponder];
    [self updateData];
}

- (void)updateData {
    NSInteger i = 0;
    for (UIButton *b in exclusiveButtons) {
        i = i + (b.selected? b.tag : 0);
    }
    
    [self.delegate updateDailyData:self.dataKey withValue:@(i)];
}

- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)height{
    if (!self.hideSwitch) {
        self.hideSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, (height - 30) / 2, 0, 0)];
        self.hideSwitch.frame = setRectX(self.hideSwitch.frame, SCREEN_WIDTH - 10 - self.hideSwitch.frame.size.width);
    }
    [self.hideSwitch addTarget:self
                        action:@selector(onSwitched:)
              forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.hideSwitch];
    [self.hideSwitch setOn:visible];
    
    for (UIButton *btn in exclusiveButtons) {
        [btn setAlpha:0];
    }
}

- (void)exitEditing {
    [self.hideSwitch removeFromSuperview];
    [self.hideSwitch removeTarget:self action:@selector(onSwitch:) forControlEvents:UIControlEventValueChanged];
    
    for (UIButton *btn in exclusiveButtons) {
        [btn setAlpha:1];
    }
}

- (IBAction)onSwitched:(id)sender {
    UISwitch *_switch = (UISwitch*) sender;
    [self.delegate setCell:self visible:_switch.isOn];
}

- (NSString *)getClickType:(UIButton *)btn yesBtnTag:(NSUInteger)tag {
    if (btn.tag == tag) {
        return btn.selected ? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    } else {
        return btn.selected ? CLICK_TYPE_NO_SELECT : CLICK_TYPE_NO_UNSELECT;
    }
}

- (void)logButton:(NSString *)eventName clickType:(NSString *)clickType eventData:(NSDictionary *)eventData {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithDictionary:eventData];
    // click type
    if (![Utils isEmptyString:clickType])
        [dict setObject:clickType forKey:@"click_type"];
    
    // daily time
    [dict setObject:@((int64_t)[self.date timeIntervalSince1970]) forKey:@"daily_time"];
    
    [Logging log:eventName eventData:dict];
}
@end

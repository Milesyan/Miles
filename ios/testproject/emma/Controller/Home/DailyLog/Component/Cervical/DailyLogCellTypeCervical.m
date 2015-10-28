//
//  DailyLogCellTypeCervical.m
//  emma
//
//  Created by Eric Xu on 12/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
//  Cervical position

#import "DailyLogCellTypeCervical.h"
#import "PillButton.h"
#import "CervicalCheckPicker.h"
#import "Logging.h"
#import "UserDailyData+CervicalPosition.h"

@interface DailyLogCellTypeCervical() <UIActionSheetDelegate>{
    IBOutlet PillButton *button;
    CervicalCheckPicker *picker;
}

@property (nonatomic, strong) NSDictionary *cervicalStatus;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *buttonWidthConstraint;

@end


@implementation DailyLogCellTypeCervical

- (void)awakeFromNib
{
    picker = [[CervicalCheckPicker alloc] init];
}


- (void)setValue:(NSObject *)value forDate:(NSDate *)date
{
    [super setValue:value forDate:date];
    
    if (value) {
        self.cervicalStatus = [UserDailyData getCervicalPositionStatusFromValue:[(NSNumber *)value unsignedLongLongValue]];
        [self updateButton];
    }
}


- (void)updateButton
{
    NSString *description = [UserDailyData statusDescriptionForCervicalStatus:self.cervicalStatus seperateBy:@"&"];
    CGSize size = [description sizeWithAttributes:@{NSFontAttributeName:button.titleLabel.font}];
    NSUInteger width = (int)size.width + 20;
    if (width < 90) {
        width = 90;
    }
    
    if (self.cervicalStatus.count > 0 && ![description isEqualToString:@""]) {
        [button setLabelText:description bold:YES];
        self.buttonWidthConstraint.constant = width;
        button.selected = YES;
    }
    else {
        [button setLabelText:@"Choose" bold:YES];
        self.buttonWidthConstraint.constant = 90;
        button.selected = NO;
    }
}


- (void)updateData
{
    uint64_t val = [UserDailyData getCervicalValueFromStatus:self.cervicalStatus];
    [self.delegate updateDailyData:self.dataKey withValue:@(val)];
}


- (IBAction)buttonTouched:(id)sender
{
    [picker presentWithCervicalPosition:self.cervicalStatus
                           doneCallback:^(NSDictionary *cervical) {
                               if (![cervical isEqualToDictionary:self.cervicalStatus]) {
                                   self.cervicalStatus = cervical;
                                   [self updateButton];
                                   [self updateData];
                                   
                                   [self logButton:BTN_CLK_HOME_CERVICAL clickType:button.titleLabel.text eventData:nil];
                               }
                               else {
                                   button.selected = YES;
                               }
                           }
                           startoverCallback:^(NSInteger row, NSInteger comp) {
                               self.cervicalStatus = @{@(CervicalPositionHeight): @(0),
                                                       @(CervicalPositionOpenness): @(0),
                                                       @(CervicalPositionFirmness): @(0)};
                               [self updateButton];
                               [self updateData];
                               
                               [self logButton:BTN_CLK_HOME_CERVICAL clickType:CLICK_TYPE_CERVICAL_CANCEL eventData:nil];
                           }];
}

- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)cellHeight {
    [super enterEditingVisibility:visible height:cellHeight];
    [button setAlpha:0];
}

- (void)exitEditing {
    [super exitEditing];
    [button setAlpha:1];
}
@end

//
//  DailyLogCellTypePhysicalDiscomfort.m
//  emma
//
//  Created by Eric Xu on 7/11/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypePhysicalDiscomfort.h"

@implementation DailyLogCellTypePhysicalDiscomfort

- (void)awakeFromNib {
    [super awakeFromNib];
    if ([self.user isPrimaryOrSingle]) {
        self.feelingLabel.text = @"SYMPTOMS";
    } else {
        self.feelingLabel.text = @"HER SYMPTOMS";
    }
        self.exclusive = NO;
    self.expandedButtons = self.symptomButtons;
    
    [self setup];
}

- (User*)user {
    return [User currentUser];
}

- (PillButton *)_buttonWithTitle:(NSString *)title {
    for (PillButton *button in self.expandedButtons) {
        if ([button.titleLabel.text isEqual:title]) {
            return button;
        }
    }
    return nil;
}

- (void)hadSex:(NSNumber *)sex {
    PillButton *otherButton = [self _buttonWithTitle:@"Other"];
    PillButton *painDuringSexButton = [self _buttonWithTitle:@"Pain during sex"];
    if ([sex boolValue]) {
        painDuringSexButton.hidden = NO;
        otherButton.frame = setRectX(otherButton.frame,
            painDuringSexButton.frame.origin.x +
            painDuringSexButton.frame.size.width + 8);
    } else {
        painDuringSexButton.hidden = YES;
        otherButton.frame = setRectX(otherButton.frame, 15);
    }
}

@end

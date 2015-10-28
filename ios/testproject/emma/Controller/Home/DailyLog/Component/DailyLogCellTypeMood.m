//
//  DailyLogCellTypeMood.m
//  emma
//
//  Created by Eric Xu on 4/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeMood.h"
#import "PillButton.h"
#import "User.h"

@interface DailyLogCellTypeMood()

@end

@implementation DailyLogCellTypeMood

- (User*)user {
    return [User currentUser];
}

- (void)awakeFromNib {
    if (self.user.isPrimaryOrSingle) {
        self.feelingLabel.text = @"I'M FEELING";
    } else {
        self.feelingLabel.text = @"SHE'S FEELING";
    }
    self.exclusive = NO;
    if (self.moodOther) {
        self.expandedButtons = @[self.moodSad, self.moodMoody, self.moodAngry, self.moodAnxious, self.moodOther];
    } else {
        self.expandedButtons = @[self.moodSad, self.moodMoody, self.moodAngry, self.moodAnxious];
    }
    self.moodSad.titleLabel.font = [Utils boldFont:FONT_SIZE];
    self.moodMoody.titleLabel.font = [Utils boldFont:FONT_SIZE];
    self.moodStressed.titleLabel.font = [Utils boldFont:FONT_SIZE];
    self.moodAngry.titleLabel.font = [Utils boldFont:FONT_SIZE];
    self.moodAnxious.titleLabel.font = [Utils boldFont:FONT_SIZE];
    self.moodOther.titleLabel.font = [Utils boldFont:FONT_SIZE];
    [self setup];
}


@end

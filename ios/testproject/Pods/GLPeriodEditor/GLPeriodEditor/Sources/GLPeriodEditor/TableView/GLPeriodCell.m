//
//  GLPeriodCell.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLPeriodCell.h"
#import "GLPeriodEditorHeader.h"
#import "GLDateUtils.h"


@interface GLPeriodCell()
@property (weak, nonatomic) IBOutlet UILabel *datesLabel;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *cycleLengthLabel;
@property (weak, nonatomic) IBOutlet UIButton *iconButton;
@end

@implementation GLPeriodCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self subscribe:EVENT_PERIOD_EDITOR_TABLE_CELL_SHOULD_BACK_TO_NORMAL selector:@selector(hideDeleteButton)];
}

- (void)setCycleData:(GLCycleData *)cycleData
{
    _cycleData = cycleData;
    [self updateUI];
}


- (void)updateUI
{
    if (!self.allowDeletion) {
        self.iconButton.hidden = YES;
    } else {
        self.iconButton.hidden = NO;
    }
    self.scrollEnabled = self.allowDeletion;
    self.durationLabel.text = [NSString stringWithFormat:@"%ld", (long)self.cycleData.periodLength];
    if (self.cycleData.cycleLength > 0) {
        self.cycleLengthLabel.text = [NSString stringWithFormat:@"%ld", (long)self.cycleData.cycleLength];
    } else {
        self.cycleLengthLabel.text = @"-";
    }
    self.datesLabel.text = [self datesText];
}

- (NSString *)datesText
{
    return [GLDateUtils descriptionForBeginDate:self.cycleData.periodBeginDate endDate:self.cycleData.periodEndDate];
}


- (IBAction)deleteIconPressed:(id)sender
{
    if (!self.allowDeletion) {
        [self.delegate periodCell:self didWantToDeleteTheLatestCycle:self.cycleData];
        return;
    }
    [self showDeleteButton];
}

- (void)didWantToDelete {
    if (!self.allowDeletion) {
        return;
    }
    self.allowDeletion = NO;
    [self.delegate periodCell:self needsDeleteCycleData:self.cycleData];
}


- (void)dealloc
{
    [self unsubscribeAll];
}

@end

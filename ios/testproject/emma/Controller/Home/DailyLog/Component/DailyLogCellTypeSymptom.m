//
//  SymptomCell.m
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeSymptom.h"
#import "UserDailyData+Symptom.h"


@interface DailyLogCellTypeSymptom ()

@property (nonatomic, strong) IBOutlet UILabel *infoLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *titleLabelCenterConstraint;

@end

@implementation DailyLogCellTypeSymptom

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setup];
}


- (void)setHighlighted:(BOOL)selected animated:(BOOL)animated
{
    [super setHighlighted:selected animated:animated];
}


- (void)configureWithValueOne:(uint64_t)valueOne valueTwo:(uint64_t)valueTwo symptomType:(SymptomType)type
{
    
    NSInteger i = 0;
    for (PillButton *b in exclusiveButtons) {
        i = i + (b.selected? b.tag: 0);
    }
    
    if (i == DAILY_LOG_VAL_YES) {
        self.infoLabel.hidden = NO;
        self.titleLabelCenterConstraint.constant = 12;
    }
    else {
        self.infoLabel.hidden = YES;
        self.titleLabelCenterConstraint.constant = 0;
        return;
    }
    
    NSDictionary *symptoms = [UserDailyData getSymptomsFromFieldOneValue:valueOne
                                                           fieldTwoValue:valueTwo
                                                                    type:type];
    
    unsigned long x = (unsigned long)symptoms.count;
    NSString *format = type == SymptomTypePhysical ? @"%lu symptom%s logged" : @"%lu mood%s logged";
    [self setInfoLabelText:[NSString stringWithFormat:format, x, (x==1 ? "" : "s")]];
}


- (void)buttonTouched:(id)sender
{
    PillButton *button = (PillButton *)sender;
    if (button.selected && button.tag == DAILY_LOG_VAL_YES) {
        [self presentSymptomViewController:sender];
    }

    [super buttonTouched:sender];
}


- (IBAction)presentSymptomViewController:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(symptomCellNeedsToPresentSymptomViewController:)]) {
        [(id<DailyLogCellTypeSymptomDelegate>)self.delegate symptomCellNeedsToPresentSymptomViewController:self];
    }
}


- (void)setInfoLabelText:(NSString *)text
{
    NSDictionary *attrs = @{
                            NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                            NSFontAttributeName: [Utils semiBoldFont:16],
                            NSForegroundColorAttributeName: UIColorFromRGB(0x4751CE)};
    NSAttributedString *attrText = [[NSAttributedString alloc] initWithString:text attributes:attrs];
    self.infoLabel.attributedText = attrText;
}


@end





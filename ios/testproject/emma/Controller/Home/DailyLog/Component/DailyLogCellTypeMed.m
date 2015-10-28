//
//  DailyLogCellTypeMed.m
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeMed.h"
#import "PillButton.h"

@interface DailyLogCellTypeMed()
{
    IBOutlet PillButton *yesBtn;
    IBOutlet PillButton *noBtn;
    IBOutlet UILinkLabel *medLabel;

    UIColor *origBGColor;
}

@end


@implementation DailyLogCellTypeMed
+ (DailyLogCellTypeMed *)getCellForMedName:(NSString *)med {
    DailyLogCellTypeMed *cell = [[NSBundle mainBundle] loadNibNamed:@"DailyLogCellMed"
                                                              owner:nil
                                                            options:nil][0];
    if (med) {
        cell.medName = med;
        cell.label.text = med;
    }
    [cell setReadOnlyStyle];
    return cell;
}

+ (DailyLogCellTypeMed *)getCellForMedicine:(Medicine *)med {
    DailyLogCellTypeMed *cell = [[NSBundle mainBundle] loadNibNamed:@"DailyLogCellMed"
                                                              owner:nil
                                                            options:nil][0];
    if (med) {
        cell.model = med;
        cell.label.text = med.name;
//        cell.label.attributedText = [[NSAttributedString alloc] initWithString:med.name
//                                                                    attributes:@{
//                                                                                 NSForegroundColorAttributeName:UIColorFromRGB(0x4751CE),
//                                                                                 NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]
//                                                                                 }];
    }
    return cell;
}

- (void)setReadOnlyStyle {
//    self.userInteractionEnabled = NO;
    medLabel.textColor = [UIColor darkTextColor];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib {
    exclusiveButtons = @[yesBtn, noBtn];
}

- (NSString *)medName {
    return _medName? _medName: (self.model? self.model.name: nil);
}

- (void)buttonTouched:(id)sender {
    PillButton *button = (PillButton *)sender;
    // logging first
    // ...
    for (PillButton *b in exclusiveButtons) {
        if (b != button && b.selected) {
            [b toggle:YES];
        }
    }
    NSInteger val = button.selected ? button.tag: 0;
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateMed:withValue:)]) {
        if (self.medName) {
            [self.delegate updateMed:self.medName withValue:@(val)];
        }
    }
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];

    if (value) {
        NSDictionary *dic = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:(NSData *)value options:0 error:nil];
        int val = [dic[self.medName] intValue];
        yesBtn.selected = val == yesBtn.tag;
        noBtn.selected = val == noBtn.tag;
    }
}

- (void)setDirectValue:(id)val forDate:(NSDate *)date {
    [super setValue:val forDate:date];
    if (!val) {
        yesBtn.selected = NO;
        noBtn.selected = NO;
    }
    else {
        int intVal = [val intValue];
        yesBtn.selected = intVal == yesBtn.tag;
        noBtn.selected = intVal == noBtn.tag;
    }
}

- (void)setHighlighted:(BOOL)selected animated:(BOOL)animated
{
    if (selected) {
        origBGColor = self.backgroundColor;
        self.backgroundColor = UIColorFromRGB(0x3f47ae);
        self.label.textColor = [UIColor whiteColor];
    } else {
        self.backgroundColor = origBGColor;
        self.label.textColor = UIColorFromRGB(0x5a5ad2);
    }
    
}


@end

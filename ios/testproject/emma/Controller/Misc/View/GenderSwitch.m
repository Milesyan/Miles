//
//  GenderSwitch.m
//  emma
//
//  Created by Eric Xu on 5/16/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//


#import "GenderSwitch.h"

@interface GenderSwitch() {
    IBOutlet UIView *selectedBG;
    IBOutlet UILabel *labelFemale;
    IBOutlet UILabel *labelMale;
    
    __weak IBOutlet UITapGestureRecognizer *tapGestureRecon;
    __weak IBOutlet UISwipeGestureRecognizer *swipeLeft;
    __weak IBOutlet UISwipeGestureRecognizer *swipeRight;
    NSString *value;
}
- (IBAction)tapped:(id)sender;
- (IBAction)swipeLeft:(id)sender;
- (IBAction)swipeRight:(id)sender;
@end

@implementation GenderSwitch

- (void)awakeFromNib {
    selectedBG.layer.cornerRadius = 5;
    value = VAL_FEMALE;
}


- (IBAction)tapped:(id)sender {
    if ([value isEqualToString:VAL_FEMALE]) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             labelFemale.font = [Utils lightFont:16];
                             labelFemale.textColor = [UIColor lightGrayColor];
                             labelMale.font = [Utils semiBoldFont:16];
                             labelMale.textColor = [UIColor whiteColor];

                             selectedBG.frame = setRectX(selectedBG.frame, 62);
                         }
                         completion:^(BOOL finished){

                             [labelMale removeGestureRecognizer:tapGestureRecon];
                             [labelFemale addGestureRecognizer:tapGestureRecon];
                             value = VAL_MALE;
                         }];
        
    } else {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             labelMale.font = [Utils lightFont:16];
                             labelMale.textColor = [UIColor lightGrayColor];
                             labelFemale.font = [Utils semiBoldFont:16];
                             labelFemale.textColor = [UIColor whiteColor];

                             selectedBG.frame = setRectX(selectedBG.frame, 0);
                         }
                         completion:^(BOOL finished){

                             [labelFemale removeGestureRecognizer:tapGestureRecon];
                             [labelMale addGestureRecognizer:tapGestureRecon];
                             value = VAL_FEMALE;
                         }];
    }
}

- (IBAction)swipeLeft:(id)sender {
    if ([value isEqualToString:VAL_MALE]) {
        [self tapped:sender];
    }
    
}

- (IBAction)swipeRight:(id)sender {
    if ([value isEqualToString:VAL_FEMALE]) {
        [self tapped:sender];
    }
}

- (NSString *)selectedValue {
    return value;
}

@end

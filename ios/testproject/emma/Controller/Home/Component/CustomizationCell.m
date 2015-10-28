//
//  CustomizationCell.m
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "CustomizationCell.h"
#import <GLFoundation/NSString+Markdown.h>
@interface CustomizationCell()
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@end

@implementation CustomizationCell

- (void)awakeFromNib {
    // Initialization code
    NSAttributedString *attributedTitle = [NSString addFont:[Utils defaultFont:18.0] toAttributed:[self.moreButton attributedTitleForState:UIControlStateNormal]];
    [self.moreButton setAttributedTitle:attributedTitle forState:UIControlStateNormal];

}

- (IBAction)buttonPressed:(id)sender {
    [self.delegate custmozationCellDidClick:self];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

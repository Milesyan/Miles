//
//  HomeCardCustomizationCell.m
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HomeCardCustomizationCell.h"
#import "HomeCardCustomizationManager.h"

@interface HomeCardCustomizationCell()
@property (weak, nonatomic) IBOutlet UISwitch *switchButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *cardNameLabel;
@end

@implementation HomeCardCustomizationCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setCard:(NSDictionary *)card
{
    _card = card;
    [self updateUI];
}

- (void)updateUI
{
    BOOL display = [[HomeCardCustomizationManager sharedInstance] needsDisplayCard:self.card[@"key"]];
    self.switchButton.on = display;
    self.cardNameLabel.text = self.card[@"title"];
    self.iconView.image = [UIImage imageNamed:self.card[@"icon"]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (IBAction)switchButtonPressed:(UISwitch *)sender {
    [self.delegate customizationCell:self didUpdateCardKey:self.card[@"key"] to:sender.on];
}
@end

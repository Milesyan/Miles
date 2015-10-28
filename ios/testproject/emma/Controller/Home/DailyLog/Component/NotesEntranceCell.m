//
//  NotesEntranceCell.m
//  emma
//
//  Created by Xin Zhao on 7/13/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "NotesEntranceCell.h"
#import "UIView+Emma.h"
#import "HomeCardOperationButton.h"

@interface NotesEntranceCell() {}
@property (weak, nonatomic) IBOutlet UIImageView *disclosureIndicator;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet HomeCardOperationButton *button;
@end

@implementation NotesEntranceCell
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.containerView addDefaultBorder];
    UIImage *image = [Utils image:self.button.imageView.image withColor:GLOW_COLOR_PURPLE];
    [self.button setImage:image forState:UIControlStateNormal];

}

- (IBAction)buttonPressed:(id)sender {
    [self.delegate tableViewCell:self needsPerformSegue:@"homeToNotes"];
}

- (void)setNotesPreview:(NSString *)notesContent {
    if (!notesContent) {
        [self.button setTitle:@"Add a note" forState:UIControlStateNormal];
        self.disclosureIndicator.hidden = YES;
    }
    else {
        [self.button setTitle:notesContent forState:UIControlStateNormal];
        self.disclosureIndicator.hidden = NO;
    }
}
@end

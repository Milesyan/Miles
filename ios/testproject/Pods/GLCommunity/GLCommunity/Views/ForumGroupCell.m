//
//  ForumMenuCell.m
//  emma
//
//  Created by Allen Hsu on 1/29/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <GLFoundation/GLFoundation.h>

#import "Forum.h"
#import "ForumGroupCell.h"

@interface ForumGroupCell ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameTrailingSpace;

@end

@implementation ForumGroupCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupSubviews];
    
    if (IOS8_OR_ABOVE) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
    }
}

- (void)setupSubviews
{
    self.photoBg.layer.cornerRadius = self.photoBg.frame.size.height / 2;
    self.photo.layer.cornerRadius = self.photo.frame.size.height / 2;
    self.photoBg.clipsToBounds = self.photo.clipsToBounds = YES;
    
    self.joinedLabel.layer.cornerRadius = self.joinedLabel.frame.size.height / 2;
    self.joinedLabel.clipsToBounds = YES;
    self.joinButton.layer.cornerRadius = self.joinedLabel.frame.size.height / 2;
    self.joinButton.clipsToBounds = YES;
}

- (void)setCategoryColor:(UIColor *)categoryColor
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.2 : 0 animations:^(){
        self.contentView.backgroundColor = selected ? [UIColor whiteColor] : [UIColor clearColor];
    }];
    //[super setSelected:selected animated:animated];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.2 : 0 animations:^(){
        self.contentView.backgroundColor = highlighted ? [UIColor whiteColor] : [UIColor clearColor];
    }];
}

- (void)setGroup:(ForumGroup *)group
{
    self.nameLabel.text = group.name;
    self.membersLabel.text = group.membersDisplay
                                ? [NSString stringWithFormat:@"Members: %@", group.membersDisplay]
                                : [NSString stringWithFormat:@"Members: %llu", group.members];
    self.creatorLabel.text = group.creatorName
                                ? [NSString stringWithFormat:@"Creator: %@", group.creatorName]
                                : @"Creator:";
    if (group.image.length > 0) {
        [self.photo sd_setImageWithURL:[NSURL URLWithString:group.image]];
    } else {
        [self.photo setImage:[UIImage imageNamed:@"gl-community-icon"]];
    }
    ForumCategory *category = [Forum categoryFromGroup:group];
    self.photoBg.backgroundColor = category
        ? [UIColor colorFromWebHexValue:category.backgroundColor]
        : GLOW_COLOR_PURPLE;
}

- (void)setCellAccessory:(ForumGroupCellAccessoryType)type
{
    self.type = type;
   
    [self.joinButton setSelected:NO];
    self.photoBg.hidden = NO;
    self.joinButton.hidden = NO;
    self.joinedLabel.hidden = NO;
    self.creatorLabel.hidden = NO;
    self.membersLabel.hidden = NO;
    
    switch (type) {
        case ForumGroupCellAccessoryTypeThin:
            self.photoBg.hidden = YES;
            self.joinButton.hidden = YES;
            self.joinedLabel.hidden = YES;
            self.creatorLabel.hidden = YES;
            self.membersLabel.hidden = YES;
            break;
        case ForumGroupCellAccessoryTypeJoinable:
            self.joinButton.hidden = NO;
            [self.joinButton setTitle:@"Join" forState:UIControlStateNormal];
            [self.joinButton setTitle:@"Join" forState:UIControlStateDisabled];
            [self.joinButton setTitle:@"Join" forState:UIControlStateSelected];
            [self.joinButton setTitle:@"Join" forState:
                UIControlStateHighlighted];
            self.joinButton.enabled = YES;
            self.joinedLabel.hidden = YES;
            break;
        case ForumGroupCellAccessoryTypeMyGroup:
            self.joinButton.hidden = NO;
            [self.joinButton setTitle:@"Go" forState:UIControlStateNormal];
            [self.joinButton setTitle:@"Go" forState:UIControlStateDisabled];
            [self.joinButton setTitle:@"Go" forState:UIControlStateSelected];
            [self.joinButton setTitle:@"Go" forState:
                UIControlStateHighlighted];
            self.joinButton.enabled = NO;
            self.joinedLabel.hidden = YES;
            break;
        case ForumGroupCellAccessoryTypeJoined:
            self.joinButton.hidden = YES;
            self.joinButton.enabled = NO;
            self.joinedLabel.hidden = NO;
            break;
        default:
            break;
    }
}

- (IBAction)joinButtonClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:
        @selector(clickJoinButton:)]) {
        [self.delegate clickJoinButton:self];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [UIView animateWithDuration:animated ? 0.2 : 0 animations:^(){
        if (editing) {
            self.joinButton.hidden = YES;
            self.nameTrailingSpace.constant = 10.0;
        }
        else {
            [self setCellAccessory:self.type];
            self.nameTrailingSpace.constant = 77.0;
        }
        [self.contentView layoutIfNeeded];
    }];
}
@end

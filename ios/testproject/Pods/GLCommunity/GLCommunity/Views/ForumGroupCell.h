//
//  ForumMenuCell.h
//  emma
//
//  Created by Allen Hsu on 1/29/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumGroup.h"

#define CELL_ID_GROUP_ROW @"CELL_ID_GROUP_ROW"
#define CELL_H_GROUP 95 

typedef enum {
    ForumGroupCellAccessoryTypeMyGroup,
    ForumGroupCellAccessoryTypeJoinable,
    ForumGroupCellAccessoryTypeJoined,
    ForumGroupCellAccessoryTypeLeave,
    ForumGroupCellAccessoryTypeThin,
    ForumGroupCellAccessoryTypeNone
} ForumGroupCellAccessoryType;

@class ForumGroupCell;
@protocol ForumGroupCellDelegate <NSObject>

- (void)clickJoinButton:(ForumGroupCell *)cell;

@end

@interface ForumGroupCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (strong, nonatomic) UIColor *categoryColor;
@property (weak, nonatomic) IBOutlet UIView *photoBg;
@property (weak, nonatomic) IBOutlet UIImageView *photo;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *membersLabel;
@property (weak, nonatomic) IBOutlet UILabel *creatorLabel;
@property (weak, nonatomic) IBOutlet UIButton *joinButton;
@property (weak, nonatomic) IBOutlet UILabel *joinedLabel;
@property (weak, nonatomic) IBOutlet UIView *overlay;
@property (weak, nonatomic) id<ForumGroupCellDelegate> delegate;
@property (nonatomic) ForumGroupCellAccessoryType type;

- (void)setGroup:(ForumGroup *)group;
- (void)setCellAccessory:(ForumGroupCellAccessoryType)type;

@end

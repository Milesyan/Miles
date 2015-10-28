//
//  PollItemCell.h
//  emma
//
//  Created by Jirong Wang on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumTopic.h"

@interface PollItemCell : UITableViewCell

- (void)setModel:(ForumTopic *)model;
+ (CGFloat)getCellHeightByTopic:(ForumTopic *)model;

@end

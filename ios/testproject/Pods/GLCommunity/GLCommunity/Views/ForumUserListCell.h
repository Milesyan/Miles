//
//  ForumUserListCell.h
//  Pods
//
//  Created by Peng Gu on 5/28/15.
//
//

#import <UIKit/UIKit.h>

@class ForumUser;

@interface ForumUserListCell : UITableViewCell

- (void)configureWithUser:(ForumUser *)user;

@end

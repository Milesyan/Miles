//
//  ForumUserListViewController.h
//  Pods
//
//  Created by Peng Gu on 5/28/15.
//
//

#import <UIKit/UIKit.h>

@class ForumUser;

typedef NS_ENUM(NSUInteger, SocialRelationType) {
    SocialRelationTypeNone,
    SocialRelationTypeFollowers,
    SocialRelationTypeFollowings
};

@interface ForumSocialUsersViewController : UITableViewController

@property (nonatomic, assign) BOOL showCloseButton;

- (instancetype)initWithUser:(ForumUser *)user
              socialRelation:(SocialRelationType)relation;

@end

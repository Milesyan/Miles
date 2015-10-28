//
//  ForumEditProfileViewController.h
//  Pods
//
//  Created by Peng Gu on 4/22/15.
//
//

#import <UIKit/UIKit.h>

#define kForumEditProfileViewControllerDidUpdateProfileInfo @"kForumEditProfileViewControllerDidUpdateProfile"

@class ForumUser;

@interface ForumEditProfileViewController : UITableViewController

- (instancetype)initWithUser:(ForumUser *)user;


@end

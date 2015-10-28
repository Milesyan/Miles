//
//  ForumProfileGroupsViewController.h
//  Pods
//
//  Created by Eric Xu on 5/28/15.
//
//

#import <UIKit/UIKit.h>

@class ForumUser;

@interface ForumProfileGroupsViewController : UITableViewController

@property (strong, nonatomic) NSArray *subscribed;

- (instancetype)initWithUser:(ForumUser *)user;

@end

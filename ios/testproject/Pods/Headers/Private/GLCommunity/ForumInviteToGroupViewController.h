//
//  ForumInviteToGroupViewController.h
//  Pods
//
//  Created by Peng Gu on 4/22/15.
//
//

#import <UIKit/UIKit.h>

@class ForumUser;
@class ForumGroup;

@interface ForumInviteToGroupViewController : UIViewController

+ (void)presentForUser:(ForumUser *)user group:(ForumGroup *)group;
- (instancetype)initWithUser:(ForumUser *)user group:(ForumGroup *)group;
- (void)present;

@end

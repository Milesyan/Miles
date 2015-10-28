//
//  ForumAddURLViewController.h
//  Pods
//
//  Created by Eric Xu on 4/22/15.
//
//

#import <UIKit/UIKit.h>
#import "Forum.h"
#import "ForumTopic.h"

@interface ForumAddURLViewController : UIViewController

@property (strong, nonatomic) ForumGroup *group;
@property (strong, nonnull) ForumTopic *topic;

+ (id)viewController;

@end

//
//  ForumAddPollViewController.h
//  emma
//
//  Created by Jirong Wang on 5/12/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Forum.h"

@interface ForumAddPollViewController : UIViewController

@property (strong, nonatomic) ForumGroup *group;
@property (strong, nonatomic) ForumTopic *topic;

+ (id)viewController;

@end

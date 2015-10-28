//
//  ForumGroupsViewController.h
//  emma
//
//  Created by Jirong Wang on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumCategory.h"

@interface ForumGroupsViewController : UIViewController

@property (nonatomic) BOOL isMyGroups;
@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

+ (ForumGroupsViewController *)viewController;

@end

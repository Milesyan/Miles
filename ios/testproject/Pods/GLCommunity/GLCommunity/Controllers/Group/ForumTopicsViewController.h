//
//  ForumTopicsViewController.h
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLFoundation/GLNavigationController.h>
#import "Forum.h"

@interface ForumTopicsViewController : UITableViewController <GLNavigationControllerDelegate>

//@property (assign, nonatomic) ForumCategoryType type;
//@property (assign, nonatomic) ForumCategoryType targetType;
@property (strong, nonatomic) ForumCategory *category;
@property (strong, nonatomic) ForumGroup *group;
@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

@property (nonatomic) BOOL showGroupInfo;

+ (id)viewController;

- (IBAction)refreshData:(id)sender;
+ (ForumTopicsViewController *)pushableControllerBy:(ForumGroup *)group;

@end

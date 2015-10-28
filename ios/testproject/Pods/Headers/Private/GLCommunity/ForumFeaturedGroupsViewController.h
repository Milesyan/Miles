//
//  ForumFeaturedGroupsViewController.h
//  emma
//
//  Created by Jirong Wang on 8/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForumFeaturedGroupsViewController : UITableViewController

@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

- (void)setup;

@end

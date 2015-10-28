//
//  ForumMyGroupsViewController.h
//  emma
//
//  Created by Jirong Wang on 8/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define MENU_CELL_BG_ODD UIColorFromRGB(0xfbfaf6)
#define MENU_CELL_BG_EVEN UIColorFromRGB(0xf6f5f0)

@interface ForumMyGroupsViewController : UITableViewController

@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

- (void)setup;

@end

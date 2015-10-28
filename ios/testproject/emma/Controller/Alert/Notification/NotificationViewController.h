//
//  NotificationViewController.h
//  emma
//
//  Created by Ryan Ye on 3/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "GeniusChildViewController.h"

@class User;

@interface NotificationViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
+ (id)getInstance;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, retain)User *model;

@end

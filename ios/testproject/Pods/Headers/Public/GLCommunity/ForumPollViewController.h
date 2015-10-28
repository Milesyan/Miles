//
//  ForumPollViewController.h
//  emma
//
//  Created by Jirong Wang on 5/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumPollOptions.h"

@interface ForumPollViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) BOOL isOnHomePage;

- (void)setModel:(ForumPollOptions *)pullOptions;
- (void)refresh;

@end

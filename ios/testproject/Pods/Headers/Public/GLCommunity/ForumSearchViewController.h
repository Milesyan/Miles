//
//  ForumSearchViewController.h
//  emma
//
//  Created by Jirong Wang on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ForumSearchViewController : UIViewController

@property (assign, nonatomic) BOOL shouldToggleNavigationBar;

- (void)toggleSearchBar;
- (BOOL)isInSearchMode;

@end

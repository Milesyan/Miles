//
//  ForumTutorialViewController.h
//  emma
//
//  Created by Allen Hsu on 2/19/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define KEY_COMPLETED_FORUM_TUTORIAL    @"emma_completed_forum_tutorial"

@interface ForumTutorialViewController : UIViewController

- (void)start;
+ (BOOL)hasCompletedForumTutorial;
+ (void)setCompletedForumTutorial:(BOOL)completed;

@end

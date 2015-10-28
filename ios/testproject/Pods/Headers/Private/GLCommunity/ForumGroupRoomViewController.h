//
//  ForumGroupRoomViewController.h
//  emma
//
//  Created by Jirong Wang on 8/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumCategory.h"
#import "ForumGroup.h"

@interface ForumGroupRoomViewController : UIViewController

@property (strong, nonatomic) ForumCategory *category;
//@property (nonatomic) ForumCategoryType bookmarkType;
@property (strong, nonatomic) ForumGroup *group;
@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

+ (id)viewController;
- (void)refresh;

@end

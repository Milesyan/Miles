//
//  ForumAddPhotoViewController.h
//  emma
//
//  Created by Allen Hsu on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumGroup.h"
#import "ForumTopic.h"

@interface ForumAddPhotoViewController : UITableViewController

@property (strong, nonatomic) ForumGroup *group;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) ForumTopic *topic;

+ (id)viewController;

@end

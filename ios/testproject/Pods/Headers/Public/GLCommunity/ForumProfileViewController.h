//
//  ForumProfileViewController.h
//  emma
//
//  Created by Allen Hsu on 1/2/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumUser.h"

@interface ForumProfileViewController : UIViewController

- (instancetype)initWithUserID:(uint64_t)userid placeholderUser:(ForumUser *)user;

@end

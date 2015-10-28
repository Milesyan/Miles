//
//  ForumCommentViewController.h
//  emma
//
//  Created by Allen Hsu on 12/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumReply.h"
#import "ForumTopic.h"
#import "ForumCategory.h"

@interface ForumCommentViewController : UIViewController

@property (nonatomic, strong) ForumCategory *category;
@property (nonatomic, strong) ForumReply *reply;
@property (nonatomic, strong) ForumTopic *topic;
@property (nonatomic, assign) BOOL beginEditWhenAppear;

+ (id)viewController;

@end

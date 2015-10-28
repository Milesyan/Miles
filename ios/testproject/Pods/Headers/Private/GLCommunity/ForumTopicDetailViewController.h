//
//  ForumTopicDetailViewController.h
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Forum.h"
#import "ForumReplyCell.h"

@interface ForumTopicDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIWebViewDelegate, ForumReplyCellDelegate, UIActionSheetDelegate, UIAlertViewDelegate>
@property (copy, nonatomic) NSString *source;
@property (strong, nonatomic) ForumTopic *topic;
@property (strong, nonatomic) ForumCategory *category;
@property (assign, nonatomic) uint64_t articleId;

@property (assign, nonatomic) uint64_t replyId;
@property (assign, nonatomic) BOOL shouldShowReportButton;
@property (assign, nonatomic) BOOL hideComments;

@property (weak, nonatomic) id <UIScrollViewDelegate> scrollDelegate;

+ (id)viewController;

@end

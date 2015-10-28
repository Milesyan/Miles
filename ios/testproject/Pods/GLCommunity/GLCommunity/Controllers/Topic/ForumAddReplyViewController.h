//
//  ForumAddReplyViewController.h
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLFoundation/GLTextView.h>
#import "ForumTopic.h"

@interface ForumAddReplyViewController : UIViewController <UITextViewDelegate, UIActionSheetDelegate, GLTextViewDelegate>

@property (strong, nonatomic) ForumTopic *topic;

+ (id)viewController;

@end

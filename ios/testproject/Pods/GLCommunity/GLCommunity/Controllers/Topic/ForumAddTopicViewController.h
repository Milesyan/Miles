//
//  ForumAddTopicViewController.h
//  emma
//
//  Created by Allen Hsu on 11/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLFoundation/GLTextView.h>
#import "Forum.h"

@interface ForumAddTopicViewController : UIViewController <UITextViewDelegate, UIActionSheetDelegate, UITextFieldDelegate, GLTextViewDelegate>

@property (strong, nonatomic) ForumGroup *group;
@property (strong, nonatomic) ForumTopic *topic;

+ (id)viewController;

@end

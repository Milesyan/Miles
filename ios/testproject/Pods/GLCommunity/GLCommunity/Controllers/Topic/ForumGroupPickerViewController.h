//
//  ForumGroupPickerViewController.h
//  emma
//
//  Created by Allen Hsu on 8/26/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumGroup.h"

@class ForumGroupPickerViewController;

@protocol ForumGroupPickerDelegate <NSObject>

- (void)groupPicker:(ForumGroupPickerViewController *)picker didPickGroup:(ForumGroup *)group;

@end

@interface ForumGroupPickerViewController : UITableViewController

@property (weak, nonatomic) id <ForumGroupPickerDelegate> delegate;
@property (assign, nonatomic) BOOL enabled;

+ (id)viewController;

@end

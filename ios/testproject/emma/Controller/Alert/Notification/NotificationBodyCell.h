//
//  NotificationBodyCell.h
//  emma
//
//  Created by Ryan Ye on 3/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Notification.h"
#import "NotificationViewController.h"
#import <MessageUI/MessageUI.h>

@interface NotificationBodyCell : UITableViewCell<MFMessageComposeViewControllerDelegate>
@property (nonatomic, strong) Notification *model;
@property (nonatomic) BOOL thumbMode;
@property (nonatomic, weak) NotificationViewController *controller;

- (void)hideDividerLine;
- (void)showDividerLine;
+ (CGFloat)rowHeight:(Notification*)notif;
@end

//
//  InvitePartnerDialog.h
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "PushableDialog.h"

#define EVENT_INVITE_PARTNER_CANCELLED @"event_invite_partner_cancelled"
#define EVENT_PARTNER_NOT_FOUND @"event_partner_not_found"
#define EVENT_INVITE_PARTNER_DIALOG_DISMISS @"event_invite_partner_fb_dialog_dismiss"

@interface InvitePartnerDialog : UIViewController <UIAlertViewDelegate, PushableDialog>
- (id)initWithUser:(User *)user;
- (void)present;

+ (void)openDialog;

@end

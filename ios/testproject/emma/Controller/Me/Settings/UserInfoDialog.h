//
//  UserInfoDialog.h
//  emma
//
//  Created by Ryan Ye on 8/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "User.h"

@interface UserInfoDialog : UIViewController
- (id)initWithUser:(User *)user;
- (void)present;
@end

//
//  ExportReportDialog.h
//  emma
//
//  Created by Eric Xu on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"

@interface ExportReportDialog : UIViewController

- (id)initWithUser:(User *)user;
- (void)present;
@end

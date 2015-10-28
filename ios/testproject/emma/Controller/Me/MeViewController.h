//
//  MeViewController.h
//  emma
//
//  Created by Eric Xu on 10/23/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PersistentBackgroundLabel : UILabel
- (void)setPersistentBackgroundColor:(UIColor *)color;
@end

@interface MeViewController : UITableViewController
- (void)goToGlowFirstPage;
@end

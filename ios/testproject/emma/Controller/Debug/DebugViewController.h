//
//  DebugViewController.h
//  emma
//
//  Created by ltebean on 15-5-8.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TabbarController.h"

@interface DebugViewController : UITableViewController
@property (nonatomic, weak) TabbarController *tabbarVC;
+ (instancetype)instance;
@end

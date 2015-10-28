//
//  MedListViewController.h
//  emma
//
//  Created by Peng Gu on 1/7/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MedManager;

@interface MedListViewController : UITableViewController

@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) MedManager *medManager;

@end

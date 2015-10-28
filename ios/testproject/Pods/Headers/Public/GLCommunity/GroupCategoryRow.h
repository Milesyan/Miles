//
//  GroupCategoryRow.h
//  emma
//
//  Created by Xin Zhao on 7/31/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CELL_ID_GROUP_CATEGORY @"CELL_ID_GROUP_CATEGORY"
#define CELL_H_GROUP_CATEGORY 44

@interface GroupCategoryRow : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIView *colorCircle;

- (void)setupWithColor:(UIColor *)color name:(NSString *)name;

@end

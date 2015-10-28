//
//  CustomizationCell.h
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CustomizationCell;

@protocol CustomizationCellDelegate <NSObject>
- (void)custmozationCellDidClick:(CustomizationCell *)cell;
@end

@interface CustomizationCell : UITableViewCell
@property (nonatomic, weak) id<CustomizationCellDelegate> delegate;
@end

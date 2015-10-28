//
//  RatingCell.h
//  emma
//
//  Created by ltebean on 15-5-6.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RatingCell;

@protocol RatingCellDelegate <NSObject>
- (void)ratingCellNeedsDismiss:(RatingCell *)ratingCell;
@end

@interface RatingCell : UITableViewCell
@property (nonatomic, weak) id<RatingCellDelegate> delegate;
@property (nonatomic, weak) UIViewController *viewController;

+ (BOOL)needsShow;
+ (void)logLaunch;
@end

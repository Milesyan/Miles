//
//  startLoggingCell.h
//  emma
//
//  Created by Xin Zhao on 13-5-22.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UserDailyData;

@protocol StartLoggingCellDelegate <NSObject>

- (void)tableViewCellNeedsUpdateHeight:(UITableViewCell *)cell;
- (void)tableViewCell:(UITableViewCell *)cell needsPerformSegue:(NSString *)segueIdentifier;

@end


@interface StartLoggingCell : UITableViewCell

@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) UserDailyData *dailyData;
@property (nonatomic, weak) id<StartLoggingCellDelegate> delegate;

@property (nonatomic, assign) CGFloat heightThatFits;

- (void)setupWeekLogColors;
- (void)updateInsights:(NSString *)date;
- (void)popupInsights;

@end

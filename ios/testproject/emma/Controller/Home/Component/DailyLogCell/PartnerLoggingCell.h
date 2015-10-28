//
//  PartnerLoggingCell.h
//  emma
//
//  Created by ltebean on 15-3-19.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserDailyData.h"
@protocol PartnerLoggingCellDelegate <NSObject>
- (void)tableViewCellNeedsUpdateHeight:(UITableViewCell *)cell;
@end

@interface PartnerLoggingCell : UITableViewCell
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) id<PartnerLoggingCellDelegate> delegate;
- (CGFloat)heightThatFits;
@end

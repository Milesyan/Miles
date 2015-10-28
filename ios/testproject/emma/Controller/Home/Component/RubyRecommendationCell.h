//
//  RubyRecommendationCell.h
//  emma
//
//  Created by ltebean on 15/7/30.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RubyRecommendationCell;

@protocol RubyRecommendationCellDelegate <NSObject>
- (void)rubyRecommendationCellNeedsDismiss:(RubyRecommendationCell *)cell;
@end

@interface RubyRecommendationCell : UITableViewCell
@property (nonatomic, weak) id<RubyRecommendationCellDelegate> delegate;
+ (BOOL)needsShow;
+ (CGFloat)height;
@end

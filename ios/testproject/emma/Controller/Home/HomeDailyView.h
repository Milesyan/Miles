//
//  DaySummaryView.h
//  emma
//
//  Created by ltebean on 14-12-18.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StartLoggingCell.h"
#import "GLDynamicContentScrollView.h"

@class HomeDailyView;

@protocol HomeDailyViewDelegate <NSObject>
- (void)homeDailyView:(HomeDailyView *)homeDailyView needsUpdateHeightTo:(CGFloat)height;
- (void)homeDailyView:(HomeDailyView *)homeDailyView needsPerformSegueWithIdentifier:(NSString *) identifier;
@end

@interface HomeDailyView : UIView
@property (nonatomic, strong) NSDate *selectedDate; // the view will refresh once you set the date
@property (nonatomic, weak) id<HomeDailyViewDelegate> delegate;
@property (nonatomic, weak) UIViewController *homeViewController;
@property (nonatomic, weak) GLDynamicContentScrollView *parentScrollView;

- (StartLoggingCell *) startLoggingCell;
- (CGFloat)contentHeight;
- (void)showTriangleViewWithAnimation:(BOOL)animated;
- (void)hideTriangleViewWithAnimation:(BOOL)animated;
- (void)updateTriangleViewTranslationY:(CGFloat)top;
- (void)reloadTableView;
- (void)reloadLogSummary;
- (void)reloadDailyArticle;
- (void)reloadDailyTodo;
@end

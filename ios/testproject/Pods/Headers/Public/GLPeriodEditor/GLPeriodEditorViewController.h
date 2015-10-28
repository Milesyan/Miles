//
//  GLPeriodEditorViewController.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLFoundation/GLSlidingViewController.h>
#import "GLCycleData.h"
#import "GLPeriodEditorHeader.h"
#import "GLPeriodEditorNavigationViewController.h"

typedef NS_ENUM(NSInteger, MODE) {
    MODE_NORMAL = 0,
    MODE_EDITING = 1,
};

@class GLPeriodEditorViewController;

@protocol GLPeriodEditorDataSource <NSObject>
- (NSMutableArray *)initialDataForPeriodEditor:(GLPeriodEditorViewController *)editor;
@end

@protocol GLPeriodEditorDelegate <NSObject>
// call [GLPeriodEditorTipsPopup presentWithURL:@"http://glowing.com/term/period_editor_tips"];
- (void)editorDidClickInfoIcon:(GLPeriodEditorViewController *)editor;
- (void)editor:(GLPeriodEditorViewController *)editor didUpdateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate;
- (void)editor:(GLPeriodEditorViewController *)editor didAddCycleData:(GLCycleData *)cycleData;
- (void)editor:(GLPeriodEditorViewController *)editor didRemoveCycleData:(GLCycleData *)cycleData;
- (void)editor:(GLPeriodEditorViewController *)editor didReceiveLoggingEvent:(LOGGING_EVENT)event data:(id)data;
- (NSDate *)selectedDate;
@end

@interface GLPeriodEditorViewController : GLSlidingViewController
@property (nonatomic, weak) id<GLPeriodEditorDataSource> dataSource;
@property (nonatomic, weak) id<GLPeriodEditorDelegate> delegate;
@property (nonatomic) BOOL scrollEnabled;
@property (nonatomic) BOOL hideBottomBar;
@property (nonatomic, copy) NSDate *firstDate;
@property (nonatomic, copy) NSDate *lastDate;
@property (nonatomic) UIStatusBarStyle statusBarStyle;
@property (weak, nonatomic) IBOutlet UIButton *leftNavButton;
@property (weak, nonatomic) IBOutlet UIButton *rightNavButton;
@property (nonatomic, strong) NSMutableArray *cycleDataList;
@property (nonatomic) MODE mode;

+ (GLPeriodEditorNavigationViewController *)instance;
+ (GLPeriodEditorNavigationViewController *)instanceOfSubClass:(NSString *)classString;
- (IBAction)leftNavButtonPressed:(UIButton *)sender;
- (IBAction)rightNavButtonPressed:(UIButton *)sender;
- (void)showSegmentedControlTitle;
- (void)showLabelTitleWithText:(NSString *)text;

- (void)reloadData;
// method to overide in subclass
- (NSMutableArray *)initialData;
- (void)didUpdateCycleData:(GLCycleData *)cycleData withPeriodBeginDate:(NSDate *)periodBeginDate periodEndDate:(NSDate *)periodEndDate;
- (void)didAddCycleData:(GLCycleData *)cycleData;
- (void)didRemoveCycleData:(GLCycleData *)cycleData;
// show some alerts in these methods
- (void)didClickInfoIcon;
- (void)didWantToAddCycleNearExistingOne;
- (void)didWantToAddCycleInFuture;
- (void)didWantToDeleteTheLatestCycle;
- (void)didWantToUpdateBeginDateToFutuerDays;
// logging event
- (void)didReceiveLoggingEvent:(LOGGING_EVENT)event data:(id)data;
@end

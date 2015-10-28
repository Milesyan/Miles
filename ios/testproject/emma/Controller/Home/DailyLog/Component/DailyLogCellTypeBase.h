//
//  DailyLogCellTypeBase.h
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UILinkLabel.h"

#define LOG_VAL_POSITIVE 1
#define LOG_VAL_NEGATIVE 2
#define LOG_VAL_MEDIUM 3

#define WIDTH_DIFF_WITH_2_BUTTON (IS_IPHONE_6_PLUS ? 45 : (IS_IPHONE_6 ? 24 : 0))
#define WIDTH_DIFF_WITH_3_BUTTON (IS_IPHONE_6_PLUS ? 30 : (IS_IPHONE_6 ? 16 : 0))
#define WIDTH_DIFF_WITH_4_BUTTON (IS_IPHONE_6_PLUS ? 22 : (IS_IPHONE_6 ? 12 : 0))

@class DailyLogCellTypeBase;
@protocol DailyLogCellDelegate <NSObject>
- (void)scrollToBottom;
- (void)refreshLayout;
- (void)updateDailyData:(NSString *) key withValue:(id)val;
- (void)findAndResignFirstResponder;
- (NSInteger)fromMfpFlag;
- (void)setCell:(DailyLogCellTypeBase *)cell visible:(BOOL)isVisibile;
@optional
- (void)updateMed:(NSString *)medName withValue:(id)val;
@end

@interface DailyLogCellTypeBase : UITableViewCell {
    UIView *buttonsContainer;
    NSArray *exclusiveButtons;
}

@property (nonatomic, strong) NSString *dataKey;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) id<DailyLogCellDelegate> delegate;
@property (nonatomic, strong) IBOutlet UILinkLabel *label;
@property (nonatomic, strong) UISwitch *hideSwitch;

- (void)setup;
- (void)configWithTemplate:(NSDictionary *)template;
- (void)setValue:(NSObject*)value forDate:(NSDate *)date;
- (void)logButton:(NSString *)eventName clickType:(NSString *)clickType eventData:(NSDictionary *)eventData;
- (NSString *)getClickType:(UIButton *)btn yesBtnTag:(NSUInteger)tag;
- (IBAction)buttonTouched:(id)sender;
- (void)updateData;
- (IBAction)onSwitched:(id)sender;
- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)height;
- (void)exitEditing;

@end

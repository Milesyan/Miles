//
//  DateButton.h
//  emma
//
//  Created by Peng Gu on 11/4/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//


#import <UIKit/UIKit.h>


#define DEFAULT_CELL_WIDTH (IS_IPHONE_6_PLUS ? 44.0f : (IS_IPHONE_6 ? 40.0f : 35.0f))
#define CELL_BORDER_WIDTH (IS_IPHONE_6_PLUS ? 6.5f : (IS_IPHONE_6 ? 6.0f : 5.0f))


@interface DateButton : UILabel

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSCalendar *calendar;
@property (nonatomic, strong) NSDateFormatter *formatter;
@property (nonatomic, assign) BOOL hasMedication;
@property (nonatomic, assign) BOOL hasAppointment;
@property (nonatomic, assign) BOOL hasSex;
@property (nonatomic, assign) BOOL hasLog;

- (void)addIcon:(UIImage *)image;
- (void)updateIcons;
- (void)clearIcons;

@end


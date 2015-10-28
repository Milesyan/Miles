//
//  GLPeriodEditorHeader.h
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <GLFoundation/UIView+Helpers.h>
#import <GLFoundation/NSObject+PubSub.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define GLOW_COLOR_PURPLE UIColorFromRGB(0x5a62d2)
#define GLOW_COLOR_LIGHT_PURPLE UIColorFromRGB(0xabaae3)
#define GLOW_COLOR_PURPLE UIColorFromRGB(0x5a62d2)
#define GLOW_COLOR_GREEN UIColorFromRGB(0x73bd37)
#define GLOW_COLOR_PINK UIColorFromRGB(0xea7ba3)
#define GLOW_COLOR_CYAN UIColorFromRGB(0x1BCCA4)
#define GLOW_COLOR_FUTURE_DAY UIColorFromRGB(0xa6a6a6)

#define EVENT_PERIOD_EDITOR_CALENDAR_VIEW_NEEDS_RELOAD @"event_period_editor_calendar_view_needs_reload"
#define EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD @"event_period_editor_table_view_needs_reload"
#define EVENT_PERIOD_EDITOR_INDICATE_CAN_RELOAD_DATA @"event_period_editor_indicate_can_reload_data"

typedef NS_ENUM(NSInteger, LOGGING_EVENT) {
    BTN_CLK_BACK,
    BTN_CLK_TIPS,
    BTN_CLK_VIEW_LIST_VIEW,
    BTN_CLK_VIEW_CAL_VIEW,
    BTN_CLK_CAL_VIEW_PERIOD_DEL,
    BTN_CLK_CAL_VIEW_PERIOD_DEL_CONFIRM,
    BTN_CLK_CAL_VIEW_PERIOD_ADD_CONFIRM,
    BTN_CLK_CAL_VIEW_PERIOD_SAVE,
    BTN_CLK_CAL_VIEW_PERIOD_IS_LATE,
    BTN_CLK_CAL_VIEW_PERIOD_STARTED_TODAY,
    BTN_CLK_LIST_VIEW_PERIOD_DEL
};


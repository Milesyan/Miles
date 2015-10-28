//
//  DailyLogViewController.h
//  emma
//
//  Created by Ryan Ye on 3/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogCellTypeBase.h"
#import "MedicineViewController.h"

#define LOG_VAL_INTERCOURSE_ON_BOTTOM 0x100
#define LOG_VAL_INTERCOURSE_BENT_OVER 0x200
#define LOG_VAL_INTERCOURSE_ON_TOP 0x400
#define LOG_VAL_INTERCOURSE_OTHER 0x800

#define LOG_VAL_MOOD_SAD 0x10
#define LOG_VAL_MOOD_MOODY 0x20
#define LOG_VAL_MOOD_STRESSED 0x40
#define LOG_VAL_MOOD_ANGRY 0x80
#define LOG_VAL_MOOD_ANXIOUS 0x100
#define LOG_VAL_MOOD_OTHER 0x200

typedef enum {
    dailyLogCellSaveSuccessful = 0,
    dailyLogCellSaveInvalidPb,
    dailyLogCellSaveInvalidPe,
}DailyLogCellSaveResult;

@interface DailyLogViewController : UIViewController<DailyLogCellDelegate, UIActionSheetDelegate, MedicineViewControllerDelegate>

@property(nonatomic, strong) NSDate *selectedDate;
@property(nonatomic) BOOL hasChanges;

@property (nonatomic, assign) BOOL needsToScrollToWeightCell;

@end

//
//  DailyLogCellTypeExpandable.h
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogCellTypeBase.h"
#import "PillButton.h"

@interface DailyLogCellTypeExpandable : DailyLogCellTypeBase {
    IBOutlet PillButton *button1;
    IBOutlet PillButton *button2;
}

@property (nonatomic, strong) NSArray *expandedButtons;
@property (nonatomic) BOOL exclusive;
- (IBAction)expandedButtonTouched: (id)sender;
@end

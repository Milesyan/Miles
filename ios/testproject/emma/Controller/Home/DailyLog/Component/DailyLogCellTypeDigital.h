//
//  DailyLogCellTypeDigital.h
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogCellTypeBase.h"
#import "PillButton.h"


@interface DailyLogCellTypeDigital : DailyLogCellTypeBase


//@property IBOutlet UILabel *unitLabel;
@property (nonatomic, strong) IBOutlet PillButton *digitalButton;
@property (nonatomic, strong) IBOutlet UIButton *inc;
@property (nonatomic, strong) IBOutlet UIButton *dec;
@property (strong, nonatomic) IBOutlet PillButton *unitButton;

- (void)openTemperaturePanel;

@end

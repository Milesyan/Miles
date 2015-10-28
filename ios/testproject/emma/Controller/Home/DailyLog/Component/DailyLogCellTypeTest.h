//
//  DailyLogCellTypeTest.h
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyLogCellTypeBase.h"
#import <GLFoundation/GLPillButton.h>

@interface DailyLogCellTypeTest : DailyLogCellTypeBase {
    IBOutlet GLPillButton *button1;
    IBOutlet GLPillButton *button2;
    IBOutlet GLPillButton *button3;
    IBOutlet GLPillButton *brandButton;
}


- (IBAction)brandTouched:(id)sender;

@end

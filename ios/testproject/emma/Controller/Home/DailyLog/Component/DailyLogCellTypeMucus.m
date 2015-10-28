//
//  DailyLogCellTypeMucus.m
//  emma
//
//  Created by Ryan Ye on 4/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogConstants.h"
#import "DailyLogCellTypeMucus.h"
#import "PillButton.h"
#import "Logging.h"
#import "UILinkLabel.h"
#import "Tooltip.h"

@interface DailyLogCellTypeMucus()  {
    IBOutlet PillButton *yesBtn;
    IBOutlet PillButton *noBtn;
    IBOutlet UILinkLabel *CMCheckLabel;
    IBOutlet UILinkLabel *wetnessLabel;
    IBOutlet UILinkLabel *textureLabel;

    IBOutletCollection(PillButton) NSArray *textureButtons;

    IBOutletCollection(PillButton) NSArray *wetnessButtons;
    
    __weak IBOutlet PillButton *textureNotSelectedButton;
    
    __weak IBOutlet PillButton *amountNotSelectedButton;
    
    IBOutletCollection(PillButton) NSArray * threeButtonsInLine;
    IBOutletCollection(PillButton) NSArray * twoButtonsInLine;
}
@end

@implementation DailyLogCellTypeMucus

- (void)awakeFromNib {
    // need set tags for textureButtons and wetnessButtons
    
    exclusiveButtons = @[yesBtn, noBtn];
    
    if (WIDTH_DIFF_WITH_2_BUTTON > 0) {
        // two buttons in line
        for (UIView * v in twoButtonsInLine) {
            v.aWidth = v.aWidth + WIDTH_DIFF_WITH_2_BUTTON;
        }
        for (UIView * v in threeButtonsInLine) {
            v.aWidth = v.aWidth + WIDTH_DIFF_WITH_3_BUTTON;
        }
    }
}

- (void)setup {

}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    int val = [(NSNumber *)value intValue];
    yesBtn.selected = val >= DAILY_LOG_VAL_YES;
    noBtn.selected = (val == DAILY_LOG_VAL_NO);
    if (val >= DAILY_LOG_VAL_YES) {
        [self setTexture:(val & 0xff)];
        [self setWetness:((val >> 8) & 0xff)];
    }
    self.dataValue = value;
    
    if (DETECT_TIPS) {
        textureLabel.userInteractionEnabled = YES;
        textureLabel.lineBreakMode = NSLineBreakByWordWrapping;
        wetnessLabel.userInteractionEnabled = YES;
        wetnessLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        [textureLabel clearCallbacks];
        [wetnessLabel clearCallbacks];

        for (NSString *kw in [Tooltip keywords]) {
            [textureLabel setCallback:^(NSString *str) {
                [Tooltip tip:str];
            }
                           forKeyword:kw];
            [wetnessLabel setCallback:^(NSString *str) {
                [Tooltip tip:str];
            }
                           forKeyword:kw];
            
        }
    }
}

- (void)setTexture:(int)val {
    if (val <= CM_TEXTURE_NO) {
        val = CM_TEXTURE_NO;
    } else if (val <= CM_TEXTURE_STICKY - 5) {
        val = CM_TEXTURE_DRY;
    } else if (val <= CM_TEXTURE_WATERY - 5) {
        val = CM_TEXTURE_STICKY;
    } else if (val <= CM_TEXTURE_EGGWHITE - 5) {
        val = CM_TEXTURE_WATERY;
    } else if (val <= CM_TEXTURE_CREAMY - 5) {
        val = CM_TEXTURE_EGGWHITE;
    } else {
        val = CM_TEXTURE_CREAMY;
    }
    for (PillButton *b in textureButtons) {
        b.selected = (b.tag == val);
    }
}

- (void)setWetness:(int)val {
    if (val <= CM_WETNESS_NO) {
        val = CM_WETNESS_NO;
    } else if (val <= 33) {
        val = CM_WETNESS_DRY;
    } else if (val <= 66) {
        val = CM_WETNESS_DAMP;
    } else {
        val = CM_WETNESS_WET;
    }
    for (PillButton *b in wetnessButtons) {
        b.selected = (b.tag == val);
    }
}

- (IBAction)buttonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    // logging first
    NSString * clickType;
    if (button == yesBtn) {
        clickType = button.selected ? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    } else {
        clickType = button.selected ? CLICK_TYPE_NO_SELECT : CLICK_TYPE_NO_UNSELECT;
    }
    [self logButton:BTN_CLK_HOME_MUCUS_CHECK clickType:clickType eventData:nil];
    GLLog(@"button touched: exclusiveButtons=%@", exclusiveButtons); 
    for (PillButton *b in exclusiveButtons) {
        if (b != button && b.selected) {
            [b toggle:YES];
        }
    }
    [self.delegate findAndResignFirstResponder];
    if (yesBtn.selected) {
        [self setTexture:CM_TEXTURE_NO];
        [self setWetness:CM_WETNESS_NO];
    }
    if (button.inAnimation) {
        [self subscribeOnce:EVENT_PILLBUTTON_ANIMATION_END obj:button selector:@selector(updateData)];
    } else {
        [self updateData];
    }
}

- (IBAction)textureButtonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    BOOL anyButtonSelected = NO;
    for (PillButton *b in textureButtons) {
        if (b != button && b.selected) {
            [b toggle:NO];
        }
        if (b.isSelected) {
            anyButtonSelected = YES;
        }
    }
    if (!anyButtonSelected) {
        [textureNotSelectedButton toggle:NO];
    }
    [self logButton:BTN_CLK_HOME_MUCUS_TEXTURE clickType:CLICK_TYPE_NONE eventData:@{@"value": @(button.tag)}];
    [self updateData];
}


- (IBAction)wetnessButtonTouched: (id)sender {
    PillButton *button = (PillButton *)sender;
    BOOL anyButtonSelected = NO;
    for (PillButton *b in wetnessButtons) {
        if (b != button && b.selected) {
            [b toggle:NO];
        }
        if (b.isSelected) {
            anyButtonSelected = YES;
        }
    }
    if (!anyButtonSelected) {
        [amountNotSelectedButton toggle:NO];
    }
    [self logButton:BTN_CLK_HOME_MUCUS_WETNESS clickType:CLICK_TYPE_NONE eventData:@{@"value": @(button.tag)}];
    [self updateData];
}

- (void)updateData {
    int val = 0;
    if (yesBtn.selected) {
        for (PillButton *texBtn in textureButtons) {
            if (texBtn.selected)
                val += texBtn.tag;
        }
        for (PillButton *wetBtn in wetnessButtons) {
            if (wetBtn.selected)
                val += (wetBtn.tag << 8);
        }
    } else if (noBtn.selected) {
        val = CM_SELECT_NO;
    }
    GLLog(@"updateData:%d", val);
    [self.delegate updateDailyData:self.dataKey withValue:@(val)];
}
@end

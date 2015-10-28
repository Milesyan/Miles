//
//  UIPairButton.m
//  emma
//
//  Created by Jirong Wang on 3/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PairButton.h"

@implementation PairButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    [self addTarget:self action:@selector(buttonToggle) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(buttonToggle) forControlEvents:UIControlEventTouchUpOutside];
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setPairButton:(PairButton *)pairButton deselect:(BOOL)deselect{
    /*
     * deselect - YES, the pair button can both in "unselect" status
     *          - NO, the pair button can not both in "unselect" status
     *            Which mean, one of the pair button is selected, the other one is unselected
     *
     * no matter YES or NO, only one button can be "selected"
     */
    self.pair = (UIButton *)pairButton;
    pairButton.pair = (UIButton *)self;
    self.deselect = deselect;
    pairButton.deselect = deselect;
    
    if (!deselect) {
        // the pair button should be in different status
        pairButton.selected = 1 - self.selected;
    } else {
        // can not both in "selected"
        if (self.selected)
            pairButton.selected = 0;
    }
}

- (void)buttonToggle {
    // we run at the first, so now button.select is not changed.
    if (self.pair == nil) {
        return;
    }
    if (!self.deselect) {
        self.pair.selected = self.selected;
    } else {
        if (!self.selected) {
            // self from unselect -> select
            self.pair.selected = 0;
        }
    }
}

@end

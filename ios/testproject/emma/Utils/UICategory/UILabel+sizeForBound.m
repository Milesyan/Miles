//
//  UILabel+sizeForBound.m
//  emma
//
//  Created by Eric Xu on 12/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "UILabel+sizeForBound.h"

@implementation UILabel (sizeForBound)

+ (CGSize)sizeForText:(NSAttributedString *)str inBound:(CGSize)bound {
    static UILabel *dummyLabel;
    if (!dummyLabel) {
        dummyLabel = [[UILabel alloc] init];
        dummyLabel.numberOfLines = 0;
        dummyLabel.lineBreakMode = NSLineBreakByWordWrapping;
    }
    dummyLabel.frame = CGRectMake(0, 0, bound.width, bound.height);
    dummyLabel.attributedText = str;
    [dummyLabel sizeToFit];
    return dummyLabel.frame.size;
    
}

- (CGSize)sizeForBound:(CGSize)bound {
    return [UILabel sizeForText:self.attributedText inBound:bound];
}
@end

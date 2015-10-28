//
//  UILabel+sizeForBound.h
//  emma
//
//  Created by Eric Xu on 12/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (sizeForBound)

+ (CGSize)sizeForText:(NSAttributedString *)str inBound:(CGSize)bound;
- (CGSize)sizeForBound:(CGSize)bound;
@end

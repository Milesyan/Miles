//
//  GLMarkdownLabel.h
//  kaylee
//
//  Created by Bob on 14-9-24.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLMarkdownLabel : UILabel

@property (nonatomic, retain) IBInspectable NSString *markdownText;
@property (nonatomic) IBInspectable BOOL underline;
@property (nonatomic) IBInspectable CGFloat markdownLineSpacing;

@end

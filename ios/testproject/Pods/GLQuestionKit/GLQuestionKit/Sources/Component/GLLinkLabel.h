//
//  GLLinkLabel.h
//  GLQuestionKit
//
//  Created by ltebean on 15/7/24.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
//#import "UILabel+AutoLink.h"
#define NSLinkAttributeName @"NSLinkAttributeName"
#define NSLinkAttributeCallback @"NSLinkAttributeCallback"

typedef void (^LinkClickedCallback)(NSString *str);

@interface GLLinkLabel : UILabel

@property (nonatomic) BOOL useUnderline;
@property (nonatomic) BOOL useHyperlinkColor;

- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw;
- (void)setCallback:(LinkClickedCallback)cb forKeyword:(NSString *)kw caseSensitive:(BOOL)caseSensitive;
- (void)clearCallbacks;
- (LinkClickedCallback)callbackForKeyword:(NSString *)kw;

@end
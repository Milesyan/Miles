//
//  GLMarkdownLabel.m
//  kaylee
//
//  Created by Bob on 14-9-24.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import "GLMarkdownLabel.h"
#import "NSString+Markdown.h"

@implementation GLMarkdownLabel

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    if (self.numberOfLines != 1 && bounds.size.width != self.preferredMaxLayoutWidth) {
        self.preferredMaxLayoutWidth = bounds.size.width;
        [self setNeedsUpdateConstraints];
    }
}

- (void)setMarkdownText:(NSString *)markdownText
{
    if (![markdownText isEqualToString:_markdownText])
    {
        _markdownText = markdownText;
        [self refresh];
    }
}

- (void)setMarkdownLineSpacing:(CGFloat)markdownLineSpacing
{
    if (_markdownLineSpacing != markdownLineSpacing)
    {
        _markdownLineSpacing = markdownLineSpacing;
        [self refresh];
    }
}
- (void)setUnderline:(BOOL)underline
{
    if (underline != _underline)
    {
        _underline = underline;
        [self refresh];
    }
}

- (void)refresh
{
    NSString *markdownText = self.markdownText.length > 0 ? self.markdownText : nil;
    NSMutableAttributedString *str;
    if (markdownText)
    {
        str = [[NSString markdownToAttributedText:markdownText fontSize:self.font.pointSize  color:self.textColor] mutableCopy];
    }
    else
    {
        str = [[[NSAttributedString alloc] initWithString:self.text] mutableCopy];
    }
    if (self.underline)
    {
        [str addAttribute:NSUnderlineStyleAttributeName value:@1 range:NSMakeRange(0, str.length)];
    }
    if (self.markdownLineSpacing > 0)
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:self.markdownLineSpacing];
        [style setAlignment:self.textAlignment];
        [str addAttribute:NSParagraphStyleAttributeName
                    value:style
                    range:NSMakeRange(0, str.length)];
    }
    self.attributedText = str;
}

@end

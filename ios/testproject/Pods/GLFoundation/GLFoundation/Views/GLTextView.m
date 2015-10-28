//
//  EmmaTextView.m
//  emma
//
//  Created by Allen Hsu on 11/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GLTextView.h"
#import "UIWebView+Hack.h"
#import "GLLog.h"

@implementation GLTextView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initSubviews];
    }
    return self;
}

- (void)initSubviews
{
    self.webView = [[UIWebView alloc] initWithFrame:self.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.webView.delegate = self;
    self.webView.scrollView.showsHorizontalScrollIndicator = NO;
    self.webView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.dataDetectorTypes = 0;
    self.webView.keyboardDisplayRequiresUserAction = NO;
    self.webView.hackishlyHidesInputAccessoryView = YES;
    [self.webView hideGradientBackgrounds];
    NSURL *path = [[NSBundle mainBundle] URLForResource:@"GLTextView" withExtension:@"html"];
    NSURLRequest *request = [NSURLRequest requestWithURL:path];
    [self.webView loadRequest:request];
    [self addSubview:self.webView];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    GLLog(@"%@", request);
    if ([request.URL.scheme isEqualToString:@"keyboarddidshow"]) {
        if ([self.delegate respondsToSelector:@selector(GLTextViewDidBeginEditing:)]) {
            [self.delegate GLTextViewDidBeginEditing:self];
        }
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"didblur"]) {
        if ([self.delegate respondsToSelector:@selector(GLTextViewDidEndEditing:)]) {
            [self.delegate GLTextViewDidEndEditing:self];
        }
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"textdidchange"]) {
        NSString *fullUrl = [NSString stringWithFormat:@"%@%@", request.URL.host, request.URL.path];
        NSArray *params = [fullUrl componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
        if (params.count >= 2) {
            NSString *heightString = [params objectAtIndex:0];
            NSString *cursorPosString = [params objectAtIndex:1];
            
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            CGFloat height = [[nf numberFromString:heightString] floatValue];
            CGFloat cursorPos = [[nf numberFromString:cursorPosString] floatValue];
            
            [self updateHeightForNewScrollHeight:height cursorPosition:cursorPos];
        }
        if ([self.delegate respondsToSelector:@selector(GLTextViewDidChange:)]) {
            [self.delegate GLTextViewDidChange:self];
        }
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.focusOnLoad) {
        [self recallCursorPosition];
    }
}

- (NSMutableDictionary *)insertedImages
{
    if (!_insertedImages) {
        _insertedImages = [NSMutableDictionary dictionary];
    }
    return _insertedImages;
}

- (void)insertImage:(UIImage *)image
{
    unsigned long i = self.insertedImages.count;
    NSString *imgId = [NSString stringWithFormat:@"img%lu", i];
    [self insertImage:image withId:imgId];
}

- (void)insertImage:(UIImage *)image withId:(NSString *)imgId
{
    if (image && imgId) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cachesDirectory = [paths firstObject];
        int timestamp = (int)[[NSDate date] timeIntervalSince1970];
        int rand = arc4random() % 1000;
        NSString *filename = [NSString stringWithFormat:@"%d%d@2x.jpg", timestamp, rand];
        NSString *imagePath = [cachesDirectory stringByAppendingPathComponent:filename];
        
        NSData *data = UIImageJPEGRepresentation(image, 0.6);
        [data writeToFile:imagePath atomically:YES];
        
        [self.insertedImages setObject:image forKey:filename];
        [self insertImageWithID:imgId src:imagePath andFilename:filename];
        [self recallCursorPosition];
    }
}

- (void)insertImageWithID:(NSString *)imgId src:(NSString *)src andFilename:(NSString *)filename
{
    [self recallCursorPosition];
    NSString *js = [NSString stringWithFormat:@"insertImage(\"%@\", \"%@\", \"%@\")", imgId, src, filename];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)insertText:(NSString *)text
{
    [self recallCursorPosition];
    text = [text stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *js = [NSString stringWithFormat:@"insertText(\"%@\")", text];
    [self.webView stringByEvaluatingJavaScriptFromString:js];
}

- (void)updateHeightForNewScrollHeight:(CGFloat)height cursorPosition:(CGFloat)cursorPos
{
    CGFloat lineHeight = 25.0;
    if (cursorPos == INFINITY) return;
    UIScrollView *scrollView = self.webView.scrollView;
    CGFloat overflow = cursorPos + lineHeight - (scrollView.contentOffset.y + scrollView.bounds.size.height);
    GLLog(@"cursorPos: %f", cursorPos);
    GLLog(@"contentOffset: %@", [NSValue valueWithCGPoint:scrollView.contentOffset]);
    GLLog(@"contentSize: %@", [NSValue valueWithCGSize:scrollView.contentSize]);
    GLLog(@"bounds: %@", [NSValue valueWithCGRect:scrollView.bounds]);
    if (overflow >= 0) {
        CGPoint offset = scrollView.contentOffset;
        offset.y += overflow + 5.0;
        [UIView animateWithDuration:.2 animations:^{
            [scrollView setContentOffset:offset];
        }];
    }
}

- (NSString *)fullText
{
    NSString *content = [self.webView stringByEvaluatingJavaScriptFromString:@"getText()"];
    content = [content stringByReplacingOccurrencesOfString:@"(<[^>]+) style=\"[^\"]*\"" withString:@"$1" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
    content = [content stringByReplacingOccurrencesOfString:@"(<[^>]+) class=\"[^\"]*\"" withString:@"$1" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
    content = [content stringByReplacingOccurrencesOfString:@"(<[^>]+) id=\"[^\"]*\"" withString:@"$1" options:NSRegularExpressionSearch|NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
    return content;
}

- (NSString *)plainText
{
    return @"";
}

- (BOOL)isEmpty
{
    NSString *content = [self.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return ([content isEqualToString:@""] || [content isEqualToString:@"<br>"]);
}

- (void)saveCursorPosition
{
    [self.webView stringByEvaluatingJavaScriptFromString:@"saveCursorPosition()"];
}

- (void)recallCursorPosition
{
    [self.webView becomeFirstResponder];
    [self.webView stringByEvaluatingJavaScriptFromString:@"recallCursorPosition()"];
}

- (void)blur
{
    [self.webView stringByEvaluatingJavaScriptFromString:@""];
}

- (NSDictionary *)usedImages
{
    NSString *content = self.fullText;
    NSMutableDictionary *images = [self.insertedImages mutableCopy];
    NSMutableArray *keysToRemove = [NSMutableArray array];
    for (NSString *key in [images allKeys]) {
        if ([content rangeOfString:key].location == NSNotFound) {
            [keysToRemove addObject:key];
        }
    }
    [images removeObjectsForKeys:keysToRemove];
    return images;
}

@end

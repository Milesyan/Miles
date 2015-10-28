//
//  EmmaTextView.h
//  emma
//
//  Created by Allen Hsu on 11/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLTextView;

@protocol GLTextViewDelegate <NSObject>

- (void)GLTextViewDidFinishLoading:(GLTextView *)textView;
- (void)GLTextViewDidBeginEditing:(GLTextView *)textView;
- (void)GLTextViewDidEndEditing:(GLTextView *)textView;
- (void)GLTextViewDidChange:(GLTextView *)textView;
- (void)GLTextView:(GLTextView *)textView didChangeToHeight:(CGFloat)height withCursorPosition:(CGFloat)cursorPos;

@end

@interface GLTextView : UIView <UIWebViewDelegate>

@property (assign, nonatomic) BOOL shouldLimitScrollViewHeight;
@property (assign, nonatomic) BOOL bringUpKeyboardAfterWebViewFinishLoad;
@property (weak, nonatomic) id <GLTextViewDelegate> delegate;
@property (assign, nonatomic) float previousCursorPosition;
@property (assign, nonatomic) float previousHeight;
@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSMutableDictionary *insertedImages;
@property (assign, nonatomic) BOOL focusOnLoad;

- (void)insertImage:(UIImage *)image;
- (void)insertImage:(UIImage *)image withId:(NSString *)imgId;
- (void)insertImageWithID:(NSString *)imgId src:(NSString *)src andFilename:(NSString *)filename;
- (void)insertText:(NSString *)text;
- (void)updateHeightForNewScrollHeight:(CGFloat)height cursorPosition:(CGFloat)cursorPos;
- (NSString *)fullText;
- (NSString *)plainText;
- (BOOL)isEmpty;
- (void)saveCursorPosition;
- (void)recallCursorPosition;
- (NSDictionary *)usedImages;

@end

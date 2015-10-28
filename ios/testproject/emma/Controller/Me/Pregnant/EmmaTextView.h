//
//  EmmaTextView.h
//  emma
//
//  Created by Allen Hsu on 11/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EmmaTextView;

@protocol EmmaTextViewDelegate <NSObject>

- (void)emmaTextViewDidFinishLoading:(EmmaTextView *)textView;
- (void)emmaTextViewDidBeginEditing:(EmmaTextView *)textView;
- (void)emmaTextViewDidEndEditing:(EmmaTextView *)textView;
- (void)emmaTextViewDidChange:(EmmaTextView *)textView;
- (void)emmaTextView:(EmmaTextView *)textView didChangeToHeight:(CGFloat)height withCursorPosition:(CGFloat)cursorPos;

@end

@interface EmmaTextView : UIView <UIWebViewDelegate>

@property (assign, nonatomic) BOOL shouldLimitScrollViewHeight;
@property (assign, nonatomic) BOOL bringUpKeyboardAfterWebViewFinishLoad;
@property (weak, nonatomic) id <EmmaTextViewDelegate> delegate;
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

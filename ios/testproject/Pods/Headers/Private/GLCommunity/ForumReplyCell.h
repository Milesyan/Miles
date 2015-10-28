//
//  ForumReplyCell.h
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ForumReply.h"

#define REPLY_CELL_IDENTIFIER           @"ForumReplyCell"

@class ForumReplyCell;

@protocol ForumReplyCellDelegate <NSObject>

@optional
- (void)cell:(ForumReplyCell *)cell heightDidChange:(CGFloat)height;
- (void)cell:(ForumReplyCell *)cell finalHeight:(CGFloat)height contentHeight:(CGFloat)contentHeight;
- (void)cell:(ForumReplyCell *)cell showRepliesForReply:(ForumReply *)reply autoFocus:(BOOL)autoFocus;
- (void)cell:(ForumReplyCell *)cell showProfileForUser:(ForumUser *)user;

- (void)cell:(ForumReplyCell *)cell showImagesWithURL:(NSArray *)array fromIndex:(NSUInteger)index;
- (void)cell:(ForumReplyCell *)cell didClickFlagButtonForReply:(ForumReply *)reply;
- (void)cell:(ForumReplyCell *)cell didClickHideButtonForReply:(ForumReply *)reply;

- (void)cell:(ForumReplyCell *)cell needUpdateHeightforReply:(ForumReply *)reply;
- (void)cell:(ForumReplyCell *)cell didClickShowHiddenContentForReply:(ForumReply *)reply;
- (void)cell:(ForumReplyCell *)cell showRules:(ForumReply *)reply;

@end

@interface ForumReplyCell : UITableViewCell <UIWebViewDelegate>

@property (weak, nonatomic) id <ForumReplyCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UILabel *contentLabel;
@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageMask;
@property (assign, nonatomic) BOOL alternative;
@property (strong, nonatomic) ForumReply *reply;
@property (weak, nonatomic) IBOutlet UIButton *buttonBadge;
@property (weak, nonatomic) IBOutlet UIView *subrepliesView;
@property (weak, nonatomic) IBOutlet UIView *subreplyList;
@property (assign, nonatomic) CGFloat contentHeight;
@property (assign, nonatomic) BOOL hideSubreplies;

+ (CGFloat)cellHeightForReply:(ForumReply *)reply;
+ (CGFloat)cellHeightForReply:(ForumReply *)reply hideSubreplies:(BOOL)hideSubreplies;
+ (UIImage *)profileMaskImage;
+ (UIImage *)profileMaskImageNormal;
+ (UIImage *)profileMaskImageAlternative;
+ (UIImage *)profileMaskImageHighlighted;
+ (UIImage *)bubbleBackgroundImage;

@end

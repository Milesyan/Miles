//
//  ForumReplyCell.m
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIWebView+Hack.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/UIImage+Utils.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import "ForumReplyCell.h"
#import "ForumUpvoteButton.h"
#import "Forum.h"

#define REPLY_CELL_BACKGROUND_COLOR         [UIColor whiteColor]
#define REPLY_CELL_BACKGROUND_COLOR_ALT     UIColorFromRGB(0xfbfaf7)
#define REPLY_CELL_BACKGROUND_COLOR_HL      [UIColor lightGrayColor]

#define HIDDEN_CONTENT_HEIGHT   30
#define REPLY_ACTION_HEIGHT     44.0
#define kDefaultContentWebViewHeight    25.0
#define REPLY_DEFAULT_BODY_HEIGHT       80.0
#define REPLY_SUBREPLY_FRAME_WIDTH      ([UIScreen mainScreen].bounds.size.width - (320 - 280))
#define REPLY_SUBREPLY_WIDTH            (REPLY_SUBREPLY_FRAME_WIDTH - 30.0)
#define REPLY_CONTENT_WIDTH             ([UIScreen mainScreen].bounds.size.width - (320 - 280))

@interface ForumReplyCell () <UIAlertViewDelegate>

@property (strong, nonatomic) NSTimer *resizeTimer;
@property (strong, nonatomic) NSArray *imgsURLStrings;

@property (weak, nonatomic) IBOutlet UIImageView *speechBubble;
@property (weak, nonatomic) IBOutlet UIButton *replyButton;
@property (weak, nonatomic) IBOutlet ForumUpvoteButton *likeButton;
@property (weak, nonatomic) IBOutlet UILabel *seeReplyLabel;
@property (weak, nonatomic) IBOutlet UILabel *likeLabel;
@property (weak, nonatomic) IBOutlet UIButton *dislikeButton;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;

@property (weak, nonatomic) IBOutlet UIView *actionButtonContainer;
@property (weak, nonatomic) IBOutlet UIView *hiddenContentContainer;

@end

@implementation ForumReplyCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    self.contentWebView.delegate = nil;
}

- (void)setContentHeight:(CGFloat)contentHeight
{
    if (_contentHeight != contentHeight) {
        _contentHeight = contentHeight;
        if (_contentHeight > 0) {
            self.contentWebView.height = _contentHeight;
            self.subrepliesView.top = self.contentWebView.bottom + 10.0;
        }
    }
}

- (void)setHideSubreplies:(BOOL)hideSubreplies
{
    _hideSubreplies = hideSubreplies;
    self.subrepliesView.hidden = hideSubreplies;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    UIImage *img = [self.buttonBadge backgroundImageForState:UIControlStateNormal];
    img = [img resizableImageWithCapInsets:UIEdgeInsetsMake(img.size.height / 2, img.size.width / 2, img.size.height / 2, img.size.width / 2)];
    [self.buttonBadge setBackgroundImage:img forState:UIControlStateNormal];
    
    [self.contentWebView hideGradientBackgrounds];
    self.contentWebView.delegate = self;
    self.contentWebView.scrollView.bounces = NO;
    self.contentWebView.scrollView.showsHorizontalScrollIndicator = NO;
    self.contentWebView.scrollView.showsVerticalScrollIndicator = NO;
    self.contentWebView.backgroundColor = [UIColor clearColor];
    self.contentWebView.opaque = NO;
    self.contentWebView.scrollView.backgroundColor = [UIColor clearColor];
    self.contentWebView.scrollView.opaque = NO;
    self.contentWebView.userInteractionEnabled = YES;
    self.contentWebView.scrollView.scrollsToTop = NO;
    self.contentWebView.scrollView.scrollEnabled = NO;
    
    UITapGestureRecognizer *tapOnProfileImage = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnProfileImage:)];
    [self.profileImageView addGestureRecognizer:tapOnProfileImage];
    self.profileImageView.userInteractionEnabled = YES;
    
    UITapGestureRecognizer *tapOnSeeReplyLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(seeOlderReplies:)];
    [self.seeReplyLabel addGestureRecognizer:tapOnSeeReplyLabel];
    self.seeReplyLabel.userInteractionEnabled = YES;
    
    self.speechBubble.image = [[self class] bubbleBackgroundImage];
    self.likeButton.layer.cornerRadius = self.likeButton.height / 2;
    self.likeButton.layer.borderWidth = 1;
    
    self.replyButton.layer.cornerRadius = self.replyButton.height / 2;
    self.replyButton.layer.borderWidth = 1;
    self.replyButton.layer.borderColor = [UIColor colorFromWebHexValue:@"E8E8E8"].CGColor;
    
    if (IOS8_OR_ABOVE) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [self unsubscribeAll];
    if (newSuperview) {
        [self subscribe:EVENT_PROFILE_MODIFIED selector:@selector(updateIfNeeded)];
        [self subscribe:EVENT_PROFILE_IMAGE_UPDATE selector:@selector(updateIfNeeded)];
    }
}

- (void)updateIfNeeded
{
    ForumUser *currentUser = [Forum currentForumUser];
    BOOL needUpdate = NO;
    if (self.reply.author.identifier == currentUser.identifier) {
        needUpdate = YES;
    } else {
        for (ForumReply *subreply in self.reply.replies) {
            if (subreply.author.identifier == currentUser.identifier) {
                needUpdate = YES;
                break;
            }
        }
    }
    if (needUpdate) {
        [self reloadData];
    }
}

- (void)tapOnProfileImage:(UITapGestureRecognizer *)gesture
{
    if ([self.delegate respondsToSelector:@selector(cell:showProfileForUser:)]) {
        [self.delegate cell:self showProfileForUser:self.reply.author];
    }
}

- (IBAction)didClickOnName:(id)sender {
    if ([self.delegate respondsToSelector:@selector(cell:showProfileForUser:)]) {
        [self.delegate cell:self showProfileForUser:self.reply.author];
    }
}

- (IBAction)didClickOnSubreply:(UIView *)sender
{
    if (sender.tag < self.reply.replies.count) {
        ForumReply *subreply = [self.reply.replies objectAtIndex:sender.tag];
        if ([self.delegate respondsToSelector:@selector(cell:showProfileForUser:)]) {
            [self.delegate cell:self showProfileForUser:subreply.author];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

#pragma mark - IBAction

- (IBAction)addReply:(id)sender {
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [self showRepliesAutoFocus:YES];
}

- (void)seeOlderReplies:(id)sender {
    [self showRepliesAutoFocus:NO];
}

- (BOOL)handleCallbackResult:(NSDictionary *)result error:(NSError *)error
{
    NSNumber *rc = result[@"rc"];
    if (!error && rc.integerValue == RC_SUCCESS) {
        return NO;
    }
    
    NSString *title = @"Oops";
    NSString *msg = @"Looks like something went wrong, please try later.";
    if (result[@"msg"]) {
        msg = result[@"msg"];
    }
    
    [UIAlertView bk_showAlertViewWithTitle:title
                                   message:msg
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil
                                   handler:^(UIAlertView *alertView, NSInteger buttonIndex) {}];
    return YES;
}

- (IBAction)didClickLikeButton:(id)sender {
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    BOOL toLike = !self.reply.liked;
    [Forum log:BTN_CLK_FORUM_REPLY_LIKE eventData:@{@"topic_id": @(self.reply.topicId),
                                                    @"reply_id": @(self.reply.identifier),
                                                    @"like": @(toLike)}];
    [self toggleLiked];
    self.dislikeButton.enabled = NO;
    [Forum markReply:self.reply.topicId
             replyId:self.reply.identifier
               liked:self.reply.liked
            callback:^(NSDictionary *result, NSError *error)
    {
        if ([self handleCallbackResult:result error:error]) {
            // if error, we need rollback
            [self toggleLiked];
        }
        self.dislikeButton.enabled = YES;
    }];
}

- (IBAction)didDislikeButton:(id)sender
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    
    BOOL toDislike = !self.reply.disliked;
    [Forum log:BTN_CLK_FORUM_REPLY_DISLIKE eventData:@{@"topic_id": @(self.reply.topicId),
                                                       @"reply_id": @(self.reply.identifier),
                                                       @"dislike": @(toDislike)}];
    
    [self toggleDisliked];
    self.likeButton.enabled = NO;
    [Forum markReply:self.reply.topicId
             replyId:self.reply.identifier
            disliked:self.reply.disliked
            callback:^(NSDictionary *result, NSError *error)
    {
        if ([self handleCallbackResult:result error:error]) {
            // if error, we need rollback
            [self toggleDisliked];
        }
        self.likeButton.enabled = YES;
    }];
    
}


- (IBAction)didClickShowContentButton:(id)sender
{
    self.reply.didUnlockLowRatingContent = YES;
    if ([self.delegate respondsToSelector:@selector(cell:didClickShowHiddenContentForReply:)]) {
        [self.delegate cell:self didClickShowHiddenContentForReply:self.reply];
    }
}


- (IBAction)didClickViewRulesButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:showRules:)]) {
        [self.delegate cell:self showRules:self.reply];
    }
}

- (IBAction)didClickMoreButton:(id)sender
{
    BOOL isMySelf = (self.reply.author.identifier == [Forum currentForumUser].identifier);
    UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:nil];
    @weakify(self)
    
    if (isMySelf) {
        [sheet bk_addButtonWithTitle:@"Delete" handler:^{
            @strongify(self)
            [self removeClicked];
        }];
    }
    else {
        [sheet bk_addButtonWithTitle:@"Hide" handler:^{
            @strongify(self)
            [self didClickHideButton];
        }];
        
        [sheet bk_addButtonWithTitle:@"Report" handler:^{
            @strongify(self)
            [self didClickFlagButton];
        }];
    }
    
    [sheet bk_setDestructiveButtonWithTitle:@"Cancel" handler:^{}];
    [sheet showInView:self];
}

- (void)didClickFlagButton
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didClickFlagButtonForReply:)]) {
        [self.delegate cell:self didClickFlagButtonForReply:self.reply];
    }
}

- (void)didClickHideButton
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:didClickHideButtonForReply:)]) {
        [self.delegate cell:self didClickHideButtonForReply:self.reply];
    }
}

- (void)removeClicked
{
    [UIAlertView bk_showAlertViewWithTitle:@"Are you sure you want to delete this comment? This can not be undone!"
                                   message:@""
                         cancelButtonTitle:@"Cancel"
                         otherButtonTitles:@[@"OK"]
                                   handler:^(UIAlertView *alertView, NSInteger buttonIndex)
    {
        if (buttonIndex == alertView.cancelButtonIndex) {
            return;
        }
        
        @weakify(self)
        [Forum removeReply:self.reply.identifier callback:^(NSDictionary *result, NSError *error) {
            @strongify(self)
            if (!error) {
                NSInteger rc = [[result objectForKey:@"rc"] intValue];
                if (rc == RC_SUCCESS) {
                    [self publish:EVENT_FORUM_REPLY_REMOVED data:@{
                                                                   @"topic_id": @(self.reply.topicId),
                                                                   @"reply_id": @(self.reply.identifier)
                                                                   }];
                    [[GLDropdownMessageController sharedInstance] postMessage:@"Comment Deleted!"
                                                                     duration:3
                                                                     inWindow:[GLUtils keyWindow]];
                }
                else {
                    NSString * msg = [result objectForKey:@"msg"];
                    [[GLDropdownMessageController sharedInstance] postMessage:msg
                                                                     duration:3
                                                                     inWindow:[GLUtils keyWindow]];
                }
                return;
            }
            [[GLDropdownMessageController sharedInstance] postMessage:@"Can not remove this comment!"
                                                             duration:3
                                                             inWindow:[GLUtils keyWindow]];
            return;
        }];
    }];
}


#pragma mark - like related function
- (void)toggleDisliked
{
    self.reply.disliked = !self.reply.disliked;
    int diff = self.reply.disliked ? 1 : -1;
    self.reply.countDislikes += diff;
    self.dislikeButton.selected = self.reply.disliked;
    
    if (self.reply.disliked && self.reply.liked) {
        [self toggleLiked];
    }
}


- (void)toggleLiked
{
    self.reply.liked = !self.reply.liked;
    int diff = self.reply.liked ? 1 : -1;
    self.reply.countLikes += diff;
    
    if (self.reply.replyTo > 0) {
        self.dislikeButton.left = self.reply.liked ? 110 : 100;
    }

    if (self.reply.liked && self.reply.disliked) {
        [self toggleDisliked];
    }
    
    [self updateLikeCount];
    [self updateLikeButtonStyle];
    [self updateLikeButtonInset];
    
    if ((self.reply.countLikes == 0 && diff == -1) || (self.reply.countLikes == 1 && diff == 1)) {
        if ([self.delegate respondsToSelector:@selector(cell:needUpdateHeightforReply:)]) {
            [self.delegate cell:self needUpdateHeightforReply:self.reply];
        }
    }
}


- (void)updateLikeButtonStyle
{
    self.likeButton.selected = self.reply.liked;
    
    NSString *hex = self.reply.liked ? @"EFEFFA" : @"FFFFFF";
    self.likeButton.backgroundColor = [UIColor colorFromWebHexValue:hex];
    
    hex = self.reply.liked ? @"5B62D2" : @"E8E8E8";
    self.likeButton.layer.borderColor = [UIColor colorFromWebHexValue:hex].CGColor;
    
    self.likeButton.titleLabel.font = self.reply.liked ? [GLTheme semiBoldFont:13] : [GLTheme defaultFont:13];
}


- (void)updateLikeCount
{
    self.likeLabel.text = [NSString stringWithFormat:@"%@%@ upvote%s",
                           (self.reply.replies.count>0) ? @" • " : @"",
                           [NSString numberToShortIntString:self.reply.countLikes],
                           (self.reply.countLikes==1) ? "" : "s"];
    [self.likeLabel sizeToFit];
    if (self.reply.replies.count > 0) {
        [self.likeLabel setLeft:self.seeReplyLabel.right];
    } else {
        [self.likeLabel setLeft:0];
    }
    self.likeLabel.hidden = self.reply.countLikes == 0;
    if ((self.reply.countLikes == 0) || (self.reply.countLikes == 1)) {
        [self doResizeCell];
    }
}


- (void)updateLikeButtonInset
{
    if (self.reply.liked) {
        self.likeButton.width = 105;
        self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 9);
        self.likeButton.titleEdgeInsets = UIEdgeInsetsMake(0, 5, 0, 0);
    }
    else {
        self.likeButton.width = 95;
        self.likeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 7);
        self.likeButton.titleEdgeInsets = UIEdgeInsetsMake(0, 7, 0, 0);
    }
}


#pragma mark -

- (void)showRepliesAutoFocus:(BOOL)autoFocus
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(cell:showRepliesForReply:autoFocus:)]) {
        [self.delegate cell:self showRepliesForReply:self.reply autoFocus:autoFocus];
    }
}

- (void)setReply:(ForumReply *)reply
{
    if (_reply != reply) {
        _reply = reply;
    }
    [self reloadData];
}

- (void)reloadData
{
    BOOL hasImage = [self.reply containsImage];
    ForumUser *currentUser = [Forum currentForumUser];
    BOOL isMySelf = (self.reply.author.identifier == currentUser.identifier);
    ForumUser *userModel = isMySelf ? currentUser : self.reply.author;
    
    self.contentLabel.hidden = YES;
    self.contentWebView.hidden = YES;
    [self.contentWebView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML = \"\";"];
    
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    UIImage *anonymousProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    if (self.reply.isAnonymous) {
        self.profileImageView.image = anonymousProfileImage;
    } else {
        if (userModel.cachedProfileImage) {
            self.profileImageView.image = userModel.cachedProfileImage;
        } else if (userModel.profileImage.length > 0) {
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:userModel.profileImage] placeholderImage:defaultProfileImage completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                userModel.cachedProfileImage = image;
            }];
        } else {
            self.profileImageView.image = defaultProfileImage;
        }
    }
    
    self.buttonBadge.hidden = YES;
    if (![self.reply isAnonymous]) {
        if (self.reply.author.badge.length > 0) {
            self.buttonBadge.hidden = NO;
            [self.buttonBadge setTitle:self.reply.author.badge forState:UIControlStateNormal];
            self.buttonBadge.width = 160.0;
            [self.buttonBadge.titleLabel sizeToFit];
            self.buttonBadge.width = self.buttonBadge.titleLabel.width + 30.0;
        }
    }
    
    self.timeLabel.text = [NSString stringWithFormat:@"• %@", [NSString timeElapsedString:self.reply.timeCreated]];
    
    NSString *firstName = isMySelf ? currentUser.firstName : self.reply.author.firstName;
    if (![self.reply isAnonymous] && firstName.length > 0) {
        [self.nameButton setTitle:firstName forState:UIControlStateNormal];
        self.nameButton.width = 200.0;
        [self.nameButton.titleLabel sizeToFit];
        self.nameButton.titleLabel.height = 25.0;
        self.nameButton.width = self.nameButton.titleLabel.width;
        self.nameButton.height = 25.0;
        self.timeLabel.left = self.nameButton.right + 3.0;
        self.timeLabel.width = 255.0 - self.timeLabel.left;
    } else {
        self.nameButton.hidden = YES;
        self.timeLabel.left = 20.0;
        self.timeLabel.width = 255.0;
    }
    
    CGRect subFrame = self.subrepliesView.frame;
    subFrame.size.width = REPLY_SUBREPLY_FRAME_WIDTH;
    if (hasImage) {
        if (self.contentHeight <= 0) {
            self.contentHeight = kDefaultContentWebViewHeight;
        }
        self.contentWebView.frame = CGRectMake(20.0, 60.0, REPLY_CONTENT_WIDTH, self.contentHeight);
        [self.contentWebView loadHTMLString:[self htmlWithContent:self.reply.content] baseURL:nil];
        subFrame.origin.y = self.contentWebView.frame.origin.y + self.contentWebView.frame.size.height + 10.0;
    } else {
        NSMutableAttributedString *attrContent = [[NSMutableAttributedString alloc] initWithString:self.reply.content ?: @"" attributes:[ForumReplyCell contentAttribute]];
        self.contentLabel.attributedText = attrContent;
        [self.contentLabel setWidth:REPLY_CONTENT_WIDTH];
        [self.contentLabel sizeToFit];
        subFrame.origin.y = self.contentLabel.frame.origin.y + self.contentLabel.frame.size.height + 10.0;
        self.contentHeight = self.contentLabel.height;
    }
    
    /* NOTE
     *   we have 2 ways to show reply cell
     *   one is in topic page, the other one is in search page
     *   If in search page
     *   (1) hideSubreplies = YES
     *   (2) reply.replies.count = 0, while reply.countReplies my not be 0
     *       So, countReplies is useless !!!!
     */
    
    self.subrepliesView.hidden = YES;
    self.hiddenContentContainer.hidden = YES;
    self.actionButtonContainer.hidden = YES;
    self.nameButton.enabled = YES;
    
    if (self.hideSubreplies) {
    }
    else if (self.reply.shouldHideLowRatingContent) {
        self.hiddenContentContainer.hidden = NO;
        self.nameButton.enabled = NO;
        self.profileImageView.image = [UIImage imageNamed:@"hidden-profile"];
    }
    else if (self.reply.replyTo != 0) {
        self.actionButtonContainer.hidden = NO;
        self.moreButton.hidden = YES;
        self.replyButton.hidden = YES;
        self.likeButton.left = 0;
        self.dislikeButton.left = self.reply.liked ? 110 : 100;
        
        if (self.reply.countLikes > 0) {
            self.likeLabel.text = [NSString stringWithFormat:@"%@ upvote%s",
                                   [NSString numberToShortIntString:self.reply.countLikes],
                                   (self.reply.countLikes==1) ? "" : "s"];
            [self.likeLabel sizeToFit];
            self.likeLabel.left = 0;
            self.likeLabel.hidden = NO;
            self.seeReplyLabel.hidden = YES;
            self.subreplyList.hidden = YES;
            self.subrepliesView.hidden = NO;
            self.subrepliesView.height = 32;
        }
    }
    else {
        self.subrepliesView.hidden = NO;
        self.subrepliesView.frame = subFrame;
        
        self.actionButtonContainer.hidden = NO;
        self.moreButton.hidden = NO;
        self.replyButton.hidden = NO;
        
        CGFloat y = 0;
        // replies or likes
        if ((self.reply.replies.count > 0) || (self.reply.countLikes > 0)) {
            self.likeLabel.text = [NSString stringWithFormat:@"%@%@ upvote%s",
                                   (self.reply.replies.count>0) ? @" • " : @"",
                                   [NSString numberToShortIntString:self.reply.countLikes],
                                   (self.reply.countLikes==1) ? "" : "s"];
            [self.likeLabel sizeToFit];
            
            self.seeReplyLabel.text = [NSString stringWithFormat:@"View all %@ %@",
                                       [NSString numberToShortIntString:self.reply.replies.count],
                                       (self.reply.replies.count==1) ? @"reply" : @"replies"];
            [self.seeReplyLabel sizeToFit];
            
            if (self.reply.replies.count > 0) {
                self.seeReplyLabel.hidden = NO;
                [self.likeLabel setLeft:self.seeReplyLabel.right];
            } else {
                self.seeReplyLabel.hidden = YES;
                [self.likeLabel setLeft:0];
            }
            self.likeLabel.hidden = self.reply.countLikes == 0;
            
            y = 20.0;
        } else {
            self.seeReplyLabel.hidden = YES;
            self.likeLabel.hidden = YES;
            y = 0;
        }

        // reply list view
        if (self.reply.replies.count == 0) {
            self.subreplyList.hidden = YES;
            if (self.reply.countLikes > 0) {
                // padding, between replies/likes and button
                y += 12.0;
            }
        } else {
            self.subreplyList.hidden = NO;
            for (UIView *v in self.subreplyList.subviews) {
                if ([v isKindOfClass:[UIButton class]]) {
                    [v removeFromSuperview];
                }
            }
            CGFloat subY = 20;
            for (NSInteger i = 0; i < self.reply.replies.count; i++) {
                ForumReply *subreply = [self.reply.replies objectAtIndex:i];
                BOOL isMySub = (subreply.author.identifier == currentUser.identifier);
                UIButton *sublabel = [UIButton buttonWithType:UIButtonTypeCustom];
                sublabel.frame = CGRectMake(15.0, subY, REPLY_SUBREPLY_WIDTH, 100.0);
                sublabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
                sublabel.titleLabel.numberOfLines = 0;
                sublabel.titleLabel.textAlignment = NSTextAlignmentLeft;
                sublabel.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                sublabel.opaque = NO;
                sublabel.backgroundColor = [UIColor clearColor];
                [sublabel setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
                NSMutableAttributedString *attrReply = [[NSMutableAttributedString alloc] init];
                NSMutableAttributedString *attrReplyHightlight = [[NSMutableAttributedString alloc] init];
                NSString *firstName = isMySub ? currentUser.firstName : subreply.author.firstName;
                if (firstName.length > 0) {
                    [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:firstName attributes:[ForumReplyCell replyAuthorAttribute]]];
                    [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[ForumReplyCell replyAttribute]]];
                    [attrReplyHightlight appendAttributedString:[[NSAttributedString alloc] initWithString:firstName attributes:[ForumReplyCell replyAuthorHighlightAttribute]]];
                    [attrReplyHightlight appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[ForumReplyCell replyAttribute]]];
                }
                [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:subreply.content attributes:[ForumReplyCell replyAttribute]]];
                [attrReplyHightlight appendAttributedString:[[NSAttributedString alloc] initWithString:subreply.content attributes:[ForumReplyCell replyAttribute]]];
                [sublabel setAttributedTitle:attrReply forState:UIControlStateNormal];
                [sublabel setAttributedTitle:attrReplyHightlight forState:UIControlStateHighlighted];
                [sublabel.titleLabel setPreferredMaxLayoutWidth:REPLY_SUBREPLY_WIDTH];
                CGSize size = [sublabel.titleLabel sizeThatFits:CGSizeMake(REPLY_SUBREPLY_WIDTH, 0)];
                sublabel.size = size;
                subY = sublabel.bottom;
                
                sublabel.tag = i;
                
                [sublabel addTarget:self action:@selector(didClickOnSubreply:) forControlEvents:UIControlEventTouchUpInside];
                
                [self.subreplyList addSubview:sublabel];
                
                subY += 2.0;
            }
            subY += 13.0;
            [self.subreplyList setHeight:subY];
            y += subY + 12.0;
        }
        // buttons
        [self.subrepliesView setHeight:y + REPLY_ACTION_HEIGHT];
    }
    
    if (hasImage) {
        self.contentLabel.hidden = YES;
        self.contentWebView.hidden = YES;
    } else {
        self.contentWebView.hidden = YES;
        self.contentLabel.hidden = NO;
    }
    
    // set like status
    self.likeButton.selected = self.reply.liked;
    NSString *hex = self.reply.liked ? @"BEBEBE" : @"EFEEFB";
    self.likeButton.backgroundColor = [UIColor colorFromWebHexValue:hex];
    
    self.dislikeButton.selected = self.reply.disliked;
    
    [self updateLikeButtonStyle];
    [self updateLikeButtonInset];
    [self setNeedsDisplay];
}

- (NSString *)htmlWithContent:(NSString *)content
{
    static NSString *htmlBase = nil;
    if (!htmlBase) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ForumReplyCell" withExtension:@"html"];
        htmlBase = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    }
    NSString *result = htmlBase;
    @autoreleasepool {
        result = [result stringByReplacingOccurrencesOfString:@"#@content@#" withString:content];
        
        NSRegularExpression *nameExpression = [NSRegularExpression regularExpressionWithPattern:@"<img[^>]*?src[^=>]*?=[^\">]*?\"([^\">]*?)\"[^>]*?>" options:0 error:nil];
        
        NSArray *matches = [nameExpression matchesInString:result
                                                   options:0
                                                     range:NSMakeRange(0, [result length])];
        
        NSMutableArray *imgs = [@[] mutableCopy];
        NSMutableArray *urls = [@[] mutableCopy];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSString *matchString = [result substringWithRange:matchRange];
            
            NSRange urlRange = [match rangeAtIndex:1];
            NSString *urlString = [result substringWithRange:urlRange];

            [imgs addObject:matchString];
            [urls addObject:urlString];
            GLLog(@"%@", matchString);
        }
        self.imgsURLStrings = urls;
        
        for (int i = 0; i < imgs.count; i++)
        {
            NSString *img = imgs[i];
            NSString *url = urls[i];
            int size = [UIScreen mainScreen].bounds.size.width;
            NSString *div = [NSString stringWithFormat:@"<div style=\"width: %dpx; height: %dpx;background-color:#eeeeee; border: 1px solid #eeeee; overflow: hidden; position: relative;\">\n         <img src=\"%@\" style=\"position: absolute;\" onload=\"OnImageLoad(event);\" />\n</div>",size, size, url];
            result = [result stringByReplacingOccurrencesOfString:img withString:div];
        }
    }
    
    return result;
}

- (void)showPictureWithURLString:(NSString *)str
{
    NSURL *url = [NSURL URLWithString:str];
    if ([self.delegate respondsToSelector:@selector(cell:showImagesWithURL:fromIndex:)])
    {
        NSInteger index = [self.imgsURLStrings indexOfObject:str];
        if (index == NSNotFound)
        {
            [self.delegate cell:self showImagesWithURL:@[url] fromIndex:0];
        }
        else
        {
            [self.delegate cell:self showImagesWithURL:self.imgsURLStrings fromIndex:index];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    GLLog(@"%@", request);
    if ([request.URL.scheme isEqualToString:@"sizechanged"]) {
        [self delayedResizeContentWebView];
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"domready"]) {
        if ([self.reply containsImage]) {
            self.contentWebView.hidden = NO;
            return NO;
        }
    } else if ([request.URL.scheme isEqualToString:@"showimage"]) {
        NSString *url = request.URL.resourceSpecifier;
        url = [url stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url = [url substringFromIndex:2];
        [self showPictureWithURLString:url];
        GLLog(@"Should Show Image at %@",url);
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"info"]) {
        NSString *info = request.URL.resourceSpecifier;
        info = [info stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        info = [info substringFromIndex:2];
        GLLog(@"Info %@", info);
        return NO;
    } else if ([request.URL.scheme isEqualToString:FORUM_SCHEME_TOOLTIP]) {
        [Forum tip:request.URL.host];
        return NO;
    }
    return YES;
}

- (void)delayedResizeContentWebView
{
    GLLog(@"Delayed");
    // leave breadcrumbs for debug
//    [CrashReport leaveBreadcrumb:[NSString stringWithFormat:@"ForumReplyCell delayResize, reply id=%@", @(self.reply.identifier)]];
    if (self.resizeTimer) {
        [self.resizeTimer invalidate];
    }
    self.resizeTimer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(resizeContentWebView) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.resizeTimer forMode:NSRunLoopCommonModes];
}

- (void)doResizeCell {
    if ([self.delegate respondsToSelector:@selector(cell:heightDidChange:)]) {
        CGFloat height = self.contentHeight + REPLY_DEFAULT_BODY_HEIGHT;
        if (self.hideSubreplies) {
            [self.delegate cell:self heightDidChange:height];
        }
        else if (self.reply.shouldHideLowRatingContent) {
            [self.delegate cell:self heightDidChange:height + HIDDEN_CONTENT_HEIGHT];
        }
        else if (self.reply.replyTo != 0) {
            [self.delegate cell:self heightDidChange:height + REPLY_ACTION_HEIGHT];
        }
        else {
            height += REPLY_ACTION_HEIGHT;
            if ((self.reply.replies.count > 0) || (self.reply.countLikes > 0)) {
                height += 20;
            }
            if (self.reply.replies.count > 0) {
                height += self.subreplyList.height + 12.0;
            }
            else if (self.reply.countLikes > 0) {
                height += 7; // padding in replies/likes label <-> buttons
            }
            [self.delegate cell:self heightDidChange:height];
        }
    }
}

- (void)resizeContentWebView
{
    if (![self.reply containsImage]) {
        return;
    }
    NSInteger bodyHeight = [[self.contentWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').offsetHeight"] integerValue];
    self.contentHeight = bodyHeight;
    [self doResizeCell];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    GLLog(@"Content did finish load");
    [self finalResize];
}

- (void)finalResize
{
    if (![self.reply containsImage]) {
        return;
    }
    NSInteger bodyHeight = [[self.contentWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').offsetHeight"] integerValue];
    self.contentHeight = bodyHeight;
    [self doResizeCell];
}

+ (NSMutableDictionary *)contentAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                      NSFontAttributeName : [GLTheme defaultFont:18.0],
                      NSForegroundColorAttributeName : [UIColor blackColor],
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 25;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (NSMutableDictionary *)authorAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                      NSFontAttributeName : [GLTheme semiBoldFont:18.0],
                      NSForegroundColorAttributeName : UIColorFromRGB(0x5a62d2),
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 25;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (NSMutableDictionary *)timeAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                      NSFontAttributeName : [GLTheme defaultFont:18.0],
                      NSForegroundColorAttributeName : [UIColor colorWithWhite:165.0/255.0 alpha:1.0],
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 25;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (NSMutableDictionary *)replyAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                      NSFontAttributeName : [GLTheme defaultFont:15.0],
                      NSForegroundColorAttributeName : [UIColor blackColor],
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 16;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (NSMutableDictionary *)replyAuthorAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                      NSFontAttributeName : [GLTheme semiBoldFont:15.0],
                      NSForegroundColorAttributeName : UIColorFromRGB(0x5a62d2),
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 18;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (NSMutableDictionary *)replyAuthorHighlightAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                        NSFontAttributeName : [GLTheme semiBoldFont:15.0],
                        NSForegroundColorAttributeName : UIColorFromRGBA(0x5a62d240),
                        } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 18;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

+ (CGFloat)cellHeightForReply:(ForumReply *)reply
{
    return [self cellHeightForReply:reply hideSubreplies:NO];
}

+ (CGFloat)cellHeightForReply:(ForumReply *)reply hideSubreplies:(BOOL)hideSubreplies
{
    static UILabel *tmpContentLabel = nil;
    static UILabel *tmpSubreplyLabel = nil;
    
    if (!tmpContentLabel) {
        tmpContentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        tmpContentLabel.numberOfLines = 0;
    }
    
    if (!tmpSubreplyLabel) {
        tmpSubreplyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        tmpSubreplyLabel.numberOfLines = 0;
    }
    
    CGFloat contentHeight = 0;
    
    if ([reply containsImage]) {
        contentHeight = kDefaultContentWebViewHeight;
    } else {
        NSMutableAttributedString *attrContent = [[NSMutableAttributedString alloc] initWithString:reply.content ?: @"" attributes:[ForumReplyCell contentAttribute]];
        tmpContentLabel.attributedText = attrContent;
        [tmpContentLabel setWidth:REPLY_CONTENT_WIDTH];
        [tmpContentLabel sizeToFit];
        contentHeight = tmpContentLabel.height;
    }
    
    if (hideSubreplies) {
        return contentHeight + REPLY_DEFAULT_BODY_HEIGHT;
    }
    else if (reply.shouldHideLowRatingContent) {
        return contentHeight + REPLY_DEFAULT_BODY_HEIGHT + HIDDEN_CONTENT_HEIGHT;
    }
    else if (reply.replyTo != 0) {
        CGFloat height = contentHeight + REPLY_DEFAULT_BODY_HEIGHT + REPLY_ACTION_HEIGHT;
        if (reply.countLikes > 0) {
            height += 28;
        }
        return height;
    }
    else {
        CGFloat y = 0;
        if ((reply.replies.count > 0) || (reply.countLikes > 0)) {
            y += 20;
        }
        if (reply.replies.count > 0) {
            y += 20.0;
            for (ForumReply *subreply in reply.replies) {
                NSMutableAttributedString *attrReply = [[NSMutableAttributedString alloc] init];
                if (subreply.author.firstName.length > 0) {
                    [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:subreply.author.firstName attributes:[self replyAuthorAttribute]]];
                    [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:[self replyAttribute]]];
                }
                [attrReply appendAttributedString:[[NSAttributedString alloc] initWithString:subreply.content attributes:[self replyAttribute]]];
                tmpSubreplyLabel.attributedText = attrReply;
                [tmpSubreplyLabel setWidth:REPLY_SUBREPLY_WIDTH];
                [tmpSubreplyLabel sizeToFit];
                y += tmpSubreplyLabel.frame.size.height;
                y += 2.0;
            }
            y += 13.0; // view list frame bottom padding
            // now y  = subreplyList.bottom
            y += 12.0; // view list frame bottom margin
        }
        else if (reply.countLikes > 0) {
            y += 7.0; // padding in replies/likes label <-> buttons
        }
        return contentHeight + REPLY_DEFAULT_BODY_HEIGHT + REPLY_ACTION_HEIGHT + y;
    }
}

+ (UIImage *)profileMaskImage
{
    static UIImage *sImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sImage = [UIImage imageNamed:@"gl-community-profile-image-mask-35"];
    });
    return sImage;
}

+ (UIImage *)profileMaskImageNormal
{
    static UIImage *sImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sImage = [[self profileMaskImage] imageWithTintColor:REPLY_CELL_BACKGROUND_COLOR];
    });
    return sImage;
}

+ (UIImage *)profileMaskImageAlternative
{
    static UIImage *sImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sImage = [[self profileMaskImage] imageWithTintColor:REPLY_CELL_BACKGROUND_COLOR_ALT];
    });
    return sImage;
}

+ (UIImage *)profileMaskImageHighlighted
{
    static UIImage *sImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sImage = [[self profileMaskImage] imageWithTintColor:REPLY_CELL_BACKGROUND_COLOR_HL];
    });
    return sImage;
}

+ (UIImage *)bubbleBackgroundImage
{
    static UIImage *sImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sImage = [UIImage imageNamed:@"gl-community-replies-speechbubble"];
//        sImage = [UIImage imageWithColor:FORUM_COLOR_LIGHT_GRAY andSize:sImage.size];
        sImage = [sImage resizableImageWithCapInsets:UIEdgeInsetsMake(sImage.size.height / 2, sImage.size.width / 2, sImage.size.height / 2, sImage.size.width / 2)];
    });
    return sImage;
}

@end

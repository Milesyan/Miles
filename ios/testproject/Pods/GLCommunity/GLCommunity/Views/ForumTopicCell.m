//
//  ForumTopicCell.m
//  emma
//
//  Created by Allen Hsu on 11/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Blur.h>
#import <GLFoundation/UIImage+Utils.h>

#import "ForumTopicCell.h"
#import "ForumCategory.h"
#import "Forum.h"

#define kTopicInfoElementPadding 8
#define kCellElementPadding 8
#define kAuthorInfoHeight 28
#define kUrlCardInfoHeight 64

@interface ForumTopicCell ()

@property (weak, nonatomic) IBOutlet UIButton *pinnedButton;
@property (weak, nonatomic) IBOutlet ForumGroupButton *groupButton;

@property (weak, nonatomic) IBOutlet UIButton *triangleButton;

// user info
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *userLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *authorInfoContainerTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *nameLabelLeftConstraint;


// topic info
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIView *thumbnailView;
@property (weak, nonatomic) IBOutlet UIView *warningOverlay;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UIImageView *pollIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UILabel *topicSummaryLabel;

@property (weak, nonatomic) IBOutlet UIView *topicInfoContainerView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topicInfoTextLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topicTitleTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topicDescTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topicInfoContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *summaryTopConstraint;

// url card
@property (weak, nonatomic) IBOutlet UIView *urlPreviewCard;
@property (weak, nonatomic) IBOutlet UIImageView *urlPreviewCardThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardTitle;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardDesc;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardUrl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *urlTextLeftConstraint;

@property (weak, nonatomic) IBOutlet UIButton *userNameButton;
@property (weak, nonatomic) IBOutlet UIView *hiddenContentContainer;

@property (strong, nonatomic) ForumTopic *topic;
@property (assign, nonatomic) BOOL isProfileTopic;

@property (strong, nonatomic) UILongPressGestureRecognizer *longPress;

@property (weak, nonatomic) IBOutlet UIButton *quizButton;

@end


@implementation ForumTopicCell


+ (BOOL)shouldShowTopicDescriptionForTopic:(ForumTopic *)topic;
{
    return topic.hasDesc && !topic.isURLTopic && !topic.isQuiz;
}


+ (BOOL)shouldShowTopicStatForTopic:(ForumTopic *)topic
{
    return topic.countReplies > 0 || (topic.isPoll && topic.pollOptions.totalVotes > 0);
}


+ (CGFloat)heightNeededForTopicInfoContainer:(ForumTopic *)topic
{
    if (topic.isPhotoTopic || topic.isQuiz) {
        return 90;
    }
    
    static NSDictionary *attrs = nil;
    attrs = @{NSFontAttributeName: [GLTheme semiBoldFont:18]};
    
    CGFloat padding = kTopicInfoElementPadding;
    CGFloat titleLabelWidth = (topic.isPhotoTopic ? 186: 284) + (SCREEN_WIDTH - 320);
    NSString *title = topic.isPoll ? [NSString stringWithFormat:@"    %@", topic.title] : topic.title;
    CGFloat titleHeight = [title boundingRectWithSize:CGSizeMake(titleLabelWidth, CGFLOAT_MAX)
                                                    options:NSStringDrawingUsesLineFragmentOrigin
                                                 attributes:attrs
                                                    context:nil].size.height;
    
    CGFloat heightNeeded = MIN(36, roundf(titleHeight));
    
    if ([ForumTopicCell shouldShowTopicDescriptionForTopic:topic]) {
        heightNeeded += padding + 14;
    }
    
    if (topic.isQuiz) {
        heightNeeded += 32;
    }
    
    if ([ForumTopicCell shouldShowTopicStatForTopic:topic]) {
        heightNeeded += padding + 14;
    }
    
    return heightNeeded;
}


+ (CGFloat)cellHeightForTopic:(ForumTopic *)topic
{
    CGFloat height = 15 + kAuthorInfoHeight + kCellElementPadding;
    height += [self heightNeededForTopicInfoContainer:topic];
    
    if (topic.isURLTopic) {
        height += kCellElementPadding + kUrlCardInfoHeight;
    }
    
    height += 20;
    return height;
}


+ (CGFloat)cellHeightForTopic:(ForumTopic *)topic showsGroup:(BOOL)showsGroup showsPinned:(BOOL)showsPinned
{
    CGFloat height = (showsGroup || showsPinned) ? 30 : 15;
    
    height += kAuthorInfoHeight;
    
    if (topic.shouldHideLowRatingContent) {
        return height + 68;
    }
    
    height += kCellElementPadding + [self heightNeededForTopicInfoContainer:topic];
    
    if (topic.isURLTopic) {
        height += kCellElementPadding + kUrlCardInfoHeight;
    }
    
    height += 20;
    
    return height;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIImage *img = [self.pinnedButton backgroundImageForState:UIControlStateNormal];
    UIEdgeInsets insets = UIEdgeInsetsMake(img.size.height / 2, img.size.width / 2,
                                           img.size.height / 2, img.size.width / 2);
    img = [img resizableImageWithCapInsets:insets];
    [self.pinnedButton setBackgroundImage:img forState:UIControlStateNormal];
    
    self.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    
    self.quizButton.layer.cornerRadius = self.quizButton.height / 2.0;
    self.warningLabel.layer.cornerRadius = 2.0;
    self.groupButton.layer.cornerRadius = 2.0;
    self.urlPreviewCard.layer.cornerRadius = 3;
    self.urlPreviewCardThumbnail.layer.cornerRadius = 1;
    self.profileImageView.layer.cornerRadius = self.profileImageView.width / 2;
    self.thumbnailImageView.layer.cornerRadius = 2.0;
    
    UIImage *pollImage = [UIImage imageNamed:@"gl-community-poll"];
    pollImage = [pollImage imageWithTintColor:UIColorFromRGB(0xA4A5A6)];
    self.pollIcon.image = pollImage;
 
    self.longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.longPress setDelaysTouchesBegan:YES];
//    [self.longPress setDelaysTouchesEnded:NO];
    [self addGestureRecognizer:self.longPress];
    
    if (IOS8_OR_ABOVE) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    self.contentView.backgroundColor = selected ? FORUM_COLOR_LIGHT_GRAY : [UIColor whiteColor];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    self.contentView.backgroundColor = highlighted ? FORUM_COLOR_LIGHT_GRAY : [UIColor whiteColor];
}

- (NSAttributedString *)attributedTitleForGroup:(ForumGroup *)group
{
    ForumCategory *category = [Forum categoryFromGroup:group];
    UIColor *themeColor = category ? [UIColor colorFromWebHexValue:category.backgroundColor] : GLOW_COLOR_PURPLE;
    NSDictionary *attr = @{NSFontAttributeName: [GLTheme defaultFont:14.0],
                           NSForegroundColorAttributeName: themeColor};
    NSDictionary *nameAttr = @{NSFontAttributeName: [GLTheme boldFont:14.0],
                               NSForegroundColorAttributeName: themeColor,
                               NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle)};
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"In " attributes:attr];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:group.name ?: @"Unknown" attributes:nameAttr]];
    [string appendAttributedString:[[NSAttributedString alloc] initWithString:@" group" attributes:attr]];
    return string;
}


- (void)configureWithTopic:(ForumTopic *)topic
                 isProfile:(BOOL)isProfile
                 showGroup:(BOOL)showGroup
                showPinned:(BOOL)showPinned
{
    self.topic = topic;
    self.isProfileTopic = isProfile;

//    self.triangleButton.hidden = isProfile;
    self.groupButton.hidden = YES;
    self.pinnedButton.hidden = YES;
    
    if (showGroup || showPinned) {
        [self updateGroupButton:showGroup pinButton:showPinned];
        self.authorInfoContainerTopConstraint.constant = 30;
    }
    else {
        self.authorInfoContainerTopConstraint.constant = 15;
    }
    
    [self updateAuthorInfo];
    [self updateTopicInfo];
    
    CGFloat height = [ForumTopicCell heightNeededForTopicInfoContainer:topic];
    self.topicInfoContainerHeightConstraint.constant = height;
    
    self.urlPreviewCard.hidden = !self.topic.isURLTopic;
    if (self.topic.isURLTopic) {
        [self updateUrlCard:self.topic];
    }
    
    [self updateViewsVisibility];
    
    [self layoutIfNeeded];
}


- (void)updateViewsVisibility
{
    if (!self.isProfileTopic && self.topic.shouldHideLowRatingContent) {
        self.topicInfoContainerView.hidden = YES;
        self.urlPreviewCard.hidden = YES;
        self.hiddenContentContainer.hidden = NO;
    }
    else {
        self.topicInfoContainerView.hidden = NO;
        self.urlPreviewCard.hidden = !self.topic.isURLTopic;
        self.hiddenContentContainer.hidden = YES;
    }
    
    [self updateAuthorInfo];
}


- (void)updateGroupButton:(BOOL)showGroup pinButton:(BOOL)showPinned
{
    if (showPinned && [self.topic isPinned]) {
        self.groupButton.hidden = YES;
        self.pinnedButton.hidden = NO;
        [self.pinnedButton setTitle:@"Pinned" forState:UIControlStateNormal];
    }
    else if (showGroup) {
        ForumCategory *category = [Forum categoryFromGroup:self.group];
        UIColor *themeColor = category ? [UIColor colorFromWebHexValue:category.backgroundColor] : GLOW_COLOR_PURPLE;
        [self.groupButton setTitle:self.group.name ?: @"Unknown Group" forState:UIControlStateNormal];
        [self.groupButton setThemeColor:themeColor];
        self.groupButton.hidden = NO;
        self.pinnedButton.hidden = YES;
    }
    
}

- (BOOL)showResponse
{
    return self.topic.countReplies > 0 && (self.isParticipatedTopic || !self.isProfileTopic);
}

- (void)updateAuthorInfo
{
    ForumUser *user;
    BOOL showUser;

    if (self.showResponse) {
        user = self.topic.replier;
        showUser = user.firstName.length > 0;
        
        self.userLabel.text = showUser ? @" responded:" : @"New response added:";
    }
    else {
        user = self.topic.author;
        showUser = !self.topic.isAnonymous && user.firstName.length > 0;
        
        if (self.topic.isPhotoTopic) {
            self.userLabel.text = !showUser ? @"New photo shared:" : @" shared a new photo:";
        }
        else if (self.topic.isPoll) {
            self.userLabel.text = !showUser ? @"New poll added:" : @" added a new poll:";
        }
        else if (self.topic.isURLTopic) {
            self.userLabel.text = !showUser ? @"New link shared:" : @" shared a new link:";
        }
        else {
            self.userLabel.text = !showUser ? @"New topic shared:" : @" added a new topic:";
        }
    }
    
    self.nameLabel.text = showUser ? user.firstName : @"";
    
    if (self.isProfileTopic || self.topic.shouldHideLowRatingContent) {
        self.nameLabel.textColor = UIColorFromRGB(0xa5a5a5);
        self.userNameButton.hidden = YES;
    }
    else {
        self.nameLabel.textColor = GLOW_COLOR_PURPLE;
        self.userNameButton.hidden = NO;
    }
    
    // profile image
    if (self.topic.shouldHideLowRatingContent && !self.isProfileTopic) {
        self.profileImageView.image = [UIImage imageNamed:@"hidden-profile"];
        return;
    }
    
    ForumUser *currentUser = [Forum currentForumUser];
    BOOL isUserSelf = (user.identifier == currentUser.identifier);
    ForumUser *userModel = isUserSelf ? currentUser : user;
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    
    if (self.topic.countReplies == 0 && self.topic.isAnonymous) {
        self.profileImageView.image = defaultProfileImage;
    }
    else {
        if (userModel.cachedProfileImage) {
            self.profileImageView.image = userModel.cachedProfileImage;
        }
        else if (userModel.profileImage.length > 0) {
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:userModel.profileImage]
                                     placeholderImage:defaultProfileImage
                                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
            {
                userModel.cachedProfileImage = image;
            }];
        }
        else {
            self.profileImageView.image = defaultProfileImage;
            userModel.cachedProfileImage = defaultProfileImage;
        }
    }
}


- (void)updateTopicInfo
{
    self.pollIcon.hidden = !self.topic.isPoll;
    self.titleLabel.text = !self.topic.isPoll ? self.topic.title : [NSString stringWithFormat:@"    %@", self.topic.title];
    
    // topic description
    self.descLabel.hidden = ![ForumTopicCell shouldShowTopicDescriptionForTopic:self.topic];
    self.quizButton.hidden = !self.topic.isQuiz;
    if (!self.descLabel.hidden || !self.quizButton.hidden) {
        self.topicDescTopConstraint.constant = kTopicInfoElementPadding;
        self.descLabel.text = self.topic.desc;
    }
    else {
        self.topicDescTopConstraint.constant = -self.descLabel.height;
    }
    
    // topic stat
    self.topicSummaryLabel.hidden = ![ForumTopicCell shouldShowTopicStatForTopic:self.topic];
    if (!self.topicSummaryLabel.hidden) {
        self.topicSummaryLabel.text = [self makeTopicStatText];
    }
    
    // topic photo or quiz containing image
    if ((self.topic.isPhotoTopic || self.topic.isQuiz) && self.topic.thumbnail.length > 0) {
        self.thumbnailView.hidden = NO;
        self.thumbnailImageView.image = nil;
        NSURL *url = [NSURL URLWithString:self.topic.thumbnail];
        
        if (self.topic.hasImproperContent) {
            self.warningOverlay.hidden = NO;
            @weakify(self)
            [self.thumbnailImageView sd_setImageWithURL:url
                                              completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
            {
                @strongify(self)
                UIImage *blurredImage = [image applyBlurWithRadius:5.0 tintColor:nil saturationDeltaFactor:1.0 maskImage:nil];
                self.thumbnailImageView.image = blurredImage;
            }];
        }
        else {
            self.warningOverlay.hidden = YES;
            [self.thumbnailImageView sd_setImageWithURL:url];
        }
        
        self.topicTitleTopConstraint.constant = 4;
        self.topicInfoTextLeftConstraint.constant = 98;
    }
    else {
        self.thumbnailView.hidden = YES;
        self.topicTitleTopConstraint.constant = 0;
        self.topicInfoTextLeftConstraint.constant = 0;
    }
}


- (void)updateUrlCard:(ForumTopic *)topic
{
    self.urlPreviewCard.hidden = NO;
    
    self.urlPreviewCardTitle.text = self.topic.urlTitle;
    self.urlPreviewCardDesc.text = self.topic.urlAbstract;
    self.urlPreviewCardUrl.text = self.topic.urlPath?: self.topic.content?: self.topic.desc;
    
    self.urlPreviewCardThumbnail.hidden = YES;
    
    if  ([NSString isNotEmptyString:self.topic.thumbnail]) {
        @weakify(self)
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.topic.thumbnail]
                                                        options:0
                                                       progress:nil
                                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
         {
             @strongify(self)
             if (image) {
                 self.urlPreviewCardThumbnail.image = image;
                 self.urlPreviewCardThumbnail.hidden = NO;
                 self.urlTextLeftConstraint.constant = 68;
             }
             
         }];
    }
    else {
        self.urlTextLeftConstraint.constant = 8;
    }
}


- (NSString *)makeTopicStatText
{
    NSString *firstPart = [self countStringForSubject:@"upvote" count:self.topic.countLikes];
    NSString *secondPart = [self countStringForSubject:@"response" count:self.topic.countReplies];
    
    if (self.topic.isPoll && self.topic.pollOptions.totalVotes > 0) {
        firstPart = [self countStringForSubject:@"vote" count:self.topic.pollOptions.totalVotes];
    }
    
    if (firstPart && secondPart) {
        return [NSString stringWithFormat:@"%@ • %@", firstPart, secondPart];
    }
    else if (firstPart || secondPart) {
        return firstPart ? firstPart : secondPart;
    }
    return @"";
}


- (NSString *)countStringForSubject:(NSString *)subject count:(NSInteger)count
{
    if (count == 0) {
        return nil;
    }
    else if (count > 1) {
        subject = [subject stringByAppendingString:@"s"];
    }
    return [NSString stringWithFormat:@"%ld %@", (long)count, subject];
}


- (IBAction)didClickGroup:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:gotoGroup:)] && self.group) {
        [Forum log:BTN_CLK_FORUM_CELL_GO_GROUP eventData:@{@"group_id": @(self.group.identifier)}];
        [self.delegate cell:self gotoGroup:self.group];
    }
}


- (void)handleLongPress:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateBegan) {
        if ([Forum isLoggedIn] && [Forum currentForumUser].identifier == self.topic.userId) {
            [self presentEditActionSheet];
        } else {
            [self didClickHideButton:nil];
        }
    }
}

- (void)presentEditActionSheet {
    
    if ([self.delegate respondsToSelector:@selector(cell:editTopic:)] && self.topic) {

    @weakify(self)
    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:nil];
    [as bk_addButtonWithTitle:@"Edit this post" handler:^{
        @strongify(self)
        if ([self.delegate respondsToSelector:@selector(cell:editTopic:)] && self.topic) {
            [self.delegate cell:self editTopic:self.topic];
        }
    }];
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [as showInView:self];
        
    }
}


- (IBAction)didClickShowContentButton:(id)sender
{
    self.topic.didUnlockLowRatingContent = YES;
    if ([self.delegate respondsToSelector:@selector(cell:showLowRatingContent:)]) {
        [self.delegate cell:self showLowRatingContent:self.topic];
        [self updateViewsVisibility];
    }
}


- (IBAction)didClickViewRulesButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:showRules:)]) {
        [self.delegate cell:self showRules:self.topic];
    }
}


- (IBAction)didClickHideButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:hideTopic:)] && self.topic && [self.delegate respondsToSelector:@selector(cell:reportTopic:)]) {
        
        UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:nil];
        
        if ([self.delegate respondsToSelector:@selector(cell:hideTopic:)] && self.topic) {
            
            [as bk_addButtonWithTitle:@"Hide this post" handler:^{
                [Forum log:BTN_CLK_FORUM_CELL_HIDE_TOPIC eventData:@{@"topic_id": @(self.topic.identifier)}];
                [self.delegate cell:self hideTopic:self.topic];
            }];
        }
        
        if ([self.delegate respondsToSelector:@selector(cell:reportTopic:)] && self.topic) {
            [as bk_addButtonWithTitle:@"Report this post" handler:^{
                [Forum log:BTN_CLK_FORUM_CELL_REPORT_TOPIC eventData:@{@"topic_id": @(self.topic.identifier)}];
                [self.delegate cell:self reportTopic:self.topic];
            }];
        }
        [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [as showInView:self];
        
    }
}


- (IBAction)showUserProfile:(id)sender
{
    if (self.isProfileTopic) {
        return;
    }
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    
    uint64_t userid = self.topic.countReplies > 0 ? self.topic.replier.identifier : self.topic.author.identifier;
    [Forum log:BTN_CLK_FORUM_TOPIC_USER_NAME eventData:@{@"user_id": @(userid)}];
    
    if ([self.delegate respondsToSelector:@selector(cell:showProfileForUser:)]) {
        if (self.topic.countReplies > 0) {
            [self.delegate cell:self showProfileForUser:self.topic.replier];
        }
        else {
            if (![self.topic isAnonymous]) {
                [self.delegate cell:self showProfileForUser:self.topic.author];
            }
        }
    }
}


- (IBAction)urlCardClicked:(id)sender
{
    if (self.topic.isURLTopic) {
        NSString *url = self.topic.urlPath ? : (self.topic.content?: self.topic.desc);
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            url = [@"http://" stringByAppendingString:url];
        }
        
        if ([self.delegate respondsToSelector:@selector(cell:presentUrlPage:)]) {
            [self.delegate cell:self presentUrlPage:url];
        } else {
            [self publish:EVENT_FORUM_CLICK_URL_TOPIC_CARD data:url];
        }
    }
}

- (IBAction)didClickQuizButton:(id)sender {
    if (self.topic.isQuiz) {
        [self publish:EVENT_FORUM_TAKE_QUIZ data:self.topic];
    }
}

@end

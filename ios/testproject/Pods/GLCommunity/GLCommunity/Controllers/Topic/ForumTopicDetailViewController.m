//
//  ForumTopicDetailViewController.m
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import "UINavigationBar+Awesome.h"
#import <Masonry/Masonry.h>
#import <BlocksKit/UIAlertView+BlocksKit.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLWebViewController.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/GLCameraViewController.h>

#import "ForumTopicDetailViewController.h"
#import "ForumAddReplyViewController.h"
#import "ForumCommentViewController.h"
#import "ForumReplyCell.h"
#import "ForumProfileViewController.h"
#import "ForumPollViewController.h"
#import "CMPopTipView+Glow.h"

#import "ForumAddTopicViewController.h"
#import "ForumAddPollViewController.h"
#import "ForumAddPhotoViewController.h"
#import "ForumAddURLViewController.h"
#import "ForumQuizViewController.h"
#import "ForumTopicHeader.h"

#define REPLY_CELL_IDENTIFIER    @"ForumReplyCell"
#define NO_RESPONSE_CELL_IDENTIFIER    @"NoResponseCell"
#define LOADING_CELL_IDENTIFIER    @"LoadingCell"

@interface ForumTopicDetailViewController () <MWPhotoBrowserDelegate, CMPopTipViewDelegate>
{
    long _resizeCount;
}

@property (strong, nonatomic) NSMutableArray *replies;
@property (strong, nonatomic) IBOutlet ForumTopicHeader *headerView;
@property (assign, nonatomic) BOOL noMore;
@property (assign, nonatomic) BOOL fetching;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *btnAddComment;
@property (strong, nonatomic) CMPopTipView *popTipView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *bookmarkButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadingButtonItem;
@property (strong, nonatomic) NSMutableDictionary *rowHeightCache;
@property (strong, nonatomic) NSMutableDictionary *contentHeightCache;
@property (strong, nonatomic) NSTimer *reloadTimer;

@property (strong, nonatomic) NSArray *photosToShow;
@property (nonatomic) ForumPollViewController * pollViewController;

@property (nonatomic, assign) NSUInteger repliesOffset;
@property (strong, nonatomic) ForumReply *flaggingReply;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomSpace;

@property (strong, nonatomic) UITapGestureRecognizer *gr;

@property (nonatomic, assign, readonly) BOOL shouldShowEntireDiscussion;
@property (nonatomic, assign) BOOL didClickShowEntireDiscussion;

@end

@implementation ForumTopicDetailViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"topicDetail"];
}

- (NSMutableArray *)replies
{
    if (!_replies) {
        _replies = [NSMutableArray array];
    }
    return _replies;
}

- (NSMutableDictionary *)rowHeightCache
{
    if (!_rowHeightCache) {
        _rowHeightCache = [NSMutableDictionary dictionary];
    }
    return _rowHeightCache;
}

- (NSMutableDictionary *)contentHeightCache
{
    if (!_contentHeightCache) {
        _contentHeightCache = [NSMutableDictionary dictionary];
    }
    return _contentHeightCache;
}


- (BOOL)shouldShowEntireDiscussion
{
    if (self.replyId == 0) {
        return YES;
    }
    
    return self.didClickShowEntireDiscussion;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.topic.title;
    self.navigationItem.title = self.topic.title;
    
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    self.loadingButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingView];
    
    UIImage *bookmarkImg = [UIImage imageNamed:@"gl-community-bookmark"];
    UIImage *bookmarkImgPressed = [UIImage imageNamed:@"gl-community-bookmark-selected"];
    
    UIImage *closeImg = [UIImage imageNamed:@"gl-community-topnav-close"];
    UIImage *closeImgPressed = [UIImage imageNamed:@"gl-community-topnav-close-press"];
    
    SEL leftButtonAction = nil;
    UIImage *leftImg = nil;
    UIImage *leftImgPressed = nil;
    
    if (self.navigationController.viewControllers.count > 1) {
        GLLog(@"Use default back style");
    } else {
        leftImg = closeImg;
        leftImgPressed = closeImgPressed;
        leftButtonAction = @selector(dismissSelf:);
    }

    if (leftButtonAction) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:leftImg
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self action:leftButtonAction];
    }
    self.bookmarkButtonItem = [[UIBarButtonItem alloc] initWithImage:bookmarkImg
                                                               style:UIBarButtonItemStylePlain
                                                              target:self
                                                              action:@selector(toggleBookmarked:)];
    
    UIButton *customButton = [UIButton buttonWithType:UIButtonTypeCustom];
    customButton.frame = CGRectMake(0, 0, 30.0, 39.0);
    if (self.category) {
        [customButton setImage:bookmarkImg forState:UIControlStateNormal];
    }
    else {
        [customButton setImage:[bookmarkImg imageWithTintColor:UIColorFromRGB(0x5b62d2)] forState:UIControlStateNormal];
    }
    [customButton setImage:bookmarkImgPressed forState:UIControlStateHighlighted];
    [customButton setImage:bookmarkImgPressed forState:UIControlStateSelected];
    [customButton addTarget:self action:@selector(toggleBookmarked:) forControlEvents:UIControlEventTouchUpInside];
    self.bookmarkButtonItem = [[UIBarButtonItem alloc] initWithCustomView:customButton];
    
    [[NSBundle mainBundle] loadNibNamed:@"ForumTopicHeader" owner:self options:nil];
    self.tableView.tableHeaderView = self.headerView;
    self.headerView.contentView.delegate = self;
    self.tableView.scrollsToTop = YES;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumReplyCell" bundle:nil] forCellReuseIdentifier:REPLY_CELL_IDENTIFIER];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 22)];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    self.btnAddComment.layer.cornerRadius = 19.0;
    self.bottomView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.bottomView.layer.shadowOpacity = 0.25;
    self.bottomView.layer.shadowRadius = 1.0;
   
    [self updateCommentSection];
    
    [self.headerView.contentView.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
    
    [self fillTopicData];
    if (self.title.length == 0) {
        self.title = @"Loading...";
    }
    [self subscribeEvents];
    [self refreshData:nil];

    self.gr = [[UITapGestureRecognizer alloc ] initWithTarget:self action:@selector(tapped:)];
    [self.gr setNumberOfTapsRequired:1];
    [self.gr setDelaysTouchesBegan:YES];
    [self.headerView.urlPreviewCard addGestureRecognizer:self.gr];
    
}

- (BOOL)needsHideCommentSection {
    return !self.topic || self.hideComments || self.topic.isNoComment;
}

- (void)updateCommentSection {
    if (self.topic.isQuiz) {
        [self.btnAddComment setTitle:NSLocalizedString(@"Take This Quiz!", nil) forState:UIControlStateNormal];
    } else {
        [self.btnAddComment setTitle:NSLocalizedString(@"Add a comment", nil) forState:UIControlStateNormal];
    }
    self.bottomView.hidden = self.needsHideCommentSection;
    self.btnAddComment.hidden = self.needsHideCommentSection;
    
    self.headerView.likeButton.hidden = self.needsHideCommentSection;
    self.headerView.shareButton.hidden = self.needsHideCommentSection;
    self.headerView.flagButton.hidden = self.needsHideCommentSection;
    self.headerView.dislikeButton.hidden = self.needsHideCommentSection;
    
    self.bottomSpace.constant = self.needsHideCommentSection? 0.0: 30;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)viewDidLayoutSubviews
{
    self.bottomView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bottomView.bounds].CGPath;
}

- (void)subscribeEvents
{
    @weakify(self)
    [self subscribe:EVENT_FORUM_ADD_REPLY_SUCCESS handler:^(Event *event) {
        @strongify(self)
        ForumTopic *topic = (ForumTopic *)event.data;
        if ([topic isKindOfClass:[ForumTopic class]] && topic.identifier == self.topic.identifier) {
            [self refreshData:nil];
        }
    }];
    [self subscribe:EVENT_FORUM_ADD_SUBREPLY_SUCCESS handler:^(Event *event) {
        @strongify(self)
        ForumReply *newReply = (ForumReply *)event.data;
        if ([newReply isKindOfClass:[ForumReply class]] && newReply.topicId == self.topic.identifier) {
            for (ForumReply *reply in self.replies) {
                if (reply.identifier == newReply.replyTo) {
                    reply.countReplies += 1;
                    NSMutableArray *newReplies = [reply.replies mutableCopy];
                    if (newReplies.count >= 3) {
                        [newReplies removeLastObject];
                    }
                    [newReplies insertObject:newReply atIndex:0];
                    reply.replies = [newReplies copy];
                    NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
                    [self.rowHeightCache removeObjectForKey:cacheKey];
                    [self.contentHeightCache removeObjectForKey:cacheKey];
                    [UIView setAnimationsEnabled:NO];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[self.replies indexOfObject:reply] inSection:0];
                    ForumReplyCell *cell = (ForumReplyCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                    if ([cell isKindOfClass:[ForumReplyCell class]]) {
                        cell.reply = reply;
                    }
                    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                    [UIView setAnimationsEnabled:YES];
                    break;
                }
            }
        }
    }];
    [self subscribe:EVENT_FORUM_POLL_OPTION_VOTE selector:@selector(pollVoteSuccess:)];
    [self subscribe:EVENT_FORUM_REPLY_REMOVED selector:@selector(replyRemoved:)];
    [self subscribe:EVENT_FORUM_DID_HIDE_REPLY handler:^(Event *event) {
        @strongify(self)
        [self.tableView reloadData];
    }];
    
    [self subscribe:EVENT_FORUM_TOPIC_UPDATED handler:^(Event *event) {
        @strongify(self)
        [self refreshData:nil];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateCommentSection];
    if (!self.needsHideCommentSection) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    NSString *source = self.source ?: IOS_TOPIC_VIEW_FROM_FORUM;
    
    [Forum log:PAGE_IMP_FORUM_TOPIC eventData:@{@"topic_id": @(self.topic.identifier), @"group_id": @(self.topic.groupId), @"page_source": source}];

    if (self.topic.isWelcomeTopic) {
        self.popTipView = [[CMPopTipView alloc] initWithMessage:@"Say hi!"];
        self.popTipView.delegate = self;
        [self.popTipView customize];

        @weakify(self)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self)
            [self.popTipView presentPointingAtView:self.btnAddComment inView:self.view animated:YES];
            self.topic.isWelcomeTopic = NO;
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.popTipView) {
        [self.popTipView dismissAnimated:YES];
    }
}

- (void)dealloc
{
    if (self.articleId > 0)
    {
        [self publish:EVENT_FORUM_ARTICLE_DID_READ data:self.topic];
    }
    [self unsubscribeAll];
    [self.headerView.contentView.scrollView removeObserver:self forKeyPath:@"contentSize"];
    self.tableView.delegate = nil;
}

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
}

- (IBAction)didClickOnName:(id)sender {
    if (![self.topic isAnonymous] && self.topic.author) {
        if (![Forum isLoggedIn]) {
            [Forum actionRequiresLogin];
            return;
        }
        ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:self.topic.author.identifier
                                                                            placeholderUser:self.topic.author];
        [self.navigationController pushViewController:vc animated:YES];
    }
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
    BOOL toLike = !self.topic.liked;
    [Forum log:BTN_CLK_FORUM_TOPIC_LIKE_NEW eventData:@{@"topic_id": @(self.topic.identifier),
                                                        @"like": @(toLike),
                                                        @"group_id": @(self.topic.groupId)}];

    [self toggleLiked];
    self.headerView.dislikeButton.enabled = NO;
    [Forum markTopic:self.topic.identifier liked:self.topic.liked callback:^(NSDictionary *result, NSError *error) {
        if ([self handleCallbackResult:result error:error]) {
            [self toggleLiked];
        }
        self.headerView.dislikeButton.enabled = YES;
    }];
}

- (IBAction)didClickDislikeButton:(id)sender
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    
    BOOL toDislike = !self.topic.disliked;
    [Forum log:BTN_CLK_FORUM_TOPIC_DISLIKE_NEW eventData:@{@"topic_id": @(self.topic.identifier),
                                                           @"dislike": @(toDislike),
                                                           @"group_id": @(self.topic.groupId)}];
    
    [self toggleDisliked];
    self.headerView.likeButton.enabled = NO;
    [Forum markTopic:self.topic.identifier disliked:self.topic.disliked callback:^(NSDictionary *result, NSError *error) {
        if ([self handleCallbackResult:result error:error]) {
            // if error, we need rollback
            [self toggleDisliked];
        }
        self.headerView.likeButton.enabled = YES;
    }];
}


- (IBAction)didClickShareButton:(id)sender {
    // logging
    [Forum log:BTN_CLK_FORUM_TOPIC_SHARE eventData:@{@"topic_id": @(self.topic.identifier),
                                                     @"group_id": @(self.topic.groupId)}];
    // open email page
    [Forum shareTopicWithObject:self.topic];
}

- (IBAction)didClickFlagButton:(id)sender {
    if ([Forum currentForumUser].identifier == self.topic.userId) {
        [self presentEditActionSheet];
    } else {
        [self presentHideAndReportActionSheet];
    }
}

- (void)presentEditActionSheet {
    @weakify(self)
    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:nil];
    [as bk_addButtonWithTitle:@"Edit this post" handler:^{
        @strongify(self)
        
        if (self.topic.isPoll && self.topic.pollOptions.isVoted) {
            [UIAlertView bk_showAlertViewWithTitle:@"Can not edit this Post"
                                           message:@"You can not edit this post because it has been voted."
                                 cancelButtonTitle:@"OK"
                                 otherButtonTitles:nil
                                           handler:nil];
            return;
        }
        
        [self editTopic];
    }];
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [as showInView:self.view];
}

- (void)presentHideAndReportActionSheet {
    @weakify(self)
    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:nil];
    [as bk_addButtonWithTitle:@"Hide this post" handler:^{
        @strongify(self)
        [self didClickHideButton:nil];
    }];
    [as bk_addButtonWithTitle:@"Report this post" handler:^{
        @strongify(self)
        if (self.topic) {
            [Forum reportTopic:self.topic.identifier];
        }
    }];
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
    [as showInView:self.view];
}

- (void)editTopic {
    GLLog(@"edit topic: %@", self.topic);
    
    if (!self.topic) {
        return;
    }
    
    UIViewController *vc  = nil;
    if (self.topic.isURLTopic) {
        vc =  [ForumAddURLViewController viewController];
        ((ForumAddURLViewController *)vc).topic = self.topic;
    } else if (self.topic.isPhotoTopic) {
        vc = [ForumAddPhotoViewController viewController];
        ((ForumAddPhotoViewController *)vc).topic = self.topic;
    } else if (self.topic.isPoll) {
        vc = [ForumAddPollViewController viewController];
        ((ForumAddPollViewController *)vc).topic = self.topic;
    } else {
        vc = [ForumAddTopicViewController viewController];
        ((ForumAddTopicViewController *)vc).topic = self.topic;
    }
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];

}

- (IBAction)didClickHideButton:(id)sender {
    @weakify(self)
    UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Would you like to hide this topic?"];
    [alert bk_addButtonWithTitle:@"Yes, hide it." handler:^{
        @strongify(self)
        [Forum hideTopic:self.topic.identifier];
        [self publish:EVENT_FORUM_DID_HIDE_TOPIC data:@(self.topic.identifier)];
        [self.navigationController popViewControllerAnimated:YES];
    }];
    [alert bk_setCancelButtonWithTitle:@"No" handler:nil];
    [alert show];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.headerView.contentView.scrollView) {
        _resizeCount++;
        if (_resizeCount > 100) {
            [self.headerView.contentView.scrollView removeObserver:self forKeyPath:@"contentSize"];
            return;
        }
        [self.headerView layoutSubviews];
        self.tableView.tableHeaderView = self.headerView;
    }
}

- (IBAction)goBack:(id)sender
{
    if ([self.navigationController.viewControllers lastObject] == self) {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (IBAction)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)tapped:(UIGestureRecognizer *)sender {
    if (self.topic.isURLTopic) {
        GLWebViewController *controller = [GLWebViewController viewController];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
        [self presentViewController:nav animated:YES completion:nil];
        
        NSString *url = self.topic.urlPath?: self.topic.content?:@"";
        if (![url hasPrefix:@"http://"] && ![url hasPrefix:@"https://"]) {
            url = [@"http://" stringByAppendingString:url];
        }
        [controller openUrl:url];
    }
}

- (IBAction)showEntireDiscussionClicked:(id)sender
{
    self.didClickShowEntireDiscussion = YES;
    self.headerView.shouldShowEntireDiscussion = YES;
    [self refreshData:nil];
    [self.tableView reloadData];
}


- (void)showNetworkingError
{
    [UIAlertView bk_showAlertViewWithTitle:@"Oops..."
                                   message:@"Failed to fetch the topic and replies, please try later."
                         cancelButtonTitle:@"OK"
                         otherButtonTitles:nil
                                   handler:^(UIAlertView *alertView, NSInteger buttonIndex)
    {
        
    }];
    self.headerView.hidden = YES;
}

- (IBAction)refreshData:(id)sender
{
    if ((0 == self.topic.content.length) && (!self.topic.isPoll)) {
        [self.headerView.loadingIndicator startAnimating];
    }
    if (!self.fetching) {
        GLLog(@"Refreshing data...");
        self.fetching = YES;
        self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
        @weakify(self)
        
        // from notification or profile
        if (!self.shouldShowEntireDiscussion) {
            self.noMore = YES;
            @strongify(self)
            [Forum fetchReplyForNotification:self.replyId callback:^(NSDictionary *result, NSError *error) {
                self.navigationItem.rightBarButtonItem = self.bookmarkButtonItem;
                
                if (!error && [result isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *topicDict = [result objectForKey:@"topic"];
                    self.topic = [[ForumTopic alloc] initWithDictionary:topicDict];
                    
                    NSArray *repliesArray = [result objectForKey:@"replies"];
                    [self appendRepliesFromJSONArray:repliesArray];
                    
                    // force to show entire discussion upon the response from server
                    self.didClickShowEntireDiscussion = [[result objectForKey:@"show_entire_discussion"] boolValue];
                    
                    [self fillTopicData];
                }
                else {
                    [self showNetworkingError];
                }
                [self.headerView.loadingIndicator stopAnimating];
                self.fetching = NO;
            }];
            return;
        }
        
        void (^cb)(NSDictionary *result, NSError *err) = ^(NSDictionary *result, NSError *error) {
            @strongify(self)
            self.navigationItem.rightBarButtonItem = self.bookmarkButtonItem;
            if (!error && [result isKindOfClass:[NSDictionary class]]) {
                NSDictionary *topicDict = [result objectForKey:@"topic"];
                ForumTopic *newTopic = [[ForumTopic alloc] initWithDictionary:topicDict];
                if (self.articleId > 0) {
                    newTopic.articleID = self.articleId;
                    if (self.topic.title.length > 0) {
                        newTopic.title = self.topic.title;
                    }
                    if (self.topic.content.length > 0) {
                        newTopic.content = self.topic.content;
                    }
                    self.topic = newTopic;
                    [self fillTopicData];
                } else {
                    if ((self.topic.identifier == newTopic.identifier) && ((newTopic.content.length > 0) || (newTopic.isPoll) || (newTopic.isPhotoTopic))) {
                        newTopic.isWelcomeTopic = self.topic.isWelcomeTopic;
                        self.topic = newTopic;
                        [self fillTopicData];
                    }
                }
                NSArray *repliesArray = [result objectForKey:@"replies"];
                if ([repliesArray isKindOfClass:[NSArray class]]) {
                    unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                    self.repliesOffset += pageSize;
                    self.noMore = pageSize > repliesArray.count;
                    [self.replies removeAllObjects];
                    [self appendRepliesFromJSONArray:repliesArray];
                }
            }
            else {
                [self showNetworkingError];
            }
            
            [self.headerView.loadingIndicator stopAnimating];
            self.fetching = NO;
        };
        if (self.articleId > 0) {
            [Forum fetchRepliesForArticle:self.articleId lastReplyTime:0 callback:cb];
        }
        else {
            [Forum fetchRepliesForTopic:self.topic.identifier offset:0 callback:cb];
        }
    }
}

- (IBAction)loadMore:(id)sender
{
    if ((0 == self.topic.content.length) && (!self.topic.isPoll)) {
        [self.headerView.loadingIndicator startAnimating];
    }
    if (!self.fetching && !self.noMore) {
        GLLog(@"Loading more...");
        self.fetching = YES;
        ForumReply *lastReply = [self.replies lastObject];
        @weakify(self)
        void (^cb)(NSDictionary *result, NSError *err) = ^(NSDictionary *result, NSError *error) {
            @strongify(self)
            if (!error) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *topicDict = [result objectForKey:@"topic"];
                    ForumTopic *newTopic = [[ForumTopic alloc] initWithDictionary:topicDict];
                    if (self.articleId > 0) {
                        self.topic.bookmarked = newTopic.bookmarked;
                        [self fillTopicData];
                    } else {
                        if ((self.topic.identifier == newTopic.identifier) && ((newTopic.content.length > 0) || (newTopic.isPoll))){
                            self.topic.content = newTopic.content;
                            self.topic.bookmarked = newTopic.bookmarked;
                            [self fillTopicData];
                        }
                    }
                    NSArray *repliesArray = [result objectForKey:@"replies"];
                    if ([repliesArray isKindOfClass:[NSArray class]]) {
                        NSUInteger pageSize = [[result objectForKey:@"page_size"] unsignedIntegerValue];
                        self.repliesOffset += pageSize;
                        self.noMore = pageSize > repliesArray.count;
                        [self appendRepliesFromJSONArray:repliesArray];
                    }
                }
            }
            [self.headerView.loadingIndicator stopAnimating];
            self.fetching = NO;
        };
        if (self.articleId > 0) {
            [Forum fetchRepliesForArticle:self.articleId lastReplyTime:lastReply.timeModified callback:cb];
        } else {
            [Forum fetchRepliesForTopic:self.topic.identifier offset:self.repliesOffset callback:cb];
        }
    }
}

- (void)appendRepliesFromJSONArray:(NSArray *)repliesArray
{
    BOOL foundNewReply = NO;
    for (NSDictionary *dict in repliesArray) {
        ForumReply *reply = [[ForumReply alloc] initWithDictionary:dict];
        BOOL exists = NO;
        
        // Test if the topic is already in the array
        if (self.replies.count > 0 && !foundNewReply) {
            NSInteger index = self.replies.count - 1;
            ForumTopic *testReply = [self.replies objectAtIndex:index];
            while (!exists && index >= 0 && reply.timeModified == testReply.timeModified) {
                if (reply.identifier == testReply.identifier) {
                    exists = YES;
                }
                index--;
                if (index >= 0) {
                    testReply = [self.replies objectAtIndex:index];
                }
            }
        }
        
        if (!exists) {
            foundNewReply = YES;
            [self.replies addObject:reply];
        }
    }
    [self.tableView reloadData];
}

- (void)fillTopicData
{
    [self checkBookmarkStatus];
    self.title = self.topic.title;
    self.navigationItem.title = self.topic.title;

    self.headerView.shouldShowEntireDiscussion = self.shouldShowEntireDiscussion;
    [self.headerView configureWithTopic:self.topic];
    
    // fill poll data before set layout
    [self fillPollData];

    [self.headerView layoutSubviews];
    [self.tableView setTableHeaderView:self.headerView];
    
    [self updateCommentSection];
}

- (void)fillPollData {
    if (!self.topic.isPoll) {
        self.headerView.pollContainer.hidden = YES;
        self.headerView.pollVoteTipLabel.hidden = YES;
        return;
    } else {
        self.headerView.pollContainer.hidden = NO;
        self.headerView.pollVoteTipLabel.hidden = NO;
    }
    // setup poll options, (in pollViewController)
    if (!self.pollViewController) {
        self.pollViewController = [[ForumPollViewController alloc] init];
        [self addChildViewController:self.pollViewController];
        [self.headerView.pollContainer removeAllSubviews];
        [self.headerView.pollContainer addSubview:self.pollViewController.view];
        [self.pollViewController.view mas_updateConstraints:^(MASConstraintMaker *maker){
            maker.edges.equalTo(self.headerView.pollContainer);
        }];
    }
    [self.pollViewController setModel:self.topic.pollOptions];
    [self.pollViewController refresh];
    // setup poll Vote Tips
    if (self.topic.pollOptions.isVoted) {
        self.headerView.pollVoteTipLabel.text = @"Thanks for participating!";
    } else {
        self.headerView.pollVoteTipLabel.text = @"Vote below to see results!";
    }
    
    // resize pollContainter fram
    self.headerView.pollContainer.height = self.pollViewController.view.frame.size.height;
}


- (IBAction)presentAddReplyViewController:(id)sender
{
    if (self.topic.isQuiz) {
        ForumQuizViewController *quizView = [ForumQuizViewController viewController];
        quizView.topicId = self.topic.identifier;
        [self presentViewController:quizView animated:YES completion:nil];
        [Forum log:BTN_CLK_FORUM_TAKE_QUIZ_FROM_TOPIC eventData:@{
            @"topic_id": @(self.topic.identifier),
        }];
    } else {
        ForumAddReplyViewController *addReplyViewController = [ForumAddReplyViewController viewController];
        addReplyViewController.topic = self.topic;
        UINavigationController *addReplyNavController = [[UINavigationController alloc] initWithRootViewController:addReplyViewController];
        addReplyNavController.navigationBar.translucent = NO;
        [self presentViewController:addReplyNavController animated:YES completion:nil];
    }
}

- (IBAction)toggleBookmarked:(id)sender
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    self.topic.bookmarked = !self.topic.bookmarked;
    [self checkBookmarkStatus];
    [Forum markTopic:self.topic.identifier bookmarked:self.topic.bookmarked callback:^(NSDictionary *result, NSError *error) {
        if (error) {
            self.topic.bookmarked = !self.topic.bookmarked;
        }
        else {
            if (self.topic.bookmarked) {
                [JDStatusBarNotification showWithStatus:@"Bookmarked!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
            }
            [self publish:EVENT_FORUM_TOPIC_BOOKMARKED data:self.topic];
        }
    }];
}

- (void)toggleLiked
{
    self.topic.liked = !self.topic.liked;
    int diff = self.topic.liked ? 1 : -1;
    self.topic.countLikes += diff;
    [Forum toggleLikedTopic:self.topic liked:self.topic.liked];
    [self.headerView updateCountLabel:self.topic];
    
    if (self.topic.liked && self.topic.disliked) {
        [self toggleDisliked];
    }
    
    [self.headerView updateLikeButtonInsetWithTopic:self.topic];
}


- (void)toggleDisliked
{
    self.topic.disliked = !self.topic.disliked;
    int diff = self.topic.disliked ? 1 : -1;
    self.topic.countDislikes += diff;
    self.headerView.dislikeButton.selected = self.topic.disliked;
    
    if (self.topic.disliked && self.topic.liked) {
        [self toggleLiked];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.needsHideCommentSection) {
        return 0;
    }
    if (section == 0) {
        return self.replies.count;
    }
    else if (section == 1) {
        return (self.noMore || self.replies.count == 0) ? 0 : 1;
    }
    else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        ForumReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:REPLY_CELL_IDENTIFIER forIndexPath:indexPath];
        replyCell.delegate = self;
        
        if (indexPath.row < self.replies.count) {
            ForumReply *reply = [self.replies objectAtIndex:indexPath.row];
            NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
            NSNumber *height = [self.contentHeightCache objectForKey:cacheKey];
            if (height) {
                [replyCell setContentHeight:[height floatValue]];
            } else {
                [replyCell setContentHeight:0];
            }
            int altIndex = 0;
            for (int i = 0; i < indexPath.row; ++i) {
                ForumReply *r = self.replies[i];
                if (![Forum isReplyHidden:r.identifier]) {
                    altIndex++;
                }
            }
            [replyCell setReply:reply];
            replyCell.alternative = (0 == altIndex % 2);
        }
        
        cell = replyCell;
    }
    else if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:LOADING_CELL_IDENTIFIER];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LOADING_CELL_IDENTIFIER];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [GLTheme defaultFont:18.0];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        for (UIView *view in cell.contentView.subviews) {
            [view removeFromSuperview];
        }
        UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [indicatorView startAnimating];
        indicatorView.hidden = NO;
        [cell.contentView addSubview:indicatorView];
        [indicatorView mas_updateConstraints:^(MASConstraintMaker *maker)
        {
            maker.center.equalTo(cell.contentView);
        }];
    }
    
    return cell;
}


- (void)delayedReload
{
    if (self.reloadTimer) {
        [self.reloadTimer invalidate];
    }
    self.reloadTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(doReload) userInfo:nil repeats:NO];
}

- (void)doReload
{
    [self.tableView reloadData];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.replies.count) {
            ForumReply *reply = [self.replies objectAtIndex:indexPath.row];
            
            if ([Forum isReplyHidden:reply.identifier]) {
                return 0.0;
            }
            
            NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
            NSNumber *heightNumber = [self.rowHeightCache objectForKey:cacheKey];
            
            if (heightNumber) {
                return [heightNumber floatValue];
            } else {
                CGFloat height = [ForumReplyCell cellHeightForReply:reply];
                [self.rowHeightCache setObject:@(height) forKey:cacheKey];
                return height;
            }
        }
    }
    return 44.0;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollDelegate scrollViewDidScroll:scrollView];
    }
    if (scrollView == self.tableView && !self.needsHideCommentSection) {
        CGFloat y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom;
        if (y > scrollView.contentSize.height - scrollView.bounds.size.height / 3.0) {
            [self loadMore:nil];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.scrollDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.scrollDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView) {
        return YES;
    }
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.category) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

#pragma mark - MWPhotoBrowserDelegate
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.photosToShow.count;
}

- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    if (index < self.photosToShow.count)
        return [self.photosToShow objectAtIndex:index];
    return nil;
}


#pragma mark - Forum Reply Cell Delegate
- (void)cell:(ForumReplyCell *)cell didClickFlagButtonForReply:(ForumReply *)reply
{
    if (reply) {
        [Forum reportReply:reply.identifier ofTopic:reply.topicId];
    }
}

- (void)cell:(ForumReplyCell *)cell didClickHideButtonForReply:(ForumReply *)reply
{
    if (reply) {
        @weakify(self)
        UIAlertView *alert = [UIAlertView bk_alertViewWithTitle:@"Are you sure to hide this comment?"];
        [alert bk_addButtonWithTitle:@"Yes, hide it." handler:^{
            @strongify(self)
            [Forum hideReply:reply.identifier];
            [self publish:EVENT_FORUM_DID_HIDE_REPLY data:@(reply.identifier)];
        }];
        [alert bk_setCancelButtonWithTitle:@"No" handler:nil];
        [alert show];
    }
}

- (void)cell:(ForumReplyCell *)cell showImagesWithURL:(NSArray *)array fromIndex:(NSUInteger)index
{
    NSMutableArray *photos = [NSMutableArray array];
    for (id urlOrStr in array)
    {
        NSURL *url;
        if ([urlOrStr isKindOfClass:[NSURL class]])
        {
            url = urlOrStr;
        }
        else if ([urlOrStr isKindOfClass:[NSString class]])
        {
            url = [NSURL URLWithString:urlOrStr];
        }
        [photos addObject:[MWPhoto photoWithURL:url]];
    }
    self.photosToShow = photos;
    
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    [browser setCurrentPhotoIndex:index];
    //browser.displayActionButton = YES; // Show action button to allow sharing, copying, etc (defaults to YES)
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
    
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)cell:(ForumReplyCell *)cell didClickShowHiddenContentForReply:(ForumReply *)reply
{
    NSInteger row = [self.replies indexOfObject:reply];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];

    NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
    [self.rowHeightCache removeObjectForKey:cacheKey];
    
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}


- (void)cell:(ForumReplyCell *)cell showRules:(ForumReply *)reply
{
    ForumTopic *topic = [[ForumTopic alloc] init];
    topic.identifier = FORUM_RULES_TOPIC_ID;
    topic.title = @"Community rules";
    
    ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
    topicViewController.source = IOS_TOPIC_VIEW_FROM_COMMUNITY_RULES;
    topicViewController.topic = topic;
    topicViewController.hideComments = YES;
    [self.navigationController pushViewController:topicViewController animated:YES];
}


- (void)cell:(ForumReplyCell *)cell heightDidChange:(CGFloat)height
{
    ForumReply *reply = cell.reply;
    NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
    NSNumber *oldNumber = [self.rowHeightCache objectForKey:cacheKey];
    if (!oldNumber || [oldNumber floatValue] != height) {
        [self.rowHeightCache setObject:@(height) forKey:cacheKey];
        NSInteger row = [self.replies indexOfObject:reply];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)cell:(ForumReplyCell *)cell finalHeight:(CGFloat)height contentHeight:(CGFloat)contentHeight
{
    [self cell:cell heightDidChange:height];
    ForumReply *reply = cell.reply;
    NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
    NSNumber *contentHeightNumber = [NSNumber numberWithFloat:contentHeight];
    [self.contentHeightCache setObject:contentHeightNumber forKey:cacheKey];
}

- (void)cell:(ForumReplyCell *)cell showRepliesForReply:(ForumReply *)reply autoFocus:(BOOL)autoFocus
{
    //            ForumReply *reply = [self.replies objectAtIndex:indexPath.row];
    ForumCommentViewController *commentView = [ForumCommentViewController viewController];
    commentView.reply = reply;
    commentView.category = self.category;
    commentView.topic = self.topic;
    commentView.beginEditWhenAppear = autoFocus;
    [self.navigationController pushViewController:commentView animated:YES from:self];
}

- (void)cell:(ForumReplyCell *)cell showProfileForUser:(ForumUser *)user
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
 
}

- (void)checkBookmarkStatus
{
    UIButton *button = (UIButton *)self.bookmarkButtonItem.customView;
    if ([button isKindOfClass:[UIButton class]]) {
        button.selected = self.topic.bookmarked;
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    GLLog(@"%@", request);
    NSString *scheme = [request.URL.scheme lowercaseString];
    if ([scheme isEqualToString:@"sizechanged"]) {
        [self.headerView layoutSubviews];
        self.tableView.tableHeaderView = self.headerView;
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"showimage"]) {
        NSString *str = request.URL.resourceSpecifier;
        str = [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        str = [str substringFromIndex:2];
        NSURL *url = [NSURL URLWithString:str];
        NSInteger index = [self.headerView.imgsURLStrings indexOfObject:str];
        if (index == NSNotFound)
        {
            [self cell:nil showImagesWithURL:@[url] fromIndex:0];
        }
        else
        {
            [self cell:nil showImagesWithURL:self.headerView.imgsURLStrings fromIndex:index];
        }
        GLLog(@"Should Show Image at %@",url);
        return NO;
    } else if ([request.URL.scheme isEqualToString:@"info"]) {
        NSString *info = request.URL.resourceSpecifier;
        info = [info stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        info = [info substringFromIndex:2];
        GLLog(@"Info %@", info);
        return NO;
    } else if (navigationType == UIWebViewNavigationTypeLinkClicked && ([scheme isEqualToString:@"http" ] || [scheme isEqualToString:@"https"])) {
        GLWebViewController *controller = [GLWebViewController viewController];
        [controller setHidesBottomBarWhenPushed:YES];
        // TODO, do we need add "from:self" here?
        [self.navigationController pushViewController:controller animated:YES from:self];
        [controller openUrl:request.URL.absoluteString];
        return NO;
    } else if ([scheme isEqualToString:FORUM_SCHEME_TOOLTIP]) {
        [Forum tip:request.URL.host];
        return NO;
    }
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    GLLog(@"Content did finish load");
}

- (void)setupNavigationBarAppearance
{
    if (self.category.backgroundColor) {
        [self.navigationController.navigationBar setBarTintColor:[UIColor colorFromWebHexValue:self.category.backgroundColor]];
        [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
        NSShadow *shadow = [[NSShadow alloc] init];
        shadow.shadowColor = [UIColor whiteColor];
        shadow.shadowOffset = CGSizeMake(0, 0);
        NSDictionary *attributes = @{
                                     NSFontAttributeName: [GLTheme semiBoldFont:24],
                                     NSForegroundColorAttributeName: [UIColor whiteColor],
                                     NSShadowAttributeName: shadow,
                                     };
        [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    }
}

#pragma mark - vote success callback
- (void)pollVoteSuccess:(Event *)event {
    // we should not put any complicated logic here
    // because, if user vote on home page, we will also get event
    self.headerView.pollVoteTipLabel.text = @"Thanks for participating!";
    [self.headerView updateCountLabel:self.topic];
}

#pragma mart -
- (void)replyRemoved:(Event *)event {
    NSDictionary * dict = (NSDictionary *)event.data;
    NSNumber * topicId = [dict objectForKey:@"topic_id"];
    NSNumber * replyId = [dict objectForKey:@"reply_id"];
    
    if ([topicId isEqualToNumber:@(self.topic.identifier)]) {
        ForumReply * removed = nil;
        for (ForumReply *reply in self.replies) {
            if ([replyId isEqualToNumber:@(reply.identifier)]) {
                removed = reply;
                break;
            }
        }
        if (removed) {
            [self.replies removeObject:removed];
            [self doReload];
        }
    }
}

@end

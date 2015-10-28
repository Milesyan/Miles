//
//  ForumCommentViewController.m
//  emma
//
//  Created by Allen Hsu on 12/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <MWFeedParser/NSString+HTML.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import "ForumCommentViewController.h"
#import "Forum.h"
#import "ForumReply.h"
#import "ForumReplyCell.h"
#import "ForumProfileViewController.h"
#import "ForumTopicDetailViewController.h"

#define kReplyMaxLength     300

#define REPLY_CELL_IDENTIFIER    @"ForumReplyCell"
#define NO_RESPONSE_CELL_IDENTIFIER    @"NoResponseCell"
#define LOADING_CELL_IDENTIFIER    @"LoadingCell"

#define SECTION_LOADING     0
#define SECTION_REPLIES     1
#define SECTION_NOMORE      2

@interface ForumCommentViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, ForumReplyCellDelegate>

@property (strong, nonatomic) NSMutableArray *replies;
@property (assign, nonatomic) BOOL noMore;
@property (assign, nonatomic) BOOL fetching;
@property (assign, nonatomic) BOOL notFirstTime;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *labelCounter;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIView *textFieldBackground;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *sendingIndicator;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableDictionary *rowHeightCache;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadingButtonItem;
@property (weak, nonatomic) IBOutlet UIView *originView;
@property (weak, nonatomic) IBOutlet UILabel *originLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *inputerBottomHeightLayout;
@end

@implementation ForumCommentViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"commentView"];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    self.tableView.delegate = nil;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.title = @"Replies";
    self.navigationItem.title = @"Replies";
    
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    self.loadingButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingView];
    
    self.bottomView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.bottomView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.bottomView.layer.shadowOpacity = 0.25;
    self.bottomView.layer.shadowRadius = 1.0;
    
    self.originView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.originView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.originView.layer.shadowOpacity = 0.25;
    self.originView.layer.shadowRadius = 1.0;
    
    
    self.textFieldBackground.layer.cornerRadius = 3.0;
    self.textFieldBackground.layer.masksToBounds = YES;
    self.textFieldBackground.layer.borderColor = [UIColor colorWithWhite:191.0/255.0 alpha:1.0].CGColor;
    self.textFieldBackground.layer.borderWidth = 1.0;
    
    self.textField.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollsToTop = YES;
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumReplyCell" bundle:nil] forCellReuseIdentifier:REPLY_CELL_IDENTIFIER];
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    UIImage *closeImg = [UIImage imageNamed:@"gl-community-topnav-close"];
    UIImage *closeImgPressed = [UIImage imageNamed:@"gl-community-topnav-close-press"];
    
    SEL leftButtonAction = nil;
    UIImage *leftImg = nil;
    UIImage *leftImgPressed = nil;
    
    if (self.navigationController.viewControllers.count > 1) {
        
    } else {
        leftImg = closeImg;
        leftImgPressed = closeImgPressed;
        leftButtonAction = @selector(dismissSelf:);
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:leftImg style:UIBarButtonItemStylePlain target:self action:leftButtonAction];
    }
    
//    if (![Forum isLoggedIn]) {
//        self.textField.placeholder = NSLocalizedString(@"You need to log in to reply", nil);
//        self.textField.enabled = NO;
//        self.btnSend.enabled = NO;
//    }
    
    [self reloadOriginalContent];
    [self refreshData:nil];
}

- (void)viewDidLayoutSubviews
{
    self.bottomView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bottomView.bounds].CGPath;
    self.originView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.originView.bounds].CGPath;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    if (self.beginEditWhenAppear) {
        [self.textField becomeFirstResponder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.textField resignFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (IBAction)goBack:(id)sender
{
    if ([self.navigationController.viewControllers lastObject] == self) {
        // we already checked here
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (IBAction)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.category) {
        return UIStatusBarStyleLightContent;
    } else {
        return UIStatusBarStyleDefault;
    }
}

#pragma mark - Load Data

- (void)reloadOriginalContent
{
    NSString *striped = [[[self.reply.content?: @"" stringByConvertingHTMLToPlainText]
                          stringByRemovingNewLinesAndWhitespace] stringByDecodingHTMLEntities];
    self.originLabel.text = [NSString stringWithFormat:@"Re: %@", striped];
}

- (IBAction)refreshData:(id)sender
{
    if (!self.fetching) {
        GLLog(@"Refreshing data...");
        self.fetching = YES;
        self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
        __weak ForumCommentViewController *weakSelf = self;
        [Forum fetchRepliesToReply:self.reply.identifier lastReplyTime:0 callback:^(NSDictionary *result, NSError *error) {
            self.navigationItem.rightBarButtonItem = nil;
            if (!error) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *origin = [result objectForKey:@"reply"];
                    if ([origin isKindOfClass:[NSDictionary class]]) {
                        ForumReply *reply = [[ForumReply alloc] initWithDictionary:origin];
                        if (reply) {
                            weakSelf.reply = reply;
                        }
                    }
                    NSArray *repliesArray = [result objectForKey:@"replies"];
                    if ([repliesArray isKindOfClass:[NSArray class]]) {
                        unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                        weakSelf.noMore = pageSize > repliesArray.count;
                        [weakSelf.replies removeAllObjects];
                        [weakSelf appendRepliesFromJSONArray:repliesArray];
                        CGFloat offsetY = MAX(-weakSelf.tableView.contentInset.top, weakSelf.tableView.contentSize.height - weakSelf.tableView.frame.size.height);
                        if (weakSelf.notFirstTime) {
                            [UIView animateWithDuration:0.3 animations:^{
                                [weakSelf.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:NO];
                            }];
                        } else {
                            [weakSelf.tableView setContentOffset:CGPointMake(0.0, offsetY)];
                        }
                        weakSelf.notFirstTime = YES;
                    }
                }
            }
            [weakSelf reloadOriginalContent];
            weakSelf.fetching = NO;
        }];
    }
}

- (IBAction)loadMore:(id)sender
{
    if (!self.fetching && !self.noMore) {
        GLLog(@"Loading more...");
        self.fetching = YES;
        ForumReply *lastReply = [self.replies lastObject];
        __weak ForumCommentViewController *weakSelf = self;
        [Forum fetchRepliesToReply:self.reply.identifier lastReplyTime:lastReply.timeCreated callback:^(NSDictionary *result, NSError *error) {
            if (!error) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    NSArray *repliesArray = [result objectForKey:@"replies"];
                    if ([repliesArray isKindOfClass:[NSArray class]]) {
                        unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                        weakSelf.noMore = pageSize > repliesArray.count;
                        CGFloat offsetToBottom = weakSelf.tableView.contentOffset.y - weakSelf.tableView.contentSize.height;
                        [weakSelf appendRepliesFromJSONArray:repliesArray];
                        [weakSelf.tableView setContentOffset:CGPointMake(0.0, offsetToBottom + weakSelf.tableView.contentSize.height) animated:NO];
                    }
                }
            }
            weakSelf.fetching = NO;
        }];
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
            while (!exists && index >= 0 && reply.timeCreated == testReply.timeCreated) {
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

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [self changeTextViewFrameWithKeyboardHeight:kbSize.height duration:[duration doubleValue] curve:[curve integerValue]];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    NSNumber *duration = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *curve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    [self changeTextViewFrameWithKeyboardHeight:0 duration:[duration doubleValue] curve:[curve integerValue]];
}

- (void)changeTextViewFrameWithKeyboardHeight:(CGFloat)kbHeight duration:(NSTimeInterval)duration curve:(NSInteger)curve
{
    GLLog(@"%f", kbHeight);
//    CGRect toolbarFrame = self.bottomView.frame;
//    toolbarFrame.origin.y = self.view.bounds.size.height - toolbarFrame.size.height - kbHeight;
//    CGRect tableViewFrame = self.tableView.frame;
//    tableViewFrame.size.height = toolbarFrame.origin.y - tableViewFrame.origin.y;
    
    BOOL animated = duration > 0.0;
    
    if (animated) {
        [UIView beginAnimations:@"showKeyboard" context:NULL];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:curve];
        [UIView setAnimationBeginsFromCurrentState:YES];
    }
    self.inputerBottomHeightLayout.constant = kbHeight;
    [self.view layoutIfNeeded];
//    self.bottomView.frame = toolbarFrame;
//    self.tableView.frame = tableViewFrame;
    
    if (kbHeight > 0.0) {
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        if ([visibleIndexPaths containsObject:[NSIndexPath indexPathForRow:self.replies.count - 1 inSection:SECTION_REPLIES]]) {
            CGFloat offsetY = MAX(-self.tableView.contentInset.top, self.tableView.contentSize.height - self.tableView.frame.size.height);
            [self.tableView setContentOffset:CGPointMake(0.0, offsetY) animated:NO];
        }
    }
    
    if (animated) {
        [UIView commitAnimations];
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = textField.text.length + string.length - range.length;
    BOOL shouldChange = (newLength > kReplyMaxLength) ? NO : YES;
    if (shouldChange) {
        self.labelCounter.text = [NSString stringWithFormat:@"%d", kReplyMaxLength - newLength];
    }
    return shouldChange;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendReply:textField];
    return NO;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.textField resignFirstResponder];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == SECTION_LOADING) {
        return self.noMore ? 0 : 1;
    } else if (section == SECTION_REPLIES) {
        return self.replies.count;
    } else if (section == SECTION_NOMORE) {
        return (self.noMore && self.replies.count == 0) ? 1 : 0;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == SECTION_LOADING) {
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
        indicatorView.center = CGPointMake(160.0, 22.0);
        indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        [indicatorView startAnimating];
        indicatorView.hidden = NO;
        [cell.contentView addSubview:indicatorView];
    } else if (indexPath.section == SECTION_REPLIES) {
        ForumReplyCell *replyCell = [tableView dequeueReusableCellWithIdentifier:REPLY_CELL_IDENTIFIER forIndexPath:indexPath];
        replyCell.delegate = self;
        
        if (indexPath.row < self.replies.count) {
            NSInteger index = self.replies.count - 1 - indexPath.row;
            ForumReply *reply = [self.replies objectAtIndex:index];
            [replyCell setReply:reply];
            replyCell.alternative = (0 == index % 2);
        }
        
        cell = replyCell;
    } else if (indexPath.section == SECTION_NOMORE) {
        cell = [tableView dequeueReusableCellWithIdentifier:NO_RESPONSE_CELL_IDENTIFIER];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NO_RESPONSE_CELL_IDENTIFIER];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [GLTheme defaultFont:18.0];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"No reply";
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == SECTION_REPLIES) {
        if (indexPath.row < self.replies.count) {
            ForumReply *reply = [self.replies objectAtIndex:self.replies.count - 1 - indexPath.row];
            return [ForumReplyCell cellHeightForReply:reply];
        }
    }
    return 44.0;
}

- (void)cell:(ForumReplyCell *)cell needUpdateHeightforReply:(ForumReply *)reply
{
    [self.tableView beginUpdates];
    NSInteger row = self.replies.count - 1 - [self.replies indexOfObject:reply];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:SECTION_REPLIES];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)cell:(ForumReplyCell *)cell didClickShowHiddenContentForReply:(ForumReply *)reply
{
    [self.tableView beginUpdates];
    NSInteger row = self.replies.count - 1 - [self.replies indexOfObject:reply];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:SECTION_REPLIES];
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

- (void)cell:(ForumReplyCell *)cell showProfileForUser:(ForumUser *)user
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [self.view endEditing:YES];
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView && self.notFirstTime) {
        CGFloat y = scrollView.contentOffset.y + scrollView.contentInset.top;
        if (y < 44.0) {
            [self loadMore:nil];
        }
    }
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

- (IBAction)sendReply:(id)sender {
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    if (self.reply.identifier > 0) {
        NSString *content = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *errMsg = nil;
        if (content.length == 0) {
            errMsg = @"Sorry, the content cannot be empty";
        } else if (content.length > kReplyMaxLength) {
            errMsg = @"Sorry, the content is too long";
        }
        if (errMsg != nil) {
            [[GLDropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
            return;
        }
        
        self.textField.enabled = NO;
        self.textField.textColor = [UIColor grayColor];
        self.sendingIndicator.hidden = NO;
        self.btnSend.hidden = YES;
        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
        [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        [Forum createReplyToReply:self.reply.identifier inTopic:self.reply.topicId withContent:content andImages:nil anonymously:NO callback:^(NSDictionary *result, NSError *error) {
            GLLog(@"create reply result: %@, error: %@", result, error);
            self.textField.enabled = YES;
            self.textField.textColor = [UIColor blackColor];
            self.sendingIndicator.hidden = YES;
            self.btnSend.hidden = NO;
            
            BOOL failed = NO;
            NSString *message = @"Failed to post the reply";
            NSInteger errCode = [result integerForKey:@"rc"];
            NSString *errMsg = [result stringForKey:@"msg"];
            if (error) {
                failed = YES;
            } else {
                if (errCode > 0) {
                    failed = YES;
                    if (errMsg) {
                        message = errMsg;
                    }
                } else {
                    if ([result isKindOfClass:[NSDictionary class] forKey:@"result"]) {
                        failed = NO;
                        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your reply is successfully posted!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
//                        [self publish:EVENT_FORUM_ADD_REPLY_SUCCESS data:self.topic];
                        // Fake reply to add to comment list
                        ForumUser *forumUser = [Forum currentForumUser];
                        
                        ForumReply *reply = [[ForumReply alloc] init];
                        reply.userId = forumUser.identifier;
                        reply.author = forumUser;
                        reply.replyTo = self.reply.identifier;
                        reply.topicId = self.reply.topicId;
                        reply.content = content;
                        
                        [self publish:EVENT_FORUM_ADD_SUBREPLY_SUCCESS data:reply];
                        self.textField.text = @"";
                        self.labelCounter.text = [NSString stringWithFormat:@"%d", kReplyMaxLength];
                        [self refreshData:nil];
                    } else {
                        failed = YES;
                    }
                }
            }
            
            if (failed) {
                [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
            }
        }];
    }
}

@end

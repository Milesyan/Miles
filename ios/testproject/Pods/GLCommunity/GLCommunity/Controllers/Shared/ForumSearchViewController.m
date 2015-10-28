//
//  ForumSearchViewController.m
//  emma
//
//  Created by Jirong Wang on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <Masonry/Masonry.h>
#import "ForumSearchViewController.h"
#import "ForumTopicCell.h"
#import "ForumReplyCell.h"
#import "ForumTopicDetailViewController.h"
#import "ForumProfileViewController.h"

#define LOADING_CELL_IDENTIFIER         @"LoadingCell"
#define NO_RESULT_CELL_IDENTIFIER       @"NoResultCell"

@interface ForumSearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate, ForumTopicCellDelegate, ForumReplyCellDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *searchTableView;

@property (strong, nonatomic) NSMutableArray *searchResults;
// need check below
@property (assign, nonatomic) BOOL fetching;
@property (assign, nonatomic) BOOL noMore;
@property (strong, nonatomic) NSString *keyword;

@property (strong, nonatomic) NSMutableDictionary *rowHeightCache;
@property (strong, nonatomic) NSMutableDictionary *contentHeightCache;

@property (assign, nonatomic) BOOL offset;

@end

@implementation ForumSearchViewController

- (BOOL)isInSearchMode
{
    return !self.view.hidden;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.searchBar.barTintColor = [UIColor whiteColor];
    self.searchBar.tintColor = GLOW_COLOR_PURPLE;
    self.searchBar.backgroundColor = [UIColor whiteColor];
    
    [self.searchTableView registerNib:[UINib nibWithNibName:@"ForumTopicCell" bundle:nil] forCellReuseIdentifier:TOPIC_CELL_IDENTIFIER];
    [self.searchTableView registerNib:[UINib nibWithNibName:@"ForumReplyCell" bundle:nil] forCellReuseIdentifier:REPLY_CELL_IDENTIFIER];
    self.searchTableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.searchTableView.separatorInset = UIEdgeInsetsZero;
    self.searchTableView.separatorColor = UIColorFromRGB(0xeceff1);
    self.searchTableView.tableFooterView = [[UIView alloc] init];

    self.view.hidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

#pragma mark - local variables

- (NSMutableArray *)searchResults
{
    if (!_searchResults) {
        _searchResults = [NSMutableArray array];
    }
    return _searchResults;
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.searchResults.count;
    } else if (section == 1) {
        BOOL hideLoading = (self.noMore || (self.keyword.length == 0));
        return hideLoading ? 0 : 1;
    } else if (section == 2) {
        return (!self.fetching && self.keyword.length > 0 && self.searchResults.count == 0) ? 1 : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.searchResults.count) {
            id data = [self.searchResults objectAtIndex:indexPath.row];
            if ([data isKindOfClass:[ForumTopic class]]) {
                ForumTopicCell *cell = [tableView dequeueReusableCellWithIdentifier:TOPIC_CELL_IDENTIFIER forIndexPath:indexPath];
                cell.delegate = self;
                [cell configureWithTopic:data isProfile:NO showGroup:NO showPinned:NO];
                return cell;
            }
            else if ([data isKindOfClass:[ForumReply class]]) {
                ForumReplyCell *cell = [tableView dequeueReusableCellWithIdentifier:REPLY_CELL_IDENTIFIER forIndexPath:indexPath];
                cell.delegate = self;
                cell.hideSubreplies = YES;
                [cell setReply:data];
                return cell;
            }
        }
    } else if (indexPath.section == 1) {
        UITableViewCell *cell = nil;
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
        indicatorView.hidden = NO;
        [cell.contentView addSubview:indicatorView];
        [indicatorView mas_updateConstraints:^(MASConstraintMaker *maker){
            maker.center.equalTo(cell.contentView);
        }];
        cell.backgroundColor = [UIColor whiteColor];
        cell.contentView.backgroundColor = [UIColor whiteColor];
        return cell;
    } else if (indexPath.section == 2) {
        UITableViewCell *cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:NO_RESULT_CELL_IDENTIFIER];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NO_RESULT_CELL_IDENTIFIER];
            cell.textLabel.textColor = [UIColor grayColor];
            cell.textLabel.font = [GLTheme defaultFont:18.0];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.textLabel.text = @"No result";
        cell.backgroundColor = [UIColor whiteColor];
        cell.contentView.backgroundColor = [UIColor whiteColor];
        return cell;
    }
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row < self.searchResults.count) {
            id data = [self.searchResults objectAtIndex:indexPath.row];
            if ([data isKindOfClass:[ForumTopic class]]) {
                return [ForumTopicCell cellHeightForTopic:data];
            } else if ([data isKindOfClass:[ForumReply class]]) {
                ForumReply *reply = data;
                NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
                NSNumber *heightNumber = [self.rowHeightCache objectForKey:cacheKey];
                
                if (heightNumber) {
                    return [heightNumber floatValue];
                } else {
                    CGFloat height = [ForumReplyCell cellHeightForReply:reply hideSubreplies:YES];
                    [self.rowHeightCache setObject:@(height) forKey:cacheKey];
                    return height;
                }
            }
            return TOPIC_CELL_HEIGHT_FULL;
        }
    }
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self resignSearchBar];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row < self.searchResults.count) {
            id data = [self.searchResults objectAtIndex:indexPath.row];
            if ([data isKindOfClass:[ForumTopic class]]) {
                ForumTopic *topic = data;
                ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
                detailViewController.source = IOS_TOPIC_VIEW_FROM_SEARCH_TOPIC;
                detailViewController.topic = topic;
                [self.navigationController pushViewController:detailViewController animated:YES from:self];
                [Forum log:BTN_CLK_FORUM_SEARCH_RESULT eventData:@{@"keyword": self.keyword ?: @"", @"topic_id": @(topic.identifier), @"result_index": @(indexPath.row)}];
            } else if ([data isKindOfClass:[ForumReply class]]) {
                ForumReply *reply = data;
                ForumTopicDetailViewController *detailViewController = [ForumTopicDetailViewController viewController];
                detailViewController.source = IOS_TOPIC_VIEW_FROM_SEARCH_REPLY;
                ForumTopic *topic = [[ForumTopic alloc] init];
                topic.identifier = reply.topicId;
                detailViewController.topic = topic;
                [self.navigationController pushViewController:detailViewController animated:YES from:self];
                [Forum log:BTN_CLK_FORUM_SEARCH_RESULT eventData:@{@"keyword": self.keyword ?: @"", @"topic_id": @(topic.identifier), @"result_index": @(indexPath.row)}];
            }
        }
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


#pragma mark - Forum Reply Cell delegate

- (void)cell:(ForumReplyCell *)cell heightDidChange:(CGFloat)height
{
    ForumReply *reply = cell.reply;
    NSString *cacheKey = [NSString stringWithFormat:@"%llu", reply.identifier];
    NSNumber *heightNumber = [NSNumber numberWithFloat:height];
    NSNumber *oldNumber = [self.rowHeightCache objectForKey:cacheKey];
    if (!oldNumber || [oldNumber floatValue] != height) {
        [self.rowHeightCache setObject:heightNumber forKey:cacheKey];
        NSInteger row = [self.searchResults indexOfObject:reply];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [UIView setAnimationsEnabled:NO];
        [self.searchTableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
        //        [self delayedReload];
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

#pragma mark - Forum Topic Cell delegate

- (void)cell:(ForumTopicCell *)cell showProfileForUser:(ForumUser *)user
{
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [self resignSearchBar];
    ForumProfileViewController *vc = [[ForumProfileViewController alloc] initWithUserID:user.identifier
                                                                        placeholderUser:user];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - search bar
- (void)toggleSearchBar {
    if (self.view.hidden) {
        [self showSearchBar];
    } else {
        [self hideSearchBar];
    }
}

- (void)showSearchBar {
    if (self.view.hidden) {
        self.view.alpha = 0.0;
        self.view.hidden = NO;
        [self.searchBar becomeFirstResponder];
        [UIView animateWithDuration:0.25 animations:^{
            self.view.alpha = 1.0;
        }];
    }
    [Forum log:BTN_CLK_FORUM_SEARCH];
}

- (void)hideSearchBar {
    [self resignSearchBar];

    [[self.tabBarController tabBar] setHidden:NO];
    if (!self.view.hidden) {
        [self publish:EVENT_FORUM_SEARCH_CANCEL];
        [UIView animateWithDuration:0.25 animations:^{
            self.view.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.view.hidden = YES;
        }];
    }
}

#pragma mark - search results
- (void)searchTopicsWithKeyword:(NSString *)keyword {
    if (!self.fetching && keyword.length > 0) {
        self.fetching = YES;
        self.noMore = NO;
        [self.searchResults removeAllObjects];
        [self.searchTableView reloadData];
        @weakify(self)
        [Forum searchTopicWithKeyword:keyword offset:0 callback:^(NSDictionary *result, NSError *error) {
            @strongify(self)
            BOOL failed = YES;
            if (!error) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    NSArray *topicsArray = [result objectForKey:@"topics"];
                    if ([topicsArray isKindOfClass:[NSArray class]]) {
                        failed = NO;
                        unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                        self.noMore = pageSize > topicsArray.count;

                        [self.searchResults removeAllObjects];
                        self.offset = pageSize;
                        
                        for (NSDictionary *dict in topicsArray) {
                            ForumTopic *topic = [[ForumTopic alloc] initWithDictionary:dict];
                            if (!topic.lowRating) {
                                [self.searchResults addObject:topic];
                            }
                        }
                        self.fetching = NO;
                        [self.searchTableView reloadData];
                    }
                }
            }
            self.fetching = NO;
        }];
        [Forum log:BTN_CLK_FORUM_DO_SEARCH eventData:@{@"keyword": keyword ?: @""}];
    }
}

- (void)searchCommentsWithKeyword:(NSString *)keyword {
    if (!self.fetching && keyword.length > 0) {
        self.fetching = YES;
        self.noMore = NO;
        [self.searchResults removeAllObjects];
        [self.searchTableView reloadData];
        __weak ForumSearchViewController *weakSelf = self;
        [Forum searchReplyWithKeyword:keyword offset:0 callback:^(NSDictionary *result, NSError *error) {
            BOOL failed = YES;
            if (!error) {
                if ([result isKindOfClass:[NSDictionary class]]) {
                    NSArray *repliesArray = [result objectForKey:@"replies"];
                    if ([repliesArray isKindOfClass:[NSArray class]]) {
                        failed = NO;
                        unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                        weakSelf.noMore = pageSize > repliesArray.count;

                        [weakSelf.searchResults removeAllObjects];
                        self.offset = pageSize;
                        
                        for (NSDictionary *dict in repliesArray) {
                            ForumReply *reply = [[ForumReply alloc] initWithDictionary:dict];
                            if (!reply.lowRating) {
                                [weakSelf.searchResults addObject:reply];
                            }
                        }
                        weakSelf.fetching = NO;
                        [weakSelf.searchTableView reloadData];
                    }
                }
            }
            weakSelf.fetching = NO;
        }];
    }
}

#pragma mark - load more

- (void)loadMore:(id)sender {
    if (!self.fetching && self.searchResults.count > 0 && !self.noMore && self.keyword.length > 0) {
        GLLog(@"Loading more...");
        self.fetching = YES;
        __weak ForumSearchViewController *weakSelf = self;
        if (0 == self.searchBar.selectedScopeButtonIndex) {
            [Forum searchTopicWithKeyword:self.keyword offset:self.offset callback:^(NSDictionary *result, NSError *error) {
                if (!error) {
                    if ([result isKindOfClass:[NSDictionary class]]) {
                        NSArray *topicsArray = [result objectForKey:@"topics"];
                        if ([topicsArray isKindOfClass:[NSArray class]]) {
                            unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                            weakSelf.noMore = pageSize > topicsArray.count;
                            weakSelf.offset += pageSize;
                            
                            for (NSDictionary *dict in topicsArray) {
                                ForumTopic *topic = [[ForumTopic alloc] initWithDictionary:dict];
                                if (!topic.lowRating) {
                                    [weakSelf.searchResults addObject:topic];
                                }
                            }
                            weakSelf.fetching = NO;
                            [weakSelf.searchTableView reloadData];
                        }
                    }
                }
                weakSelf.fetching = NO;
            }];
        } else {
            [Forum searchReplyWithKeyword:self.keyword offset:self.offset callback:^(NSDictionary *result, NSError *error) {
                if (!error) {
                    if ([result isKindOfClass:[NSDictionary class]]) {
                        NSArray *topicsArray = [result objectForKey:@"replies"];
                        if ([topicsArray isKindOfClass:[NSArray class]]) {
                            unsigned int pageSize = [[result objectForKey:@"page_size"] unsignedIntValue];
                            weakSelf.noMore = pageSize > topicsArray.count;
                            weakSelf.offset += pageSize;
                            
                            for (NSDictionary *dict in topicsArray) {
                                ForumReply *reply = [[ForumReply alloc] initWithDictionary:dict];
                                if (!reply.lowRating) {
                                    [weakSelf.searchResults addObject:reply];
                                }
                            }
                            weakSelf.fetching = NO;
                            [weakSelf.searchTableView reloadData];
                        }
                    }
                }
                weakSelf.fetching = NO;
            }];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.searchTableView) {
        [self resignSearchBar];
        CGFloat y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom;
        if (y > scrollView.contentSize.height - scrollView.bounds.size.height / 3.0) {
            [self loadMore:nil];
        }
    }
}

#pragma mark - UISearchBarDelegatsearche

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    [[self.tabBarController tabBar] setHidden:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self hideSearchBar];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self resignSearchBar];
    NSString *keyword = [searchBar.text trim];
    if (keyword.length > 0) {
        self.keyword = keyword;
        [self doSearch];
    }
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    self.keyword = self.searchBar.text;
    [self doSearch];
}

- (void)doSearch
{
    if (0 == self.searchBar.selectedScopeButtonIndex) {
        [self searchTopicsWithKeyword:self.keyword];
    } else if (1 == self.searchBar.selectedScopeButtonIndex) {
        [self searchCommentsWithKeyword:self.keyword];
    }
}

- (void)resignSearchBar
{
    [self.searchBar resignFirstResponder];
    [self enableCancelButton];
}

- (void)enableCancelButton
{
    UIControl *cancelButton = (UIButton *)[self.searchBar descendantOrSelfWithClassName:@"UINavigationButton"];
    if ([cancelButton respondsToSelector:@selector(setEnabled:)]) {
        [cancelButton setEnabled:YES];
    }
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [self layoutWithKeyboardHeight:kbSize.height animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    [self layoutWithKeyboardHeight:0.0 animated:YES];
}

- (void)layoutWithKeyboardHeight:(CGFloat)kbHeight animated:(BOOL)animated
{
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone animations:^{
            UIEdgeInsets contentInset = self.searchTableView.contentInset;
            contentInset.bottom = kbHeight;
            self.searchTableView.contentInset = contentInset;
            
            UIEdgeInsets scrollInset = self.searchTableView.scrollIndicatorInsets;
            scrollInset.bottom = kbHeight;
            self.searchTableView.scrollIndicatorInsets = scrollInset;
        } completion:nil];
    } else {
        UIEdgeInsets contentInset = self.searchTableView.contentInset;
        contentInset.bottom = kbHeight;
        self.searchTableView.contentInset = contentInset;
        
        UIEdgeInsets scrollInset = self.searchTableView.scrollIndicatorInsets;
        scrollInset.bottom = kbHeight;
        self.searchTableView.scrollIndicatorInsets = scrollInset;
    }
}


@end

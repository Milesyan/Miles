//
//  ForumPollViewController.m
//  emma
//
//  Created by Jirong Wang on 5/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <Masonry/Masonry.h>
#import "ForumPollViewController.h"
#import "ForumPollOptions.h"
#import "Forum.h"

#define FORUM_POLL_VOTE_CELL_IDENTIFIER @"PollVoteCell"
#define FORUM_POLL_VOTED_CELL_IDENTIFIER @"PollVotedCell"

#pragma mark - Class for vote cell
@interface ForumPollVoteCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *optionLabel;
@property (weak, nonatomic) IBOutlet UIView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *voteButton;
@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (nonatomic) uint64_t topicId;
@property (nonatomic) ForumPollOptionData * model;

- (IBAction)voteButtonClicked:(id)sender;

@end

@implementation ForumPollVoteCell

- (void)awakeFromNib {
    [self.buttonView removeFromSuperview];
    self.buttonView.frame = CGRectMake(0, 4, 70, 25);
    [self.voteButton addSubview:self.buttonView];
    self.buttonView.userInteractionEnabled = NO;
    
    CGFloat radius = self.progressBar.frame.size.height / 2.0;
    self.progressBar.layer.cornerRadius = radius;
    self.voteButton.layer.cornerRadius  = radius * 2;
    
    self.voteButton.exclusiveTouch = YES;
}

- (void)setModel:(ForumPollOptionData *)model topicId:(uint64_t)topicId {
    _model = model;
    self.optionLabel.text = _model.option;
    self.topicId = topicId;
}

- (IBAction)voteButtonClicked:(id)sender {
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [GLNetworkLoadingView show];
    @weakify(self)
    [Forum votePoll:self.topicId atOption:self.model.realOptionIndex callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [GLNetworkLoadingView hide];
        NSString * message = @"Failed to vote the poll";
        if (!error) {
            NSInteger rc = [result integerForKey:@"rc"];
            if (rc == RC_SUCCESS) {
                [self publish:EVENT_FORUM_POLL_OPTION_VOTE data:@{@"topic_id":@(self.topicId), @"vote_index":@(self.model.realOptionIndex)}];
                return;
            } else {
                NSString *errMsg = [result stringForKey:@"msg"];
                if (errMsg) message = errMsg;
            }
        }
        [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
    }];
}

@end

#pragma mark - Class for voted cell
@interface ForumPollVotedCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *optionLabel;
@property (weak, nonatomic) IBOutlet UIView *barBackground;
@property (weak, nonatomic) IBOutlet UIView *barProgress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *checkImageView;
@property (nonatomic) uint64_t topicId;
@property (nonatomic) ForumPollOptionData * model;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *barProgressWidthConstraint;
@property (nonatomic, strong) MASConstraint *widthConstraint;

@end

@implementation ForumPollVotedCell

- (void)awakeFromNib {
    CGFloat radius = self.barBackground.frame.size.height / 2.0;
    self.barBackground.layer.cornerRadius = radius;
    self.barProgress.layer.cornerRadius = radius;
}

- (void)setModel:(ForumPollOptionData *)model topicId:(uint64_t)topicId withAnimation:(BOOL)animation {
    BOOL drawAnimation = YES;
    if (_model == model) {
        drawAnimation = NO;
    } else {
        drawAnimation = animation;
    }
    _model = model;
    self.topicId = topicId;
    // text label
    self.optionLabel.text = _model.option;
    // check view
    self.checkImageView.hidden = !self.model.isVoted;
    
    // progress bar
    CGFloat p = _model.totalVotes <= 0 ? 0 : (_model.votes * 1.0 / _model.totalVotes);
    // draw progress bar animation for only the first time
    [self drawProgressBar:p withAnimation:drawAnimation];
    // progress label
    self.progressLabel.text = [NSString stringWithFormat:@"%2.1f%%", p * 100];

}

- (void)drawProgressBar:(CGFloat)progress withAnimation:(BOOL)animation {
    CGFloat _progress= progress;
    if (_progress <= 0) _progress = 0;
    if (_progress >= 1) _progress = 1;
    self.barProgress.width = 0;
    if (animation) {
        
        [UIView animateWithDuration:0.6 animations:^() {
            [self.widthConstraint uninstall];
            [self.barProgress mas_updateConstraints:^(MASConstraintMaker *maker){
                self.widthConstraint = maker.width.equalTo(self.barBackground).multipliedBy(progress);
            }];
            [self layoutIfNeeded];
        } completion:nil];
    } else {
        [self.widthConstraint uninstall];
        [self.barProgress mas_updateConstraints:^(MASConstraintMaker *maker){
            self.widthConstraint = maker.width.equalTo(self.barBackground).multipliedBy(progress);
        }];
    }
}

@end

#pragma mark - Class for Poll View controller
@interface ForumPollViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) ForumPollOptions * model;
@property (nonatomic) BOOL drawAnimation;

@end

@implementation ForumPollViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.isOnHomePage = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumPollVoteCell" bundle:nil] forCellReuseIdentifier:FORUM_POLL_VOTE_CELL_IDENTIFIER];
    [self.tableView registerNib:[UINib nibWithNibName:@"ForumPollVotedCell" bundle:nil] forCellReuseIdentifier:FORUM_POLL_VOTED_CELL_IDENTIFIER];
    
    self.drawAnimation = YES;
    [self subscribe:EVENT_FORUM_POLL_OPTION_VOTE selector:@selector(pollVoteSuccess:)];
    [self subscribe:EVENT_FORUM_POLL_REFRESHED selector:@selector(pollRefreshed:)];
}

- (void)setModel:(ForumPollOptions *)pullOptions {
    self.drawAnimation = YES;
    if (_model) {
        if ((_model.topicId == pullOptions.topicId) &&
            (_model.isVoted) &&
            (pullOptions.isVoted)) {
            self.drawAnimation = NO;
        }
    }
    _model = pullOptions;
    CGFloat h = _model.options.count * 45;
    self.tableView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, h);
    self.view.bounds = CGRectMake(0, 0, self.view.bounds.size.width, h);
    // This event is used to update other pollViewControllers who has the same topic
    [self publish:EVENT_FORUM_POLL_REFRESHED data:_model];
}

- (BOOL)isVoted {
    return self.model.isVoted;
}

- (void)refresh {
    [self.tableView reloadData];
}

- (void)pollRefreshed:(Event *)event {
    id obj = event.obj;
    if ([obj class] != [ForumPollViewController class]) {
        // not sent by ForumPollViewController
        return;
    }
    if ((ForumPollViewController *)obj == self) {
        // already updated in setModel
        return;
    }
    ForumPollOptions * changedOptions = (ForumPollOptions *)event.data;
    if (self.model.topicId != changedOptions.topicId) {
        // not the same topic
        return;
    }
    // copy the changed data
    self.model.totalVotes = changedOptions.totalVotes;
    self.model.isVoted    = changedOptions.isVoted;
    
    for (ForumPollOptionData * opSrc in changedOptions.options) {
        for (ForumPollOptionData * opTgt in self.model.options) {
            if (opSrc.realOptionIndex == opTgt.realOptionIndex) {
                opTgt.votes = opSrc.votes;
                opTgt.totalVotes = opSrc.totalVotes;
                opTgt.isVoted = opSrc.isVoted;
                break;
            }
        }
    }
}

#pragma mark - subscribe event handler
- (void)pollVoteSuccess:(Event *)event {
    id obj = event.obj;
    if ([obj class] != [ForumPollVoteCell class]) {
        // not sent by ForumPollViewController
        return;
    }
    NSDictionary * voteOption = (NSDictionary *)event.data;
    if (self.model.topicId != [[voteOption objectForKey:@"topic_id"] longLongValue]) {
        // not the same topic
        return;
    }
    
    int votedRealOptionIndex = [[voteOption objectForKey:@"vote_index"] intValue];
    self.model.isVoted = YES;
    self.model.totalVotes += 1;
    self.model.votedIndex = votedRealOptionIndex;
    
    for (ForumPollOptionData * data in self.model.options) {
        data.totalVotes = self.model.totalVotes;
        if (data.realOptionIndex == votedRealOptionIndex) {
            data.votes += 1;
            data.isVoted = YES;
        }
    }
    [self.tableView reloadData];
    [[GLDropdownMessageController sharedInstance] postMessage:@"Thank you for voting!" duration:3 position:64 inView:[GLUtils keyWindow]];
    // logging
    NSDictionary * logData = @{@"topic_id": @(self.model.topicId), @"option_index":@(votedRealOptionIndex)};
    if (self.isOnHomePage) {
        [Forum log:BTN_CLK_FORUM_POLL_VOTE_ON_HOME eventData:logData];
    } else {
        [Forum log:BTN_CLK_FORUM_POLL_VOTE_ON_VIEW eventData:logData];
    }
}

#pragma mark - table view source and delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.model.options.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 45;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // check isVoted
    if (self.model.isVoted) {
        ForumPollVotedCell * cell = (ForumPollVotedCell *)[tableView dequeueReusableCellWithIdentifier:FORUM_POLL_VOTED_CELL_IDENTIFIER];
        [cell setModel:[self.model.options objectAtIndex:indexPath.row] topicId:self.model.topicId withAnimation:self.drawAnimation];
        return cell;
    } else {
        ForumPollVoteCell * cell = (ForumPollVoteCell *)[tableView dequeueReusableCellWithIdentifier:FORUM_POLL_VOTE_CELL_IDENTIFIER];
        [cell setModel:[self.model.options objectAtIndex:indexPath.row] topicId:self.model.topicId];
        return cell;
    }
}

@end

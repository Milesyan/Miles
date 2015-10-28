//
//  ForumTopicHeader.h
//  Pods
//
//  Created by Peng Gu on 8/31/15.
//
//

#import <UIKit/UIKit.h>
#import "ForumUpvoteButton.h"

@interface ForumTopicHeader : UIView

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *postedLabel;
@property (weak, nonatomic) IBOutlet UIButton *nameButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIWebView *contentView;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;

@property (weak, nonatomic) IBOutlet ForumUpvoteButton *likeButton;
@property (weak, nonatomic) IBOutlet UIButton *dislikeButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *flagButton;

@property (weak, nonatomic) IBOutlet UIView *pollContainer;
@property (weak, nonatomic) IBOutlet UILabel *pollVoteTipLabel;

@property (nonatomic) BOOL asURLTopic;
@property (weak, nonatomic) IBOutlet UIView *urlPreviewCard;
@property (weak, nonatomic) IBOutlet UIView *urlPreviewCardThumbnailContainer;
@property (weak, nonatomic) IBOutlet UIImageView *urlPreviewCardThumbnail;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardTitle;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardDesc;
@property (weak, nonatomic) IBOutlet UILabel *urlPreviewCardUrl;

@property (weak, nonatomic) IBOutlet UIView *actionsContainerView;
@property (weak, nonatomic) IBOutlet UIView *showDiscussionView;

@property (strong, nonatomic) IBOutlet UIView *seperator;
@property (strong, nonatomic) NSArray *imgsURLStrings;
@property (nonatomic, assign) BOOL shouldShowEntireDiscussion;

- (void)configureWithTopic:(ForumTopic *)topic;
- (void)updateCountLabel:(ForumTopic *)topic;
- (void)updateLikeButtonInsetWithTopic:(ForumTopic *)topic;

@end



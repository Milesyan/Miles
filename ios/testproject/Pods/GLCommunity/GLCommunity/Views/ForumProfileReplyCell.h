//
//  ProfileTopicCell.h
//  Pods
//
//  Created by Eric Xu on 4/28/15.
//
//

#import <UIKit/UIKit.h>

#define PROFILE_REPLY_CELL_IDENTIFIER         @"ForumProfileReplyCell"

@class ForumReply;
@class ForumProfileReplyCell;
@class MWPhotoBrowser;

@protocol ForumProfileReplyCellDelegate <NSObject>

- (void)forumProfileReplyCellDidClickViewAllReplies:(ForumProfileReplyCell *)cell;
- (void)forumProfileReplyCellDidClickTopicCard:(ForumProfileReplyCell *)cell;
- (void)forumProfileReplyCell:(ForumProfileReplyCell *)cell needToPresentImageBrowser:(MWPhotoBrowser *)imageBrowser;

@end


@interface ForumProfileReplyCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UILabel *respond;

@property (weak, nonatomic) IBOutlet UILabel *replyContentLabel;
@property (weak, nonatomic) IBOutlet UIScrollView *imagesContainer;
@property (weak, nonatomic) IBOutlet UIButton *viewAllRepliesButton;

@property (weak, nonatomic) IBOutlet UIView *topicCard;
@property (weak, nonatomic) IBOutlet UILabel *topicTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *topicDescriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *topicIcon;
@property (weak, nonatomic) IBOutlet UIImageView *topicThumbnail;
@property (weak, nonatomic) IBOutlet UIView *topicThumbnailContainer;
@property (weak, nonatomic) IBOutlet UIView *tmiContainer;

@property (weak, nonatomic) id<ForumProfileReplyCellDelegate> delegate;

- (void)configureWithReply:(ForumReply *)reply;
+ (CGFloat)cellHeightFor:(ForumReply *)reply;

@end

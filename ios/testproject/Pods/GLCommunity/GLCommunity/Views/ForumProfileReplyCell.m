//
//  ProfileTopicCell.m
//  Pods
//
//  Created by Eric Xu on 4/28/15.
//
//
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/UIButton+Ext.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <BlocksKit/NSArray+BlocksKit.h>

#import "ForumProfileReplyCell.h"
#import "ForumReply.h"
#import "Forum.h"


#define TOPIC_CELL_BACKGROUND_COLOR         [UIColor whiteColor]
#define TOPIC_CELL_BACKGROUND_COLOR_ALT     UIColorFromRGB(0xfbfaf7)
#define TOPIC_CELL_BACKGROUND_COLOR_HL      UIColorFromRGB(0xf3f3f3)

#define kCellFullHeight 340
#define kCellLabelFullHeight 54
#define kCellPadding 12
#define kCellImageContainerHeight 88
#define kCellViewAllRepliesHeigth 27


@interface ForumProfileReplyCell () <MWPhotoBrowserDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *viewAllRepliesButtonTopConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topicLabelsLeftConstraint;

@property (nonatomic, strong) NSArray *replyImagesBeingPresented;

@end



@implementation ForumProfileReplyCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.topicCard.layer.cornerRadius = 3;
//    self.topicCard.layer.borderWidth = 0.5;
//    self.topicCard.layer.borderColor = [UIColorFromRGB(0xDEDEDE) CGColor];
//    self.topicCard.layer.shadowColor = [UIColorFromRGB(0xB0B0B0) CGColor];
//    self.topicCard.layer.shadowRadius = 1;
//    self.topicCard.layer.shadowOpacity = 0.3;
//    self.topicCard.layer.shadowOffset = CGSizeMake(0, .5);
    
    self.profileImage.layer.cornerRadius = self.profileImage.width / 2;
    self.topicThumbnail.layer.cornerRadius = 1;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(didClickImages:)];
    [self.imagesContainer addGestureRecognizer:tap];
    
    if (IOS8_OR_ABOVE) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
    }
}


+ (CGFloat)cellHeightFor:(ForumReply *)reply
{
    static NSDictionary *attrs = nil;
    attrs = @{NSFontAttributeName: [GLTheme defaultFont:18]};
    
    CGFloat height = kCellFullHeight;
    
    CGFloat labelWidth = SCREEN_WIDTH - 18 * 2;
    CGFloat labelHeight = [reply.content boundingRectWithSize:CGSizeMake(labelWidth, CGFLOAT_MAX)
                                                      options:NSStringDrawingUsesLineFragmentOrigin
                                                   attributes:attrs
                                                      context:nil].size.height;
    labelHeight = roundf(labelHeight);

    if (labelHeight < kCellLabelFullHeight) {
        height -= kCellLabelFullHeight - labelHeight;
    }
    
    if (reply.images.count == 0) {
        height -= kCellImageContainerHeight + kCellPadding;
    }
    
    if (reply.countReplies == 0) {
        height -= kCellViewAllRepliesHeigth + kCellPadding;
    }
    
    return height;
}


- (void)configureWithReply:(ForumReply *)reply
{
    [self configureAuthor:reply.author];
    [self configureTopic:reply.topic];
    [self configureReplyImages:reply.images];
    
    self.replyContentLabel.text = reply.content;
    self.imagesContainer.hidden = reply.images.count == 0;
    
    CGFloat viewAllTopConstraint = reply.images.count > 0 ? 112 : 12;
    
    if (reply.countReplies > 0) {
        int count = reply.countReplies;
        NSString *countString = count == 1? @"1 reply": [NSString stringWithFormat:@"%d replies", count];
        NSString *buttonTitle = [NSString stringWithFormat:@"View all %@", countString];
        
        self.viewAllRepliesButton.hidden = NO;
        [self.viewAllRepliesButton setTitle:buttonTitle forState:UIControlStateNormal];
    }
    else {
        self.viewAllRepliesButton.hidden = YES;
        viewAllTopConstraint = (reply.images.count == 0 ? 0 : 100) - self.viewAllRepliesButton.height;
    }
    
    self.viewAllRepliesButtonTopConstraint.constant = viewAllTopConstraint;
    
    [self layoutIfNeeded];
}


- (void)configureAuthor:(ForumUser *)author
{
    self.authorLabel.text = author.firstName ? : @"Name";
    
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    
    if (author.cachedProfileImage) {
        self.profileImage.image = author.cachedProfileImage;
    }
    else if (author.profileImage.length > 0) {
        [self.profileImage sd_setImageWithURL:[NSURL URLWithString:author.profileImage]
                             placeholderImage:defaultProfileImage
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                        author.cachedProfileImage = image;
                                    }];
    }
    else {
        self.profileImage.image = defaultProfileImage;
        author.cachedProfileImage = defaultProfileImage;
    }
}


- (void)configureReplyImages:(NSArray *)images
{
    for (UIView *each in self.imagesContainer.subviews) {
        [each removeFromSuperview];
    }
    
    if (images.count == 0) {
        return;
    }
    
    CGFloat imageSize = self.imagesContainer.height;
    CGFloat padding = 8;
    CGRect frame = CGRectMake(0, 0, imageSize, imageSize);
    
    for (NSString *imageURL in images) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.backgroundColor = UIColorFromRGB(0xF4F5F6);
        imageView.layer.masksToBounds = YES;
        imageView.layer.cornerRadius = 2;
        imageView.userInteractionEnabled = YES;
        [imageView sd_setImageWithURL:[NSURL URLWithString:imageURL]];
        
        [self.imagesContainer addSubview:imageView];
        
        frame.origin.x += imageSize + padding;
    }
    
    self.imagesContainer.contentSize = CGSizeMake(frame.origin.x - padding, imageSize);
}


- (void)configureTopic:(ForumTopic *)topic
{
    self.topicTitleLabel.text = topic.title;

    self.tmiContainer.hidden = YES;
    self.topicThumbnailContainer.hidden = YES;

    if ([NSString isNotEmptyString:topic.thumbnail]) {
        @weakify(self)
        [self.topicThumbnail sd_setImageWithURL:[NSURL URLWithString:topic.thumbnail]
                                      completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
        {
            if (image) {
                @strongify(self)
                self.topicThumbnailContainer.hidden = NO;
                if (topic.hasImproperContent) {
                    self.tmiContainer.hidden = NO;
                }
            }
                                          
        }];
        self.topicLabelsLeftConstraint.constant = 68;
    }
    else {
        self.topicLabelsLeftConstraint.constant = 8;
    }
    
    NSString *firstPart = [self countStringForSubject:@"upvote" count:topic.countLikes];
    NSString *secondPart = [self countStringForSubject:@"response" count:topic.countReplies];

    if (topic.isPoll && topic.pollOptions.totalVotes > 0) {
        firstPart = [self countStringForSubject:@"vote" count:topic.pollOptions.totalVotes];
    }
    
    if (firstPart && secondPart) {
        self.topicDescriptionLabel.text = [NSString stringWithFormat:@"%@ • %@", firstPart, secondPart];
    }
    else if (firstPart || secondPart) {
        self.topicDescriptionLabel.text = firstPart ? firstPart : secondPart;
    }
    else {
        self.topicDescriptionLabel.text = @"";
    }
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


- (IBAction)viewAllRepliesClicked:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(forumProfileReplyCellDidClickViewAllReplies:)]) {
        [self.delegate forumProfileReplyCellDidClickViewAllReplies:self];
    }
}


- (IBAction)topiccardClicked:(id)sender
{
    [UIView animateWithDuration:0.1 animations:^{
        self.backgroundColor = FORUM_COLOR_LIGHT_GRAY;
        self.topicCard.backgroundColor = FORUM_COLOR_LIGHT_GRAY;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.backgroundColor = [UIColor whiteColor];
            self.topicCard.backgroundColor = FORUM_COLOR_LIGHT_GRAY;
        });
    }];
    
    if ([self.delegate respondsToSelector:@selector(forumProfileReplyCellDidClickTopicCard:)]) {
        [self.delegate forumProfileReplyCellDidClickTopicCard:self];
    }
}


#pragma mark - reply images

- (void)didClickImages:(UITapGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:self.imagesContainer];
    UIImageView *imageView = (UIImageView *)[self.imagesContainer hitTest:point withEvent:nil];
    NSUInteger index = [self.imagesContainer.subviews indexOfObject:imageView];
    if (index == NSNotFound) {
        index = 0;
    }
    NSArray *images = [self.imagesContainer.subviews valueForKeyPath:@"image"];
    images = [images bk_select:^BOOL(id obj) {
        return ![obj isKindOfClass:[NSNull class]];
    }];
    
    if (images.count == 0) {
        return;
    }
    
    self.replyImagesBeingPresented = [images bk_map:^id(id obj) {
        return [MWPhoto photoWithImage:obj];
    }];
    
    MWPhotoBrowser *imageBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    imageBrowser.displayActionButton = NO;
    [imageBrowser setCurrentPhotoIndex:index];
    
    if ([self.delegate respondsToSelector:@selector(forumProfileReplyCell:needToPresentImageBrowser:)]) {
        [self.delegate forumProfileReplyCell:self needToPresentImageBrowser:imageBrowser];
    }
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return self.replyImagesBeingPresented.count;
}


- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    return self.replyImagesBeingPresented[index];
}


@end





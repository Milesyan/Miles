//
//  DailyArticleCell.m
//  emma
//
//  Created by ltebean on 15-2-27.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyArticleCell.h"
#import "UIView+Emma.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>

static CGFloat const TITLE_LABEL_MAX_HEIGHT = 46;
static CGFloat const TITLE_INTRO_SPACING = 5;
static CGFloat const INTRO_LABEL_MAX_HEIGHT = 63;
static CGFloat const THUMBNAIL_IMAGE_SIZE = 100;
static CGFloat const TITLE_LABEL_MARTIN_RIGHT = 15;
static CGFloat const HEADER_HEIGHT = 30;
static CGFloat const BUTTON_HEIGHT = 43;


@interface DailyArticleCell()
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *contentWrapper;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *introductionLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UIButton *readMoreButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *introductionLabelHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *contentViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thumbnailViewWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelMarginRight;
@end

@implementation DailyArticleCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.containerView addDefaultBorder];
}

- (void)setArticle:(DailyArticle *)article
{
    _article = article;
    [self updateUI];
}

- (void)updateUI
{
    // set text
    [self.titleLabel setAttributedText:[[NSAttributedString alloc] initWithString:self.article.title attributes:[DailyArticleCell attributesForTitleLabelWithCalculationMode:NO]]];
    [self.introductionLabel setAttributedText:[[NSAttributedString alloc] initWithString:self.article.introduction attributes:[DailyArticleCell attributesForIntroLabelWithCalculationMode:NO]]];
    
    // calculate view size
    CGFloat titleHeight = [DailyArticleCell heightThatFitsForTitleLabelWithArticle:self.article maxHeight:TITLE_LABEL_MAX_HEIGHT];
    self.titleLabelHeight.constant = titleHeight;
    
    CGFloat introductionHeight = [DailyArticleCell heightThatFitsForIntroLabelWithArticle:self.article maxHeight:INTRO_LABEL_MAX_HEIGHT];
    self.introductionLabelHeight.constant = introductionHeight;
    
    if ([self.article hasThumbnail]) {
        [self.thumbnailView sd_setImageWithURL:[NSURL URLWithString:self.article.thumbnailUrl]];
        self.thumbnailViewWidth.constant = THUMBNAIL_IMAGE_SIZE;
        self.titleLabelMarginRight.constant = TITLE_LABEL_MARTIN_RIGHT;
    } else {
        self.thumbnailViewWidth.constant = 0;
        self.titleLabelMarginRight.constant = 0;
    }
    CGFloat thumbnailHeight = [self.article hasThumbnail] ? THUMBNAIL_IMAGE_SIZE : 0;
    CGFloat textHeight = titleHeight + TITLE_INTRO_SPACING + introductionHeight;
    self.contentViewHeight.constant = MAX(thumbnailHeight, textHeight);
    
    
    // likes and comments
    NSString * LIKE_TEXT_BASE = @"#LIKE##COMMENT#";
    NSRange LIKE_RANGE    = NSMakeRange(0, 6);
    NSRange COMMENT_RANGE = NSMakeRange(6, 9);
    NSDictionary * purpleAttr = @{
                                  NSFontAttributeName:[Utils defaultFont:14],
                                  NSForegroundColorAttributeName: UIColorFromRGB(0x868686)
                                  };
    NSMutableAttributedString * contentString = [[NSMutableAttributedString alloc] initWithString:LIKE_TEXT_BASE attributes:purpleAttr];
    
    NSInteger comments = self.article.comments;
    NSInteger likes = self.article.likes;
    
    NSString * commentString = [NSString stringWithFormat:@"  •  %@ comment%s", [Utils numberToShortIntString:comments], (comments == 1) ? "" : "s"];
    NSString * likeString = [NSString stringWithFormat:@"%@ like%s", [Utils numberToShortIntString:likes], (likes == 1) ? "" : "s"];
    [contentString.mutableString replaceCharactersInRange:COMMENT_RANGE withString:commentString];
    [contentString.mutableString replaceCharactersInRange:LIKE_RANGE withString:likeString];
    self.detailLabel.attributedText = contentString;

}


+ (CGFloat)heightThatFitsForTitleLabelWithArticle:(DailyArticle *)article maxHeight:(CGFloat)height
{
    return [article.title boundingRectWithSize:CGSizeMake([DailyArticleCell labelWidthForArticle:article], height)
                                    options:NSStringDrawingUsesLineFragmentOrigin
                                 attributes:[DailyArticleCell attributesForTitleLabelWithCalculationMode:YES]
                                    context:nil].size.height;
}

+ (CGFloat)heightThatFitsForIntroLabelWithArticle:(DailyArticle *)article maxHeight:(CGFloat)height
{
    return [article.introduction boundingRectWithSize:CGSizeMake([DailyArticleCell labelWidthForArticle:article], height)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:[DailyArticleCell attributesForIntroLabelWithCalculationMode:YES]
                                       context:nil].size.height;
}

+ (CGFloat)labelWidthForArticle:(DailyArticle *)article
{
    // outer padding: 8; inner padding: 15; spacing to image: 15
    if ([article hasThumbnail]) {
        return SCREEN_WIDTH - 8 * 2 - 15 * 2 - THUMBNAIL_IMAGE_SIZE - TITLE_LABEL_MARTIN_RIGHT;
    } else {
        return SCREEN_WIDTH - 8 * 2 - 15 * 2;
    }
}


+ (CGFloat)heightThatFitsForArticle:(DailyArticle *)article
{
    CGFloat titleHeight = [DailyArticleCell heightThatFitsForTitleLabelWithArticle:article maxHeight:TITLE_LABEL_MAX_HEIGHT];
    CGFloat introductionHeight = [DailyArticleCell heightThatFitsForIntroLabelWithArticle:article maxHeight:INTRO_LABEL_MAX_HEIGHT];

    CGFloat thumbnailHeight = [article hasThumbnail] ? THUMBNAIL_IMAGE_SIZE : 0;
    CGFloat textHeight = titleHeight + TITLE_INTRO_SPACING + introductionHeight;
    
    CGFloat contentHeight = MAX(thumbnailHeight, textHeight);
    return 12 + HEADER_HEIGHT + 15 + contentHeight + 35 + BUTTON_HEIGHT;
}

+ (NSDictionary *)attributesForTitleLabelWithCalculationMode:(BOOL)isCalculationMode
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    paragraphStyle.lineBreakMode = isCalculationMode ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
    return @{NSFontAttributeName: [Utils semiBoldFont:18], NSParagraphStyleAttributeName:paragraphStyle};
}

+ (NSDictionary *)attributesForIntroLabelWithCalculationMode:(BOOL)isCalculationMode
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    paragraphStyle.lineBreakMode = isCalculationMode ? NSLineBreakByWordWrapping : NSLineBreakByTruncatingTail;
    return @{NSFontAttributeName: [Utils defaultFont:18], NSParagraphStyleAttributeName:paragraphStyle};
}

- (IBAction)readMoreButtonPressed:(id)sender
{
    [Logging log:BTN_CLK_HOME_ARTICLE_READMORE eventData:@{@"article_id": @(self.article.articleId), @"topic_id": @(self.article.topicId)}];
    [self publish:EVENT_HOME_GO_TO_TOPIC data:@(self.article.topicId)];
}


@end

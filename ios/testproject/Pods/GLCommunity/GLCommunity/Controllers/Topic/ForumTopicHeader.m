//
//  ForumTopicHeader.m
//  Pods
//
//  Created by Peng Gu on 8/31/15.
//
//

#import "Forum.h"
#import "ForumTopicHeader.h"
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/UIWebView+Hack.h>
#import <GLFoundation/GLFoundation.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "ForumPollViewController.h"


@interface ForumTopicHeader ()

@property (nonatomic, strong) ForumPollViewController * pollViewController;

@end

@implementation ForumTopicHeader

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self.contentView hideGradientBackgrounds];
    self.contentView.scrollView.bounces = NO;
    self.contentView.scrollView.scrollsToTop = NO;
    self.likeButton.hidden = YES;
    self.dislikeButton.hidden = YES;
    self.shareButton.hidden = YES;
    self.flagButton.hidden = YES;
    
    self.seperator.height = 0.5;
    self.showDiscussionView.hidden = YES;
    
    self.urlPreviewCard.hidden = YES;
    self.urlPreviewCard.backgroundColor = FORUM_COLOR_LIGHT_GRAY;
    self.urlPreviewCard.layer.cornerRadius = 3;
    self.urlPreviewCardThumbnailContainer.layer.cornerRadius = 1;
    
    self.likeButton.layer.cornerRadius = self.likeButton.height / 2;
    self.likeButton.layer.borderWidth = 1;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat y = 20.0;
    CGFloat maxWidth = [UIScreen mainScreen].bounds.size.width - 40;
    self.titleLabel.frame = CGRectMake(20.0, y, maxWidth, 25.0);
    [self.titleLabel sizeToFit];
    
    y += self.titleLabel.frame.size.height + 10.0;
    
    [self.loadingIndicator setTop:y];
    [self.loadingIndicator setCenterX:self.centerX];
    NSInteger bodyHeight;
    
    self.urlPreviewCard.hidden = !self.asURLTopic;
    self.contentView.hidden = self.asURLTopic;
    
    if (self.asURLTopic) {
        bodyHeight = 90;
        self.urlPreviewCard.top = y;
    } else {
        bodyHeight = [[self.contentView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').offsetHeight"] integerValue];
        CGRect contentFrame = self.contentView.frame;
        contentFrame.size.height = bodyHeight;
        contentFrame.size.width = maxWidth;
        contentFrame.origin.y = y;
        self.contentView.frame = contentFrame;
    }
    y += bodyHeight + 10.0;
    
    if (self.pollContainer.hidden == NO) {
        self.pollVoteTipLabel.top = y;
        y += 20;
        
        self.pollContainer.top = y;
        self.pollContainer.width = maxWidth;
        y += self.pollContainer.frame.size.height + 20.0;
    }
    
    if (self.imgsURLStrings.count > 0) {
        y += 12;
    }
    
    self.actionsContainerView.top = y;
    y += 76;    // action container height
    y += 20;    // padding to bottom
    
    if (!self.shouldShowEntireDiscussion) {
        y += 67;
        self.seperator.hidden = YES;
        self.showDiscussionView.hidden = NO;
    }
    else {
        y += 8;
        self.seperator.hidden = NO;
        self.showDiscussionView.hidden = YES;
    }
    
    [self setHeight:y];
}


- (void)configureWithTopic:(ForumTopic *)topic
{
    static NSMutableDictionary *baseAttr = nil;
    static NSMutableDictionary *semiBoldAttr = nil;
    static NSMutableDictionary *grayAttr = nil;
    
    if (!baseAttr) {
        baseAttr = [@{
                      NSFontAttributeName : [GLTheme defaultFont:18.0],
                      NSForegroundColorAttributeName : [UIColor blackColor],
                      } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 25;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        [baseAttr setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    
    if (!semiBoldAttr) {
        semiBoldAttr = [baseAttr mutableCopy];
        [semiBoldAttr setObject:[GLTheme semiBoldFont:15.0] forKey:NSFontAttributeName];
        [semiBoldAttr setObject:[UIColor colorWithWhite:165.0/255.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
    }
    
    if (!grayAttr) {
        grayAttr = [baseAttr mutableCopy];
        [grayAttr setObject:[GLTheme defaultFont:15.0] forKey:NSFontAttributeName];
        [grayAttr setObject:[UIColor colorWithWhite:165.0/255.0 alpha:1.0] forKey:NSForegroundColorAttributeName];
    }
    
    self.titleLabel.hidden = topic.title.length == 0;
    self.contentView.hidden = topic.content.length == 0;
    self.postedLabel.hidden = topic.timeCreated == 0;
    self.nameButton.hidden = topic.timeCreated == 0;
    
    self.titleLabel.text = topic.title;
    
    self.asURLTopic = topic.isURLTopic;
    
    if (topic.isURLTopic) {
        self.urlPreviewCard.hidden = NO;
        self.urlPreviewCardTitle.text = topic.urlTitle;
        self.urlPreviewCardDesc.text = topic.urlAbstract;
        self.urlPreviewCardUrl.text = topic.urlPath ? : topic.content;
        
        self.urlPreviewCardThumbnail.hidden = YES;
        NSInteger cardWidth = [[UIScreen mainScreen] bounds].size.width - 20;
        __block NSInteger cardTitleWidth = cardWidth - 30;
        __block NSInteger cardTitleLeft = 10;
        
        self.urlPreviewCardTitle.width = cardTitleWidth;
        self.urlPreviewCardDesc.width = cardTitleWidth;
        self.urlPreviewCardUrl.width = cardTitleWidth;
        self.urlPreviewCardTitle.left = cardTitleLeft;
        self.urlPreviewCardDesc.left = cardTitleLeft;
        self.urlPreviewCardUrl.left = cardTitleLeft;
        
        if  ([NSString isNotEmptyString:topic.thumbnail]) {
            @weakify(self)
            [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:topic.thumbnail] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                @strongify(self)
                if (image) {
                    self.urlPreviewCardThumbnail.image = image;
                    self.urlPreviewCardThumbnail.hidden = NO;
                    
                    cardTitleWidth = cardTitleWidth - 62;
                    cardTitleLeft = cardTitleLeft + 62;
                    self.urlPreviewCardTitle.width = cardTitleWidth;
                    self.urlPreviewCardDesc.width = cardTitleWidth;
                    self.urlPreviewCardUrl.width = cardTitleWidth;
                    
                    self.urlPreviewCardTitle.left = cardTitleLeft;
                    self.urlPreviewCardDesc.left = cardTitleLeft;
                    self.urlPreviewCardUrl.left = cardTitleLeft;
                }
            }];
        }
    }
    else {
        self.urlPreviewCard.hidden = YES;
        
        if (topic.content.length > 0) {
            NSString *contentWithLinks = [Forum replaceTermLinksInHtml:topic.content caseSensitive:YES];
            [self.contentView loadHTMLString:[self htmlWithContent:contentWithLinks]
                                     baseURL:[NSURL URLWithString:[Forum sharedInstance].baseURL]];
        }
    }
    
    if (![topic isAnonymous] && topic.author.firstName.length > 0) {
        self.postedLabel.hidden = NO;
        self.nameButton.hidden = NO;
        [self.nameButton setTitle:topic.author.firstName forState:UIControlStateNormal];
        [self.nameButton.titleLabel sizeToFit];
        self.nameButton.titleLabel.height = 25.0;
        self.nameButton.height = 25.0;
    }
    else {
        self.postedLabel.hidden = YES;
        self.nameButton.hidden = YES;
    }
    
    self.likeButton.hidden = NO;
    self.dislikeButton.hidden = NO;
    self.shareButton.hidden = NO;
    self.flagButton.hidden = [topic isSystemTopic];
    
    [self updateCountLabel:topic];
    [self updateLikeButtonInsetWithTopic:topic];
}


- (NSString *)numberToShortString:(NSUInteger)num
{
    NSString *u = @"";
    NSInteger newNum = 0;
    if (num >= 1000000000) {
        u = @"b";
        newNum = num/1000000000;
    } else if (num >= 1000000) {
        u = @"m";
        newNum = num/1000000;
    } else if (num >= 1000) {
        u = @"k";
        newNum = num/1000;
    } else {
        newNum = num;
    }
    return [NSString stringWithFormat:@"%ld%@", (long)newNum, u];
}


- (void)updateLikeButtonInsetWithTopic:(ForumTopic *)topic
{
    if (topic.liked) {
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


- (void)updateCountLabel:(ForumTopic *)topic
{
    NSString *hex = topic.liked ? @"EFEFFA" : @"FFFFFF";
    self.likeButton.backgroundColor = [UIColor colorFromWebHexValue:hex];
    hex = topic.liked ? @"5B62D2" : @"E8E8E8";
    self.likeButton.layer.borderColor = [UIColor colorFromWebHexValue:hex].CGColor;
    
    self.likeButton.titleLabel.font = topic.liked ? [GLTheme semiBoldFont:13] : [GLTheme defaultFont:13];
    
    self.likeButton.selected = topic.liked;
    self.dislikeButton.selected = topic.disliked;
    
    NSMutableString *countString = [NSMutableString stringWithString:@""];
    NSString *number = @"";
    if (topic.views > 0) {
        number = [self numberToShortString:(NSUInteger)topic.views];
        [countString appendFormat:@"%@ view%@", number, topic.views == 1 ? @"" : @"s"];
    }
    if (topic.countLikes > 0) {
        if (![countString isEqual:@""]) {
            [countString appendFormat:@" • "];
        }
        number = [self numberToShortString:topic.countLikes];
        [countString appendFormat:@"%@ upvote%@", number, topic.countLikes == 1 ? @"" : @"s"];
    }
    if (topic.countReplies > 0) {
        if (![countString isEqual:@""]) {
            [countString appendFormat:@" • "];
        }
        number = [self numberToShortString:topic.countReplies];
        [countString appendFormat:@"%@ comment%@", number, topic.countReplies == 1 ? @"" : @"s"];
    }
    
    NSString *prev = [countString copy];
    NSString *last = @"";
    
    if ((topic.isPoll) && (topic.pollOptions.totalVotes>0) && (topic.pollOptions.isVoted)) {
        if (![countString isEqual:@""]) {
            [countString appendFormat:@" • "];
        }
        number = [self numberToShortString:topic.pollOptions.totalVotes];
        last = [last stringByAppendingFormat:@"%@ vote%s", number, topic.pollOptions.totalVotes == 1 ? "" : "s"];
        [countString appendString:last];
    }
    
    NSDictionary *attrs = @{NSFontAttributeName: [GLTheme defaultFont:15]};
    CGFloat height = [countString boundingRectWithSize:CGSizeMake(SCREEN_WIDTH - 40, CGFLOAT_MAX)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:attrs
                                              context:nil].size.height;
    if (roundf(height) > 15) {
        last = [@"\n" stringByAppendingString:last];
        countString = [[prev stringByAppendingString:last] mutableCopy];
        self.countLabel.height = roundf(height);
    }
    else {
        self.countLabel.height = 15;
    }
    self.countLabel.bottom = self.postedLabel.top;
    self.countLabel.text = countString;
    self.countLabel.hidden = NO;
}


- (NSString *)htmlWithContent:(NSString *)content
{
    static NSString *htmlBase = nil;
    static NSString *jsBase = nil;
    if (!jsBase) {
        NSURL *imgJSURL = [[NSBundle mainBundle] URLForResource:@"img" withExtension:@"js"];
        NSString *imgJS = [[NSString alloc] initWithContentsOfURL:imgJSURL encoding:NSUTF8StringEncoding error:nil];
        NSURL *commonJSURL = [[NSBundle mainBundle] URLForResource:@"common" withExtension:@"js"];
        NSString *commonJS = [[NSString alloc] initWithContentsOfURL:commonJSURL encoding:NSUTF8StringEncoding error:nil];
        jsBase = [NSString stringWithFormat:@"%@\n%@", imgJS ?: @"", commonJS ?: @""];
    }
    if (!htmlBase) {
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"ForumTopicHeader" withExtension:@"html"];
        htmlBase = [[NSString alloc] initWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
        htmlBase = [htmlBase stringByReplacingOccurrencesOfString:@"#@javascript@#" withString:jsBase ?: @""];
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
            int size = [UIScreen mainScreen].bounds.size.width - 40;
            NSString *div = [NSString stringWithFormat:@"<div style=\"width: %dpx; height: %dpx;background-color:#eeeeee; border: 1px solid #eeeee; overflow: hidden; position: relative;\">\n         <img src=\"%@\" style=\"position: absolute;\" onload=\"OnImageLoad(event);\" />\n</div>",size, size, url];
            result = [result stringByReplacingOccurrencesOfString:img withString:div];
        }
    }
    
    return result;
}

@end





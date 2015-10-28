//
//  GLInsightPopupViewController.m
//  kaylee
//
//  Created by Bob on 14-9-4.
//  Copyright (c) 2014年 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLWebViewController.h>
#import "GLInsightPopupViewController.h"
#import "UIButton+Tint.h"
#import "User.h"
#import <GLMarkdownLabel.h>
#import "ShareController.h"
#import "AppDelegate.h"

@interface GLInsightPopupViewController ()
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UIView *footerView;
@property (strong, nonatomic) IBOutlet UIImageView *eyeIcon;
@property (weak, nonatomic) IBOutlet UIView *headerTitleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;
@property (weak, nonatomic) IBOutlet UIView *linkView;
@property (weak, nonatomic) IBOutlet UILabel *linkLabel;
@property (strong, nonatomic) IBOutlet UIImageView *linkImage;
@property (weak, nonatomic) IBOutlet UIView *bodyContentView;
@property (weak, nonatomic) IBOutlet UIImageView *insightPopupHeaderImageView;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *bodyLabel;

@end

@implementation GLInsightPopupViewController

- (void)setInsight:(Insight *)insight {
    if (_insight != insight) {
        _insight = insight;
        [self updateUI];
    }
}

- (void)updateUI {
    if (!_insight) {
        return;
    }

    NSString *title = _insight.title;
    title = [title stringByReplacingOccurrencesOfString:@"Data detected:" withString:@""];
    {
//        NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
//        attachment.bounds = CGRectMake(0, -5, 20, 20);
//        attachment.image = self.eyeIcon.image;
//        [self.eyeIcon removeFromSuperview];
//        NSMutableAttributedString *attachmentString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
        
        NSMutableAttributedString *myString= [[NSMutableAttributedString alloc] initWithString:title];
//        [attachmentString appendAttributedString:myString];
        self.titleLabel.attributedText = myString;
    }
    
    self.bodyLabel.markdownText = _insight.body;
    [self setSourceURL:_insight.source];
    [self updateLikesAndShares];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.eyeIcon.image = [Utils image:self.eyeIcon.image withColor:[UIColor whiteColor]];
    [self.shareButton setImage:[Utils image:[self.shareButton imageForState:UIControlStateNormal]
                                  withColor:[self.shareButton titleColorForState:UIControlStateNormal]]
                      forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(webLinkClicked)];
    [self.linkLabel addGestureRecognizer:tap];
    self.linkImage.image = [Utils image:self.linkImage.image withColor:UIColorFromRGB(0x6EB830)];
    
    self.view.layer.cornerRadius = 4;
    self.view.layer.masksToBounds = YES;
    
    //This should be done in image asset, but seems like Xcode 6 has a bug that doesn't handle vector image with insets correctly
    UIImage *image = self.insightPopupHeaderImageView.image;
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(40, 5.5, 2.5, 55)];
    self.insightPopupHeaderImageView.image = image;
    
    [self updateUI];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.bodyLabel.preferredMaxLayoutWidth = self.bodyLabel.width;
    self.titleLabel.preferredMaxLayoutWidth = self.titleLabel.width;
    self.linkLabel.preferredMaxLayoutWidth = self.linkLabel.width;
}

- (void)webLinkClicked
{
    [Logging log:BTN_CLK_HOME_INSIGHT_WEB];
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.insight.link]];
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    while (topController.presentedViewController) {
        //make sure it can be presented by this controller
        topController = topController.presentedViewController;
    }

    GLWebViewController *controller = [GLWebViewController viewController];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    [topController presentViewController:nav animated:YES completion:nil];
    [controller openUrl:self.insight.link];
}


- (void)updateLikesAndShares {
    if (_insight) {
        if (_insight.liked) {
            UIImage *img = [UIImage imageNamed:@"insight-upvoted"];
            [self.likeButton setImage:img forState:UIControlStateNormal];
            [self.likeButton setImage:img forState:UIControlStateHighlighted];
        } else {
            UIImage *img = [UIImage imageNamed:@"insight-upvote"];
            [self.likeButton setImage:img forState:UIControlStateNormal];
            [self.likeButton setImage:img forState:UIControlStateHighlighted];
        }
        
        NSDictionary *attrs = @{
                                NSFontAttributeName: [Utils defaultFont: 17],
                                NSForegroundColorAttributeName : UIColorFromRGB(0x6EB830),
                                //                                NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle|NSUnderlinePatternDot),
                                };
        NSString *likeCountStr = [NSString stringWithFormat:@"%d", _insight.likeCount];
        if (_insight.likeCount > 1000) {
            likeCountStr = [NSString stringWithFormat:@"%@k",[Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:(float)_insight.likeCount/1000.0]];
        } else if (_insight.likeCount > 1000000) {
            likeCountStr = [NSString stringWithFormat:@"%@m",[Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:(float)_insight.likeCount/1000000.0]];
        }
        
        NSString *likeString = [NSString stringWithFormat:@"  %@ Upvote%@ ", likeCountStr, _insight.likeCount == 1? @"": @"s"];
        if (_insight.likeCount == 0) {
            likeString = @"  Upvote ";
        }
        NSAttributedString *likeTitle = [[NSAttributedString alloc] initWithString:likeString attributes:attrs];
        
        [self.likeButton setAttributedTitle:likeTitle forState:UIControlStateNormal];
        [self.likeButton setAttributedTitle:likeTitle forState:UIControlStateHighlighted];
        
        
        NSString *shareCountStr = [NSString stringWithFormat:@"%d", _insight.shareCount];
        if (_insight.shareCount > 1000) {
            shareCountStr = [NSString stringWithFormat:@"%@k",[Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:(float)_insight.shareCount/1000.0]];
        } else if (_insight.shareCount > 1000000) {
            shareCountStr = [NSString stringWithFormat:@"%@m",[Utils stringWithFloatOfOneOrZeroDecimal:@"%f" float:(float)_insight.shareCount/1000000.0]];
        }
        NSString *shareString = [NSString stringWithFormat:@" %@ Share%@ ", shareCountStr, _insight.shareCount == 1? @"": @"s"];
        if (_insight.shareCount == 0) {
            shareString = @"  Share ";
        }
        NSAttributedString *shareTitle = [[NSAttributedString alloc] initWithString:shareString attributes:attrs];
        
        [self.shareButton setAttributedTitle:shareTitle forState:UIControlStateNormal];
        [self.shareButton setAttributedTitle:shareTitle forState:UIControlStateHighlighted];
        
        [self.likeButton tintWithColor:UIColorFromRGB(0x6EB830)];
    }
}


- (void)setSourceURL:(NSString *)source {
    // link
//    source = [source stringByAppendingString:@"  "];
    NSDictionary *sourceAttribute = @{
                                      NSFontAttributeName: [Utils semiBoldFont:12],
                                      NSForegroundColorAttributeName: UIColorFromRGB(0x6EB830),
                                      };
    NSDictionary *underlineAttribute = @{
                                         NSFontAttributeName: [Utils defaultFont: 12],
                                         NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                                         NSForegroundColorAttributeName: UIColorFromRGB(0x6EB830),
                                         };
    NSMutableAttributedString *mas = [[NSMutableAttributedString alloc] initWithString:@"Source: " attributes:sourceAttribute];
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:source attributes:underlineAttribute]];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = self.linkImage.image;
    [mas appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    NSMutableAttributedString *attachmentString = [[NSAttributedString attributedStringWithAttachment:attachment] mutableCopy];
    [mas appendAttributedString:attachmentString];
    self.linkLabel.attributedText = mas;
}


#pragma mark - IBActions
- (IBAction)likeButtonTapped:(id)sender
{
    [Logging log:BTN_CLK_HOME_INSIGHT_LIKE
       eventData:@{@"insight_type": @(_insight.type),
                   @"like": _insight.liked? LOG_GENIUS_INSIGHT_UNLIKE: LOG_GENIUS_INSIGHT_LIKE}];
    
    [[User currentUser] likeInsight:_insight];
    [self updateLikesAndShares];
    
    if (!_insight.liked) {
        return;
    }
    
    // prompt message only the first time each week when a user likes an insight
    NSNumber *promptCount = [Utils getDefaultsForKey:SHARE_INSIGHT_PROMPT];
    if (!promptCount || ![promptCount isKindOfClass:[NSNumber class]]) {
        promptCount = @(0);
    }

    if (promptCount.integerValue % 3 == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Like this insight? Share it with your friends!"
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Later"
                                                      otherButtonTitles:@"OK", nil];
            [alertView show];
        });
        promptCount = @(0);
    }

    promptCount = @(promptCount.integerValue + 1);
    [Utils setDefaultsForKey:SHARE_INSIGHT_PROMPT withValue:promptCount];
}

- (IBAction)shareButtonTapped:(id)sender
{
    @weakify(self)
    [ShareController presentWithShareType:ShareTypeInsightShare shareItem:self.insight fromViewController:[AppDelegate topMostController] completion:^(BOOL success) {
        @strongify(self)
        if (success) {
            [self updateLikesAndShares];
        }
    }];
    [Logging log:BTN_CLK_HOME_INSIGHT_SHARE eventData:@{@"insight_type": @(_insight.type)}];
}

#pragma mark - Alertview delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self shareButtonTapped:nil];
    }
}

@end

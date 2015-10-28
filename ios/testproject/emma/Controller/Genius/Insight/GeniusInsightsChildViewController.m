//
//  GeniusInsightsChildViewController.m
//  emma
//
//  Created by Jirong Wang on 8/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GeniusMainViewController.h"
#import "GeniusInsightsChildViewController.h"
#import "Insight.h"
#import "User.h"
#import "Logging.h"
#import "UIButton+Tint.h"
#import "ArrowView.h"
#import "AppDelegate.h"
#import "StatusBarOverlay.h"
#import "Utils+NumberFormat.h"
#import "ShareController.h"


@interface GeniusInsightsChildViewController () <UIAlertViewDelegate>
{
    CGFloat viewWidth;
    CGFloat textY;
    CGFloat viewX;
    CGFloat viewY;
}
@property (weak, nonatomic) IBOutlet UIView *insightTitleView;

@property (weak, nonatomic) IBOutlet UIView *insightTitleHeaderView;
@property (weak, nonatomic) IBOutlet UILabel *insightTitleHeaderLabel;
@property (weak, nonatomic) IBOutlet UILabel *insightTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *insightTitleLabel;



@property (weak, nonatomic) IBOutlet UIView *insightBodyView;

@property (weak, nonatomic) IBOutlet ArrowView *arrowView;
@property (weak, nonatomic) IBOutlet UIView *whiteContainerView;


@property (weak, nonatomic) IBOutlet UIImageView *eyeImage;

@property (strong, nonatomic) IBOutlet UIScrollView *bodyScrollView;
@property (weak, nonatomic) IBOutlet UILabel *insightBodyLabel;
@property (weak, nonatomic) IBOutlet UIView *insightLinkView;
@property (weak, nonatomic) IBOutlet UILabel *insightLinkLabel;
@property (weak, nonatomic) IBOutlet UIImageView *insightWebLinkImage;

@property (weak, nonatomic) IBOutlet UIView *insightBottomView;

@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *likeButton;

@property (weak, nonatomic) IBOutlet UILabel *insightSharedLabel;

@property (weak, nonatomic) IBOutlet UIView *fadeView;

@property (nonatomic) CGRect insightTitleLabelFrame;
@property (nonatomic) CGRect insightTitleViewFrame;
@property (nonatomic) CGRect insightBodyLabelFrame;
@property (nonatomic) CGRect insightBodyViewFrame;
@property (nonatomic) CGRect insightLinkViewFrame;

@property (nonatomic) Insight *insight;

@end

@implementation GeniusInsightsChildViewController

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
    
    self.insightTitleLabel.textColor = UIColorFromRGB(0xffffff);
//    self.insightBodyLabel.textColor = UIColorFromRGB(0xffffff);
    
    viewWidth = GG_FULL_CONTENT_W;//self.insightTitleView.frame.size.width;
    textY = self.insightTitleLabel.frame.origin.y;
    viewX = self.insightTitleView.frame.origin.x;
    viewY = self.insightTitleView.frame.origin.y;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(webLinkClicked)];
    [self.insightLinkLabel addGestureRecognizer:tap];
    
    self.insightWebLinkImage.image = [Utils image:self.insightWebLinkImage.image withColor:UIColorFromRGB(0x6EB839)];
//    self.eyeImage.image = [Utils image:self.eyeImage.image withColor:UIColorFromRGB(0x6EB839) withBlendMode:kCGBlendModeXOR];
    [self.shareButton tintWithColor:UIColorFromRGB(0x6EB830)];
    [self.likeButton tintWithColor:UIColorFromRGB(0x6EB830)];
    
    self.whiteContainerView.layer.cornerRadius = 4;
    [self.arrowView setArrowPoints:@[[NSValue valueWithCGPoint: CGPointMake(30, 0)],
                                     [NSValue valueWithCGPoint: CGPointMake(22, 8)],
                                     [NSValue valueWithCGPoint: CGPointMake(38, 8)]]];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.fadeView.bounds;
    gradient.colors = @[(id)[UIColorFromRGBA(0xFFFFFF00) CGColor],
                        (id)[UIColorFromRGBA(0xFFFFFF77) CGColor],
                        (id)[UIColorFromRGBA(0xFFFFFFCC) CGColor],
                        (id)[UIColorFromRGBA(0xFFFFFFFF) CGColor]];
    [self.fadeView.layer insertSublayer:gradient atIndex:0];

}

- (void)setInsight:(Insight *)insight {
    _insight = insight;
    
    // title header label
    NSString *timePrefixText = self.insight.priority < MAX_GENERAL_INSIGHT_PRI ? @"Daily knowledge" : @"Data detected";
    self.insightTitleHeaderLabel.text = [NSString stringWithFormat:@"%@ • %@", 
         timePrefixText,
         [[Utils dateWithDateLabel:self.insight.date] toReadableDate]
    ];

    // title text and body text
    self.insightTitleLabel.attributedText = [Utils markdownToAttributedText:self.boldInsightTitle fontSize:18 lineHeight:22 color:[UIColor whiteColor]];

    self.insightBodyLabel.attributedText = [Utils markdownToAttributedText:self.insight.body fontSize:18 lineHeight:22 color:UIColorFromRGB(0x393939)];
    [self.insightBodyLabel sizeToFit];

    self.whiteContainerView.frame = setRectHeight(self.whiteContainerView.frame, self.insightBodyLabel.frame.size.height + 60);
    
    [self setSourceURL:self.insight.source];
    [self updateLikesAndShares];
    float y = self.insightBodyLabel.frame.origin.y + self.insightBodyLabel.frame.size.height + 10;
    self.insightBottomView.frame = setRectY(self.insightBottomView.frame, y);
}

- (void)updateLikesAndShares {
    if (_insight) {
//        self.insightSharedLabel.text = [NSString stringWithFormat:@" %d Like%@ • %d Shared", _insight.likeCount, _insight.likeCount == 1? @"": @"s", _insight.shareCount];
//        _insight.likeCount = 561230;
//        _insight.shareCount = 43230;

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
    self.insightLinkLabel.attributedText = mas;

    float w = [UILabel sizeForText:mas inBound:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width;
    [self.insightWebLinkImage setFrame:setRectX(self.insightWebLinkImage.frame, w < 235? w: 240)];

}

- (NSString*)boldInsightTitle {
    return [NSString stringWithFormat:@"$$%@$$", self.insight.title];
}

- (void)calculateViewsToFit {
    CGRect temp1 = self.insightTitleLabel.frame;
    CGRect temp2 = self.insightTitleView.frame;
    CGRect temp3 = self.insightBodyLabel.frame;
    CGRect temp4 = self.insightBodyView.frame;
    CGRect temp5 = self.insightLinkView.frame;
    
    [self replaceViewsToFit];
    
    // set the new frame
    self.insightTitleLabelFrame = self.insightTitleLabel.frame;
    self.insightTitleViewFrame = self.insightTitleView.frame;
    self.insightBodyLabelFrame = self.insightBodyLabel.frame;
    self.insightBodyViewFrame = self.insightBodyView.frame;
    self.insightLinkViewFrame = self.insightLinkView.frame;
    
    // set back
    self.insightTitleLabel.frame = temp1;
    self.insightTitleView.frame = temp2;
    self.insightBodyLabel.frame = temp3;
    self.insightBodyView.frame = temp4;
    self.insightLinkView.frame = temp5;
}

- (void)replaceViewsToFit {
    int yPadding = 10;//IS_IPHONE_5 ? 30 : 20;
    
    int y = viewY;
    // title label
    self.insightTitleLabel.frame = CGRectMake(0, textY, viewWidth, 1);
    [self.insightTitleLabel sizeToFit];
    // reset the width, because the width is changed by "sizeToFit"
    self.insightTitleLabel.frame = setRectWidth(self.insightTitleLabel.frame, viewWidth);
    
    // title view
    self.insightTitleView.frame = CGRectMake(viewX, y, viewWidth, self.insightTitleLabel.frame.size.height + textY + yPadding);
    y += self.insightTitleView.frame.size.height;
    
    // body label
    self.insightBodyLabel.frame = CGRectMake(15, 0, GG_FULL_CONTENT_W - 30, 1);
    [self.insightBodyLabel sizeToFit];
//    self.insightBodyLabel.frame = setRectWidth(self.insightBodyLabel.frame, 250);
    
    self.insightLinkView.frame = setRectY(self.insightLinkView.frame, self.insightBodyLabel.frame.origin.y + self.insightBodyLabel.frame.size.height + 6);
    
    float maxScrollViewHeight = SCREEN_HEIGHT - 220 - y;
    if (self.insightBodyLabel.frame.size.height + 60 < maxScrollViewHeight) {
        maxScrollViewHeight = self.insightBodyLabel.frame.size.height + 60;
        self.bodyScrollView.showsVerticalScrollIndicator = NO;
        self.bodyScrollView.scrollEnabled = NO;
        self.fadeView.hidden = YES;
    } else {
        self.bodyScrollView.scrollEnabled = YES;
        self.bodyScrollView.showsVerticalScrollIndicator = YES;
        [self.bodyScrollView flashScrollIndicators ];
        self.fadeView.hidden = NO;
    }

    self.bodyScrollView.frame = setRectHeight(self.bodyScrollView.frame, maxScrollViewHeight);
    self.bodyScrollView.contentSize = CGSizeMake(self.bodyScrollView.frame.size.width, self.insightBodyLabel.frame.size.height + 60);

    // body view
    self.insightBodyView.frame = CGRectMake(viewX, y, viewWidth, 480);
    self.insightBottomView.frame = setRectY(self.insightBottomView.frame, self.bodyScrollView.frame.origin.y + self.bodyScrollView.frame.size.height);

    self.fadeView.frame = setRectY(self.fadeView.frame, self.bodyScrollView.frame.origin.y + self.bodyScrollView.frame.size.height - self.fadeView.frame.size.height);

    
    float maxWhiteContainerHeight = maxScrollViewHeight + 80;
    self.whiteContainerView.frame = setRectHeight(self.whiteContainerView.frame, maxWhiteContainerHeight);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setSmallTitleLabel {
    // title text and body text
    self.insightTitleLabel.attributedText = [Utils markdownToAttributedText:[NSString stringWithFormat:@"%@ \n%@", self.boldInsightTitle, self.insight.body] fontSize:16 lineHeight:20 color:[UIColor whiteColor]];
    [self.insightTitleLabel setLineBreakMode:NSLineBreakByTruncatingTail];
}

- (void)setFullTitleLabel {
    self.insightTitleLabel.attributedText = [Utils markdownToAttributedText:self.boldInsightTitle fontSize:18 lineHeight:22 color:[UIColor whiteColor]];
}

- (void)showThumbView {
    CGFloat heightOffset = IS_IPHONE_4 ? 0 : 20;
    self.view.frame = CGRectMake(0, 0, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 100 + heightOffset);
    [self setSmallTitleLabel];
    
    // insight title view
    self.insightTitleView.frame = CGRectMake(10, 5,
        GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 85 + heightOffset);
    //[self setSmallTitleLabel];
    self.insightTitleLabel.frame = CGRectMake(0, 0, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 85 + heightOffset);
    // insight body view
    self.insightBodyView.frame = CGRectMake(10, 90 + heightOffset, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 0);
    // insight link view
    self.insightLinkView.frame = CGRectMake(10, 90 + heightOffset, GENIUS_SINGLE_BLOCK_TITLE_WIDTH, 0);
    
    // tital image
    self.insightTitleHeaderView.alpha = 0;
    
}

- (void)showFullView {
    self.view.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    [self setFullTitleLabel];
    
    // insight title Label
    self.insightTitleLabel.frame = self.insightTitleLabelFrame;
    // insight title view
    self.insightTitleView.frame = self.insightTitleViewFrame;
    // insight body Label
    self.insightBodyLabel.frame = self.insightBodyLabelFrame;
    // insight body view
    self.insightBodyView.frame = self.insightBodyViewFrame;
    setWidthOfRect(self.insightBodyView.frame, GG_FULL_CONTENT_W);
    // insight link view
//    self.insightLinkView.frame = self.insightLinkViewFrame;
    
    // title image
    self.insightTitleHeaderView.alpha = 1.0;
    
//    self.view.frame = CGRectMake(0, 0, 320, self.insightLinkView.frame.origin.y + self.insightLinkView.frame.size.height);
}

- (void)webLinkClicked {
    [Logging log:BTN_CLK_GNS_INSIGHT_WEB];
    [self publish:EVENT_INSIGHT_WEB_CLICKED data:@{@"url": self.insight.link}];
}


- (IBAction)shareClicked:(id)sender
{
    [Logging log:BTN_CLK_GNS_INSIGHT_SHARE eventData:@{@"insight_type": @(_insight.type)}];
    
    [self shareInsightWithShareType:ShareTypeInsightShare];
}

- (IBAction)likeClicked:(id)sender {
    GLLog(@"Like it: %@", _insight);
    [Logging log:BTN_CLK_GNS_INSIGHT_LIKE
       eventData:@{@"insight_type": @(_insight.type),
                   @"like": _insight.liked? LOG_GENIUS_INSIGHT_UNLIKE: LOG_GENIUS_INSIGHT_LIKE}];

    [[User currentUser] likeInsight:_insight];
    [self updateLikesAndShares];
    
    if (!_insight.liked) {
        return;
    }
    
    // prompt message only the first time each week when a user likes an insight
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *promptCount = [defaults objectForKey:SHARE_INSIGHT_PROMPT];
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
    [defaults setObject:promptCount forKey:SHARE_INSIGHT_PROMPT];
    [defaults synchronize];
}

- (float)maxHeightForView:(UIView *)v toBottom:(float)distanceToBottom {
    CGPoint p = [v convertPoint:CGPointMake(0, 0) toView:nil];
    return SCREEN_HEIGHT - distanceToBottom - p.y;
}


- (void)shareInsightWithShareType:(ShareType)shareType
{
    @weakify(self)
    [ShareController presentWithShareType:shareType shareItem:_insight fromViewController:[AppDelegate topMostController] completion:^(BOOL success) {
        @strongify(self)
        if (success) {
            [self updateLikesAndShares];
        }
    }];
}


#pragma mark - Alertview delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self shareInsightWithShareType:ShareTypeInsightShareThreeLikes];
    }
}

@end

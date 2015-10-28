//
//  ForumPromotionCell.m
//  Pods
//
//  Created by Eric Xu on 7/17/15.
//
//

#import "ForumPromotionCell.h"

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Blur.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/UIWebView+Hack.h>

#import "ForumTopicCell.h"
#import "ForumCategory.h"
#import "Forum.h"

@interface ForumPromotionCell()
@property (nonatomic) NSInteger resizeCount;
@property (nonatomic, strong) IBOutlet UIButton *more;
@end

@implementation ForumPromotionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    [self.promotionButton setThemeColor:[UIColor colorFromWebHexValue: @"E0675B"]];
    
    [self.contentWebView hideGradientBackgrounds];
    self.contentWebView.scrollView.bounces = NO;
    self.contentWebView.scrollView.scrollsToTop = NO;
    
    [self.more setImage:[[UIImage imageNamed:@"gl-community-addmore"] imageWithTintColor:[UIColor lightGrayColor]] forState:UIControlStateNormal];
    self.promotionButton.layer.cornerRadius = 2;
}


- (void)layoutSubviews
{
    [super layoutSubviews];

    NSInteger bodyHeight;
    
    bodyHeight = [[self.contentWebView stringByEvaluatingJavaScriptFromString:@"document.getElementById('content').offsetHeight"] integerValue];
//    CGRect contentFrame = self.contentWebView.frame;
//    contentFrame.size.height = bodyHeight+20;
//    contentFrame.size.width = SCREEN_WIDTH - 16;
//    contentFrame.origin.y = y;
//    self.contentWebView.height = bodyHeight;
//    [self setHeight:bodyHeight + 41];
//    self.invisibleButton.frame = contentFrame;
    
//    [self.contentWebView.scrollView addObserver:self forKeyPath:@"contentSize" options:0 context:nil];
}


//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if (object == self.contentWebView.scrollView) {
//        _resizeCount++;
//        if (_resizeCount > 10) {
//            [self.contentWebView.scrollView removeObserver:self forKeyPath:@"contentSize"];
//            return;
//        }
//        [self layoutSubviews];
//    }
//}

- (void)setFeed:(ForumPromotionFeed *)feed {
    _feed = feed;
    
    NSString *content = [feed htmlContent];
    [self.contentWebView loadHTMLString:[self htmlWithContent:content] baseURL:nil];

    [self setNeedsLayout];
}

- (IBAction)promotionButtonClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellDidDismissed:)]) {
        [self.delegate performSelector:@selector(cellDidDismissed:) withObject:self];
    }
}

- (IBAction)invisibleButtonClicked:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(cellGotClicked:)]) {
        [self.delegate performSelector:@selector(cellGotClicked:) withObject:self];
    }
}

- (void)dealloc {
//    [self.contentWebView.scrollView removeObserver:self forKeyPath:@"contentSize"];
}


- (NSString *)htmlWithContent:(NSString *)content
{
    return [NSString stringWithFormat:@"%@ %@ %@", @"<body><div id=\"content\" class=\"content\" style=\"margin: 0;\">", content, @"</div></body>    "];
}

@end

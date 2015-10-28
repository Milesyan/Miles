//
//  PollItemCell.m
//  emma
//
//  Created by Jirong Wang on 5/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "PollItemCell.h"
#import "ForumTopic.h"
#import "UIView+Helpers.h"
#import "ForumPollViewController.h"
#import "UIView+Emma.h"

@interface PollItemCell()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *pollContainer;

@property (weak, nonatomic) IBOutlet UILabel *likeTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *readmoreButton;

@property (weak, nonatomic) IBOutlet UIView *whiteBackgroundView;

@property (nonatomic) ForumPollViewController * pollViewController;
@property (nonatomic, strong) ForumTopic * model;
@property (nonatomic) BOOL valid;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pollViewHeight;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *titleLabelHeight;


@end


@implementation PollItemCell

- (void)awakeFromNib
{
    // Initialization code
    [self.whiteBackgroundView addDefaultBorder];
    self.valid = NO;
}

- (void)jumpToForum {
    if (self.model.identifier) {
        [self publish:EVENT_HOME_GO_TO_TOPIC data:@(self.model.identifier)];
    }
}
- (IBAction)readmoreButtonClicked:(id)sender {
    [self jumpToForum];

}

- (void)setModel:(ForumTopic *)model {
    _model = model;
    if ((!_model) || (!_model.pollOptions)) {
        self.valid = NO;
        return;
    }
    if (_model.pollOptions.options.count == 0) {
        self.valid = NO;
        return;
    }
    self.valid = YES;
  
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.model.title attributes:[PollItemCell attributesForTitleLabel]];
    self.titleLabelHeight.constant = [PollItemCell heightThatFitsForTitleLabelWithText:self.model.title];
    
    if (!self.pollViewController) {
        self.pollViewController = [[ForumPollViewController alloc] init];
        [self.pollContainer removeAllSubviews];
        [self.pollContainer addSubview:self.pollViewController.view];
        [self.pollViewController.view mas_updateConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.pollContainer);
        }];
        self.pollViewController.isOnHomePage = YES;
    }
    [self.pollViewController setModel:_model.pollOptions];
    [self.pollViewController refresh];
    self.pollViewHeight.constant = 45 * self.model.pollOptions.options.count;
    
    [self updateForumInfo];
}

- (void)updateForumInfo {
    NSString * LIKE_TEXT_BASE = @"#LIKE##COMMENT#";
    // NSRange MORE_RANGE    = NSMakeRange(0, 9);
    NSRange LIKE_RANGE    = NSMakeRange(0, 6);
    NSRange COMMENT_RANGE = NSMakeRange(6, 9);
    
    NSDictionary * purpleAttr = @{
                                  NSFontAttributeName:[Utils defaultFont:14],
                                  NSForegroundColorAttributeName: UIColorFromRGB(0x868686)
                                  };
    NSMutableAttributedString * contentString = [[NSMutableAttributedString alloc] initWithString:LIKE_TEXT_BASE attributes:purpleAttr];
    if (self.model.identifier) {
        [contentString setAttributes:purpleAttr range:LIKE_RANGE];
        [contentString setAttributes:purpleAttr range:COMMENT_RANGE];
    }
    
    int comments = self.model.countReplies;
    int likes    = self.model.countLikes;
    NSString * commentString = [NSString stringWithFormat:@"  •  %@ comment%s", [Utils numberToShortIntString:comments], (comments == 1) ? "" : "s"];
    NSString * likeString = [NSString stringWithFormat:@"%@ like%s", [Utils numberToShortIntString:likes], (likes == 1) ? "" : "s"];
    [contentString.mutableString replaceCharactersInRange:COMMENT_RANGE withString:commentString];
    [contentString.mutableString replaceCharactersInRange:LIKE_RANGE withString:likeString];
    self.likeTextLabel.attributedText = contentString;
}

+ (CGFloat)getCellHeightByTopic:(ForumTopic *)model {
    if ((!model) || (!model.pollOptions)) {
        return 0;
    }
    if (model.pollOptions.options.count == 0) {
        return 0;
    }
    CGFloat titleHeight = [PollItemCell heightThatFitsForTitleLabelWithText:model.title];
    return 12 + 30 + 15 + titleHeight + 10 + 45 * model.pollOptions.options.count + 42 + 43;
}

+ (NSDictionary *)attributesForTitleLabel
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    return @{NSFontAttributeName: [Utils semiBoldFont:18], NSParagraphStyleAttributeName:paragraphStyle};
}

+ (CGFloat)heightThatFitsForTitleLabelWithText:(NSString *)text
{
    return [text boundingRectWithSize:CGSizeMake(SCREEN_WIDTH - 2 * 8 - 2 * 15, 1000)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:[PollItemCell attributesForTitleLabel]
                                       context:nil].size.height;
}

@end

//
//  DailyTodoItemCell.m
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "DailyTodoItemCell.h"
#import "UILinkLabel.h"
#import "ToolTip.h"
#import "PillButton.h"

@interface DailyTodoItemCell()
@property (weak, nonatomic) IBOutlet UILinkLabel *todoTextLabel;
@property (weak, nonatomic) IBOutlet UIButton *infoButton;
@property (weak, nonatomic) IBOutlet PillButton *checkButton;

@property (nonatomic, strong) NSDictionary *uncompletedAttrs;
@property (nonatomic, strong) NSDictionary *completedAttrs;
@end

@implementation DailyTodoItemCell
- (void)awakeFromNib
{
    [super awakeFromNib];
    self.completedAttrs = [DailyTodoItemCell completedTextAttributes];
    self.uncompletedAttrs = [DailyTodoItemCell textAttributes];
    
    self.separator = [[UIView alloc] initWithFrame:CGRectMake(15, 0, CGRectGetWidth(self.bounds) - 2 * 15, 0.5)];
    self.separator.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.separator.backgroundColor = UIColorFromRGB(0xe2e2e2);
    [self addSubview:self.separator];
}

- (void)setModel:(DailyTodo *)model
{
    _model = model;
    [self updateUI];
}

- (void)updateUI
{
    [self.checkButton setSelected:self.model.checked animated:NO];
    [self updateTodoTitle];
    [self updateTodoInfo];
}

- (void)updateTodoTitle
{
    NSDictionary *attrsDictionary = nil;
    
    // check item type to determine whether to use a bold font
    if (self.model.checked) {
        self.todoTextLabel.textColor = [UIColor grayColor];
        attrsDictionary = self.completedAttrs;
    } else {
        self.todoTextLabel.textColor = [UIColor blackColor];
        attrsDictionary = self.uncompletedAttrs;
    }
    
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:self.model.title attributes:attrsDictionary];
    self.todoTextLabel.attributedText = attrString;
    if (DETECT_TIPS && [self.todoTextLabel isKindOfClass:[UILinkLabel class]]) {
        UILinkLabel *linkLabel = (UILinkLabel *)self.todoTextLabel;
        [linkLabel clearCallbacks];
        for (NSString *tip in [Tooltip keywords]) {
            [linkLabel setCallback:^(NSString *str) {
                //
                [Tooltip tip:str];
            } forKeyword:tip];
        }
        
    }
}

- (void)updateTodoInfo {
    
    NSString * LIKE_TEXT_BASE = @"#LIKE##COMMENT#";
    NSRange LIKE_RANGE    = NSMakeRange(0, 6);
    NSRange COMMENT_RANGE = NSMakeRange(6, 9);
    
    NSDictionary * baseAttr = @{
                                NSFontAttributeName:[Utils defaultFont:14.0],
                                NSForegroundColorAttributeName: self.topicLinkClickable ? GLOW_COLOR_PURPLE:UIColorFromRGB(0x868686)
                                };
    NSMutableAttributedString * contentString = [[NSMutableAttributedString alloc] initWithString:LIKE_TEXT_BASE attributes:baseAttr];
    
    NSInteger comments = self.model.comments;
    NSInteger likes    = self.model.likes;
    NSString * commentString = [NSString stringWithFormat:@"  •  %@ comment%s", [Utils numberToShortIntString:comments], (comments == 1) ? "" : "s"];
    NSString * likeString = [NSString stringWithFormat:@"%@ upvote%s", [Utils numberToShortIntString:likes], (likes == 1) ? "" : "s"];
    [contentString.mutableString replaceCharactersInRange:COMMENT_RANGE withString:commentString];
    [contentString.mutableString replaceCharactersInRange:LIKE_RANGE withString:likeString];
    [self.infoButton setAttributedTitle:contentString forState:UIControlStateNormal];
    [self.infoButton sizeToFit];
    
}

- (IBAction)infoButtonPressed:(id)sender {
    if (self.topicLinkClickable) {
        [self jumpToForum];
    }
}

- (IBAction)checkButtonPressed:(id)sender
{
    [self.model updateChecked:!self.model.checked];
    [Logging log:BTN_CLK_HOME_CHECKOFF_TASK eventData:@{
        @"completed": @(self.model.checked),
        @"idx": @(self.model.todoId),
    }];
    [self updateTodoTitle];
    
}

- (void)jumpToForum {
    if (self.model.topicId) {
        [Logging log:BTN_CLK_HOME_TASK_READMORE eventData:@{@"task_id": @(self.model.todoId)}];
        [self publish:EVENT_HOME_GO_TO_TOPIC data:@(self.model.topicId)];
    }
}

+ (CGFloat)textHeight:(NSString *)todoTitle {
    CGSize size = [todoTitle boundingRectWithSize:CGSizeMake(SCREEN_WIDTH - 8 * 2 - 15 - 58, 10000.0f)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:[self textAttributes]
                                          context:nil].size;
    
    return size.height;
}

+ (NSDictionary *)textAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    return @{NSFontAttributeName: [Utils defaultFont:18], NSParagraphStyleAttributeName:paragraphStyle};
}

+ (NSDictionary *)completedTextAttributes
{
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 3;
    return @{NSFontAttributeName: [Utils defaultFont:18], NSParagraphStyleAttributeName:paragraphStyle, NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)};
}

+ (CGFloat)heightForTodo:(DailyTodo *)todo
{
    CGFloat todoTextHeight = [self textHeight:todo.title];
    return 15 + todoTextHeight + 8 + 14 + 15;
}



@end

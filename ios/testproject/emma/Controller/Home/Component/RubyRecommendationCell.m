//
//  RubyRecommendationCell.m
//  emma
//
//  Created by ltebean on 15/7/30.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "RubyRecommendationCell.h"
#import "UIView+Emma.h"
#import "User.h"

#define TITLE_TEXT @"Sex & Health Trends Unlocked"
#define DESC_TEXT @"Ruby by Glow is a savvy sex & health app for women who want to take control of their sex lives. Get it, girl!"

#define KEY_RUBY_CARD_ALREADY_SHOWN @"ruby_card_already_shown"

@interface RubyRecommendationCell()
@property (weak, nonatomic) IBOutlet UIButton *installButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIImageView *appIcon;
@end

@implementation RubyRecommendationCell
+ (BOOL)needsShow
{
    if ([User currentUser].currentPurpose != AppPurposesAvoidPregnant) {
        return NO;
    }
    if ([User currentUser].isMale) {
        return NO;
    }
    if ([Utils getDefaultsForKey:KEY_RUBY_CARD_ALREADY_SHOWN]) {
        return NO;
    }
    NSDate *firstLaunch = [Utils getDefaultsForKey:@"firstLaunch"];
    if (!firstLaunch) {
        return NO;
    }
    if ([Utils daysBeforeDate:[NSDate date] sinceDate:firstLaunch] < 40) {
        return NO;
    }
    return YES;
}

- (void)awakeFromNib
{
    [self.containerView addDefaultBorder];
    
    self.installButton.layer.cornerRadius = self.installButton.height / 2;
    self.installButton.layer.masksToBounds = YES;
    
    self.dismissButton.layer.borderWidth = 2;
    self.dismissButton.layer.borderColor = GLOW_COLOR_PURPLE.CGColor;
    self.dismissButton.layer.cornerRadius = self.dismissButton.height / 2;
    self.dismissButton.layer.masksToBounds = YES;
    
    self.topLabel.attributedText = [[NSAttributedString alloc] initWithString:TITLE_TEXT attributes:[RubyRecommendationCell attributesForTitleLabelWithCalculationMode:NO]];
    [self.topLabel sizeToFit];
    
    self.descriptionLabel.attributedText = [[NSAttributedString alloc] initWithString:DESC_TEXT attributes:[RubyRecommendationCell attributesForIntroLabelWithCalculationMode:NO]];
    [self.descriptionLabel sizeToFit];
    
}

- (IBAction)installButtonPressed:(id)sender
{
    [Logging log:BTN_CLK_HOME_RUBY_RECOMMENDATION_CARD_INSTALL];
    NSString * url = [NSString stringWithFormat:@"http://itunes.apple.com/app/id%@", RUBY_APP_ID];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    [self dismiss];
}

- (IBAction)dismissButtonPressed:(id)sender
{
    [Logging log:BTN_CLK_HOME_RUBY_RECOMMENDATION_CARD_NOT_NOW];
    [self dismiss];
}


- (void)dismiss
{
    [Utils setDefaultsForKey:KEY_RUBY_CARD_ALREADY_SHOWN withValue:@(YES)];
    [self.delegate rubyRecommendationCellNeedsDismiss:self];
}



+ (CGFloat)height
{
    CGFloat width = SCREEN_WIDTH - 8 * 2 - 20 * 2 - 65 - 15;
    CGFloat titleHeight = [TITLE_TEXT boundingRectWithSize:CGSizeMake(width, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self attributesForTitleLabelWithCalculationMode:YES] context:nil].size.height;
    CGFloat descHeight = [DESC_TEXT boundingRectWithSize:CGSizeMake(width, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:[self attributesForIntroLabelWithCalculationMode:YES] context:nil].size.height;
    return  12 + 20 + titleHeight + 10 + descHeight + 85;
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

@end

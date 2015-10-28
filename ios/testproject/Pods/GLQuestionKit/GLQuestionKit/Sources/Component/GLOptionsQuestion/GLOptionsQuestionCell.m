//
//  GLOptionsQuestionCell.m
//  GLQuestionKit
//
//  Created by ltebean on 15/8/23.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLOptionsQuestionCell.h"
#import <GLFoundation/GLPillButton.h>
#import <Masonry/Masonry.h>
#import "UIView+Helpers.h"
#import <GLFoundation/GLTheme.h>
@interface GLOptionsQuestionCell()
@property (nonatomic, strong) NSMutableArray *titles;
@property (nonatomic, strong) NSMutableArray *values;
@property (nonatomic, strong) NSMutableSet *buttons;
@end

@implementation GLOptionsQuestionCell
@dynamic question;

- (void)setQuestion:(GLOptionsQuestion *)question
{
    [super setQuestion:question];
    NSArray *optionTitles = question.optionTitles;
    NSArray *optionValues = question.optionValues;
    self.titles = [NSMutableArray array];
    self.values = [NSMutableArray array];
    for (NSInteger i = 0; i < optionTitles.count; i++) {
        NSArray *row = optionTitles[i];
        for (NSInteger j = 0; j < row.count; j++) {
            [self.titles addObject:row[j]];
            [self.values addObject:optionValues[i][j]];
        }
    }
    [self updateUI];
}

- (void)updateUI
{
    NSArray *optionTitles = self.question.optionTitles;
    [self.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.buttons = [NSMutableSet set];
    
    CGFloat totalWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat rowHeight = 50;
    UIColor *buttonColor = self.question.titleColor ?: UIColorFromRGB(0x20C493);
    
    for (NSInteger i = 0; i < optionTitles.count; i++) {
        NSArray *row = optionTitles[i];
        CGFloat rowWidth = totalWidth - 15 * 2;
        UIView *rowContainer = [[UIView alloc] initWithFrame:CGRectMake(15, rowHeight * i + 10, rowWidth, rowHeight)];
    
        [self.contentView addSubview:rowContainer];
        
        NSArray *buttonWidthRatios = [self buttonWidthRatiosForRow:row];
        CGFloat buttonWidthTotal = (rowWidth - (row.count - 1) * 15);
        CGFloat left = 0;
        for (NSInteger j = 0; j < row.count; j++) {
            NSString *option = row[j];
            GLPillButton *button = [[GLPillButton alloc] initAndLayoutWithTitle:@"" tintColor:buttonColor offset:CGSizeZero];
            button.height = 36;
            button.centerY = rowHeight / 2;
            button.width = buttonWidthTotal *[buttonWidthRatios[j] floatValue];
            button.left = left;
            button.titleLabel.font = [GLTheme boldFont:15];
            left += button.width + 15;
            
            [button performSelector:@selector(updateBackgroundImage)];
            [button setLabelText:option bold:YES];
            [rowContainer addSubview:button];
            [self.buttons addObject:button];
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            if ([self.values indexOfObject:self.question.answer] == [self.titles indexOfObject:option]) {
                [button setSelected:YES animated:NO];
            }
        }
    }
}

- (NSMutableArray *)buttonWidthRatiosForRow:(NSArray *)row
{
    NSMutableArray *ratios = [NSMutableArray array];
    NSMutableArray *widths = [NSMutableArray array];
    
    CGFloat totalWidth = 0;
    for (NSString *title in row) {
        CGSize size = [title boundingRectWithSize:CGSizeMake(300, 1000)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName: [GLTheme boldFont:15]}
                                          context:nil].size;
        totalWidth += size.width;
        [widths addObject:@(size.width)];
    }
    for (NSNumber *width in widths) {
        [ratios addObject:@([width floatValue] / totalWidth)];
    }
    return ratios;
}

- (void)buttonPressed:(GLPillButton *)button
{
    for (GLPillButton *optionButton in self.buttons) {
        if (optionButton != button) {
            [optionButton setSelected:NO animated:NO];
        }
    }
    NSString *title = button.titleLabel.text;
    NSString *answer = self.values[[self.titles indexOfObject:title]];
    [self updateAnwser:button.selected ? answer : nil];
    [self publishClickEventWithType:CLICK_TYPE_INPUT];
}

+ (NSNumber *)heightForQuestion:(GLQuestion *)question
{
    return @(((GLOptionsQuestion *)question).optionTitles.count * 50 + 20);
}

@end

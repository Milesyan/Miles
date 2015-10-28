//
//  GLQuestionCell.m
//  GLQuestionCell
//
//  Created by ltebean on 15/7/16.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestionCell.h"
#import "GLYesOrNoQuestionCell.h"
#import "GLPickerQuestionCell.h"
#import <GLFoundation/GLTheme.h>
#import "GLQuestionRegistry.h"
#import <GLFoundation/UIView+Helpers.h>

#define subQuestionsSeperatorHeight 20;

@interface GLQuestionCell()<UITableViewDataSource, UITableViewDelegate, GLQuestionBaseCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeight;
@end

@implementation GLQuestionCell

- (void)awakeFromNib {
    // Initialization code
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    NSArray *registeredQuestions = [[GLQuestionRegistry sharedInstance] registeredQuestionClasses];
    for (Class questionClass in registeredQuestions) {
        NSString *cellClassName  = [GLQuestionCell cellClassNameForQuestionClass:questionClass];
        [self.tableView registerNib:[UINib nibWithNibName:cellClassName bundle:nil] forCellReuseIdentifier:cellClassName];
    }
    
}

- (void)setQuestion:(GLQuestion *)question
{
    _question = question;
    self.tableViewHeight.constant = [GLQuestionCell heightForMainQuestion:question forceExpand:YES];
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.question.subQuestions.count > 0) {
        return self.question.subQuestions.count + 1;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 1;
    } else {
        return [self.question.subQuestions[section - 1] count];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return [GLQuestionCell cellHeightForQuestion:self.question];
    }
    else {
        NSArray *questions = self.question.subQuestions[indexPath.section - 1];
        GLQuestion *question = questions[indexPath.row];
        return [GLQuestionCell cellHeightForQuestion:question];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        NSString *identifier = [GLQuestionCell cellIdentifierForQuestion:self.question];
        GLQuestionBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.delegate = self;
        cell.question = self.question;
        cell.leftMargin = 16;
        return cell;
    }
    else {
        NSArray *questions = self.question.subQuestions[indexPath.section - 1];
        GLQuestion *question = questions[indexPath.row];
        NSString *identifier = [GLQuestionCell cellIdentifierForQuestion:question];
        GLQuestionBaseCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
        cell.delegate = self;
        cell.question = question;
        cell.leftMargin = 32;
        return cell;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (![self hasSectionSeperator]) {
        return nil;
    }
    if (section == 0) {
        return nil;
    } else {
        UIColor *color =  [UIColor colorFromWebHexValue:@"b3b3b3"];
        CGFloat height = subQuestionsSeperatorHeight;
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        
        UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, height)];
        if (section - 1 < self.question.subQuestionsSeparatorTitles.count) {
            label.text = self.question.subQuestionsSeparatorTitles[section - 1];
        } else {
            label.text = @"Additional Info";
        }
        label.font = [GLTheme defaultFont:12];
        label.textColor = color;
        label.textAlignment = NSTextAlignmentCenter;
        [label sizeToFit];
        label.centerY = height / 2;
        label.centerX = width / 2;
        
        CGFloat lineWidth = (width - label.width - 15 * 4) / 2;
        
        UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(15, 10, lineWidth, 0.5)];
        leftLine.backgroundColor = [UIColor lightGrayColor];
        
        UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(width - 15 - lineWidth, 10, lineWidth, 0.5)];
        rightLine.backgroundColor = color;
        
        [header addSubview:label];
        [header addSubview:leftLine];
        [header addSubview:rightLine];
        return header;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (![self hasSectionSeperator]) {
        return 0;
    }
    if (section == 0) {
        return 0;
    } else {
        return subQuestionsSeperatorHeight;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.outerTableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]) {
        [self.outerTableView.delegate tableView:self.outerTableView didSelectRowAtIndexPath:[self.outerTableView indexPathForCell:self]];
    }
}


- (void)questionCell:(GLQuestionBaseCell *)cell didAnswerQuestion:(GLQuestion *)question
{
    if (question.subQuestions.count > 0) {
        [self.outerTableView beginUpdates];
        [self.outerTableView endUpdates];
        if (!question.needShowSubquestions) {
            [question enumerateSubQuestions:^(GLQuestion *subQuestion) {
                subQuestion.answer = nil;
                [self.delegate questionCell:self didUpdateAnswerToQuestion:subQuestion];
            }];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, question.subQuestions.count)];
            [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationNone];
        }
    }
    [self.delegate questionCell:self didUpdateAnswerToQuestion:question];
}

- (BOOL)hasSectionSeperator
{
    return self.question.subQuestionsSeparatorTitles && self.question.subQuestionsSeparatorTitles.count > 0;

}

+ (CGFloat)heightForMainQuestion:(GLQuestion *)question forceExpand:(BOOL)force
{
    CGFloat height = 0;
    height += [self cellHeightForQuestion:question];
    BOOL hasSubQuestions = question.subQuestions.count > 0;
    if (hasSubQuestions && (question.needShowSubquestions || force)) {
        for (NSArray *questions in question.subQuestions) {
            if (question.subQuestionsSeparatorTitles.count > 0) {
                height += subQuestionsSeperatorHeight;
            }
            for (GLQuestion *subQuestion in questions) {
                height += [self cellHeightForQuestion:subQuestion];
            }
        }
//        height += 15;
    }
    return height;
}


+ (CGFloat)heightForMainQuestion:(GLQuestion *)question
{
    return [self heightForMainQuestion:question forceExpand:NO];
}

+ (NSString *)cellClassNameForQuestionClass:(Class)questionClass
{
    return [NSString stringWithFormat:@"%@Cell", questionClass];
}

+ (Class)cellClassForQuestionClass:(Class)questionClass
{
    return NSClassFromString([self cellClassNameForQuestionClass:questionClass]);
}

+ (NSString *)cellIdentifierForQuestion:(GLQuestion *)question
{
    Class class = [self cellClassForQuestionClass:[question class]];
    return [class performSelector:@selector(cellIdentifier)];
}

+ (CGFloat)cellHeightForQuestion:(GLQuestion *)question
{
    Class class = [self cellClassForQuestionClass:[question class]];
    return [[class performSelector:@selector(heightForQuestion:) withObject:question] floatValue];
}

@end

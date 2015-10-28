//
//  GLQuestionListView.m
//  GLQuestionKit
//
//  Created by ltebean on 15/7/21.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLQuestionListView.h"
#import "GLQuestionCell.h"

@interface GLQuestionListView()<UITableViewDataSource, UITableViewDelegate, GLQuestionCellDelegate>
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation GLQuestionListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.tableView = [[UITableView alloc] initWithFrame:self.bounds];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"GLQuestionCell" bundle:nil] forCellReuseIdentifier:GLQuestionCellIdentifier];
    self.tableView.tableFooterView = [UIView new];
    
    [self addSubview:self.tableView];
}

- (void)reloadData
{
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.questions.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [GLQuestionCell heightForMainQuestion:self.questions[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GLQuestionCell *cell = [tableView dequeueReusableCellWithIdentifier:GLQuestionCellIdentifier];
    cell.question = self.questions[indexPath.row];
    cell.outerTableView = self.tableView;
    cell.delegate = self;

    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    
}


- (void)questionCell:(GLQuestionCell *)cell didUpdateAnswerToQuestion:(GLQuestion *)question
{
    [self.delegate questionListView:self didUpdateAnswerToQuestion:question];
}


@end

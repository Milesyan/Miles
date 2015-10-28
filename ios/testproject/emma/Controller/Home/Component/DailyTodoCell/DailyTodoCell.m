//
//  DailyTodoCell.m
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "DailyTodoCell.h"
#import "DailyTodoItemCell.h"
#import "HomeCardOperationButton.h"

@interface DailyTodoCell()<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet HomeCardOperationButton *readmoreButton;
@end

@implementation DailyTodoCell

- (void)awakeFromNib {
    // Initialization code
    [self.tableView registerNib:[UINib nibWithNibName:@"DailyTodoItemCell" bundle:nil] forCellReuseIdentifier:@"DailyTodoItem"];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)setTodos:(NSArray *)todos
{
    _todos = todos;
    [self updateUI];
}

- (void)updateUI
{
    if (self.todos.count == 1) {
        self.readmoreButton.hidden = NO;
    } else {
        self.readmoreButton.hidden = YES;
    }
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.todos.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DailyTodoItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DailyTodoItem"];
    if (indexPath.row == 0) {
        cell.separator.hidden = YES;
    } else {
        cell.separator.hidden = NO;
    }
    if (self.todos.count == 1) {
        cell.topicLinkClickable = NO;
    } else {
        cell.topicLinkClickable = YES;
    }
    cell.model = self.todos[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [DailyTodoItemCell heightForTodo:self.todos[indexPath.row]];
}

- (IBAction)readMoreButtonPressed:(id)sender
{
    DailyTodo *todo = self.todos[0];
    [Logging log:BTN_CLK_HOME_TASK_READMORE eventData:@{@"task_id": @(todo.todoId)}];
    [self publish:EVENT_HOME_GO_TO_TOPIC data:@(todo.topicId)];
}

+ (CGFloat)heightForTodos:(NSArray *)todos
{
    CGFloat height = 12 + 30;
    for (DailyTodo *todo in todos) {
        height += [DailyTodoItemCell heightForTodo:todo];
    }
    if (todos.count == 1) {
        // show the join discussion button
        return height + 43;
    } else {
        return height;
    }
}

@end

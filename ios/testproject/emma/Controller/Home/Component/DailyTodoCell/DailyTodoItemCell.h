//
//  DailyTodoItemCell.h
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyTodo.h"

@interface DailyTodoItemCell : UITableViewCell
@property (nonatomic) BOOL topicLinkClickable;
@property (nonatomic, strong) UIView *separator;
@property (nonatomic, strong) DailyTodo *model;
+ (CGFloat)heightForTodo:(DailyTodo *)todo;
@end

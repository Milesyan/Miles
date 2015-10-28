//
//  DailyTodoCell.h
//  emma
//
//  Created by ltebean on 15/7/13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DailyTodoCell : UITableViewCell
@property (nonatomic, strong) NSArray *todos;
+ (CGFloat)heightForTodos:(NSArray *)todos;
@end

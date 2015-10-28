//
//  ForumTableHeader.h
//  emma
//
//  Created by Xin Zhao on 7/3/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CELL_ID_FORUM_TABLE_HEADER @"CELL_ID_FORUM_TABLE_HEADER"
#define CELL_H_FORUM_TABLE_HEADER 30

@class ForumTableHeader;
@protocol ForumTableHeaderDelegate <NSObject>

- (void)clickSectionHeaderRight:(ForumTableHeader *)header;

@end

@interface ForumTableHeader : UITableViewHeaderFooterView

@property (weak, nonatomic) IBOutlet UIView *bg;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) id<ForumTableHeaderDelegate> delegate;

- (void)setupWithBgColor:(UIColor *)color titleMeta:(NSDictionary *)titleMeta
    rightClickableMeta:(NSDictionary *)rightClickableMeta;

@end

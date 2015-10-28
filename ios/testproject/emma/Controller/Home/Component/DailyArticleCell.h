//
//  DailyArticleCell.h
//  emma
//
//  Created by ltebean on 15-2-27.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DailyArticle.h"

@interface DailyArticleCell : UITableViewCell
@property (nonatomic,strong) DailyArticle *article;
+ (CGFloat)heightThatFitsForArticle:(DailyArticle *)article;
@end

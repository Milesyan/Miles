//
//  HomeCardCustomizationCell.h
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HomeCardCustomizationCell;
@protocol HomeCardCustomizationCellDelegate <NSObject>
- (void)customizationCell:(HomeCardCustomizationCell *)cell didUpdateCardKey:(NSString *)key to:(BOOL)display;
@end

@interface HomeCardCustomizationCell : UITableViewCell
@property (nonatomic, strong) NSDictionary *card;
@property (nonatomic, weak) id<HomeCardCustomizationCellDelegate> delegate;
@end

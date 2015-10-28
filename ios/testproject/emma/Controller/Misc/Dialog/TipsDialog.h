//
//  TipsDialog.h
//  emma
//
//  Created by Xin Zhao on 13-10-18.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "AppUpgradeDialog.h"

@interface TipsDialog : AppUpgradeDialog<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
+ (TipsDialog *)getInstance;

- (void)setTweaks:(NSArray *)tweaks rows:(NSArray *)rows;
@end

@interface StarredRowCell : UITableViewCell


@end

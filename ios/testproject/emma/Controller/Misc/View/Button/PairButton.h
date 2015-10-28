//
//  UIPairButton.h
//  emma
//
//  Created by Jirong Wang on 3/26/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PairButton : UIButton

@property (nonatomic, retain) UIButton *pair;
@property (nonatomic) BOOL deselect;

- (void)setPairButton:(PairButton *)pairButton deselect:(BOOL)deselect;

@end

//
//  CardHeaderView.h
//  emma
//
//  Created by ltebean on 15/5/19.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
IB_DESIGNABLE
@interface HomeCardHeaderView : UIView
@property (nonatomic, copy) IBInspectable NSString *title;
@property (nonatomic, strong) IBInspectable UIImage *icon;
@end

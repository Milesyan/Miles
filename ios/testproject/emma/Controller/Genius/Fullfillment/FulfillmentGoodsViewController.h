//
//  FulfillmentViewController.h
//  emma
//
//  Created by Xin Zhao on 13-12-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "TextValidationTableViewController.h"
#import <UIKit/UIKit.h>

@interface FulfillmentGoodsViewController : UIViewController<UIWebViewDelegate>
@property (nonatomic) NSInteger goodsId;
@end

@interface FulfillmentPaymentViewController : TextValidationTableViewController<TextValidator>

@end

@interface FulfillmentShippingViewController : TextValidationTableViewController<TextValidator>

@end
//
//  WebViewController.h
//  emma
//
//  Created by Xin Zhao on 13-4-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLWebViewController : UIViewController

+ (id)viewController;
- (void)openUrl:(NSString *)urlAddress;

@end

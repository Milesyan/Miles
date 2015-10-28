//
//  WebViewController.h
//  emma
//
//  Created by Xin Zhao on 13-4-12.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

- (void)loadRequest:(NSURLRequest *)request;
- (void)openUrl:(NSString *)urlAddress;

@end

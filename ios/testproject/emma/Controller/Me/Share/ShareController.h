//
//  ShareViewController.h
//  emma
//
//  Created by Peng Gu on 7/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Share.h"

#define SHARE_INSIGHT_PROMPT @"share insight prompt"

@interface ShareController : NSObject

+ (void)presentWithShareType:(ShareType)shareType
                                    shareItem:(id)item
                           fromViewController:(UIViewController *)presentingViewController;

+ (void)presentWithShareType:(ShareType)shareType
                                    shareItem:(id)item
                           fromViewController:(UIViewController *)presentingViewController
                                   completion:(void (^)(BOOL))completion;
@end

//
//  ShareDialogViewController.h
//  emma
//
//  Created by Peng Gu on 8/1/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShareController.h"

@interface ShareDialogViewController : UIViewController

@property (nonatomic, assign) ShareType shareType;

- (instancetype)initFromNib;
- (void)present;
+ (BOOL)alreadyShared;


@end

//
//  EmmaNavigationController.h
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UINavigationController+SafePush.h"

@protocol GLNavigationControllerDelegate <NSObject>

- (void)setupNavigationBarAppearance;

@end

@interface GLNavigationController : UINavigationController <UINavigationControllerDelegate>

@end

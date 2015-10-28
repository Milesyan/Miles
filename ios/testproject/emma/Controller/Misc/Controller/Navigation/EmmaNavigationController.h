//
//  EmmaNavigationController.h
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EmmaNavigationControllerDelegate <NSObject>

- (void)setupNavigationBarAppearance;

@end

@interface EmmaNavigationController : UINavigationController <UINavigationControllerDelegate>

@end

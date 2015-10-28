//
//  PushablePresenteeNavigationController.h
//  emma
//
//  Created by Xin Zhao on 7/21/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLPushableInteractor.h"
#import "EmmaNavigationController.h"

@interface PushablePresenteeNavigationController : EmmaNavigationController
    <GLPushablePresentee>

@end

//
//  GLAppGalleryViewController.h
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLAppGalleryTableViewController.h"

@interface GLAppGalleryViewController : UINavigationController

@property (nonatomic, copy) NSArray *apps;

+ (GLAppGalleryViewController *)viewControllerFromStoryboard;

@end

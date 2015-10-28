//
//  GLAppGalleryTableViewController.h
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLAppEntity.h"

@interface GLAppGalleryTableViewController : UITableViewController

@property (nonatomic, copy) NSArray *apps;

+ (GLAppGalleryTableViewController *)viewControllerFromStoryboard;

@end

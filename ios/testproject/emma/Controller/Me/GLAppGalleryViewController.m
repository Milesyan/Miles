//
//  GLAppGalleryViewController.m
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import "GLAppGalleryViewController.h"

@interface GLAppGalleryViewController ()

@property (strong, nonatomic) GLAppGalleryTableViewController *galleryViewController;

@end

@implementation GLAppGalleryViewController

+ (GLAppGalleryViewController *)viewControllerFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AppGallery" bundle:nil] instantiateViewControllerWithIdentifier:@"AppGallery"];
}

- (void)setApps:(NSArray *)apps {
    self.galleryViewController.apps = apps;
}

- (NSArray *)apps {
    return self.galleryViewController.apps;
}

@end

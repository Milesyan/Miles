//
//  GLCameraViewController.h
//  GLUIKit
//
//  Created by Allen Hsu on 8/19/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GLCameraViewController : UIImagePickerController <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

//@property (assign, nonatomic) BOOL autoCrop;

@property (weak, nonatomic) id <UIImagePickerControllerDelegate> imagePickerDelegate;
- (id)initWithImagePickerDelegate:(id <UIImagePickerControllerDelegate>)imagePickerDelegate;

@end

//
//  ImagePicker.h
//  emma
//
//  Created by Eric Xu on 5/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLImagePicker;

@protocol GLImagePickerDelegate <NSObject>
- (void)imagePicker:(GLImagePicker *)imagePicker didPickedImage:(UIImage *)image;
@optional
- (void)imagePickerDidClickDestructiveButton:(GLImagePicker *)imagePicker;
@optional
- (void)imagePickerDidCancel:(GLImagePicker *)imagePicker;
@end

@interface GLImagePicker : NSObject
@property (nonatomic) id userinfo;

+(GLImagePicker *)sharedInstance;
-(void)showInController:(UIViewController *)controller withTitle:(NSString *)title;
-(void)showInController:(UIViewController *)controller withTitle:(NSString *)title destructiveButtonTitle:(NSString *)destructiveButtonTitle allowsEditing:(BOOL)editing;
@end

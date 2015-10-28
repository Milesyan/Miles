//
//  ImagePicker.h
//  emma
//
//  Created by Eric Xu on 5/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImagePicker;

@protocol ImagePickerDelegate <NSObject>
- (void)didPickedImage:(UIImage *)image;
@optional
- (void)imagePickerDidClickDestructiveButton;
@optional
- (void)imagePickerDidCancle:(ImagePicker *)imagePicker;
@end

@interface ImagePicker : NSObject
+(ImagePicker *)sharedInstance;
-(void)showInController:(UIViewController *)controller withTitle:(NSString *)title;
-(void)showInController:(UIViewController *)controller withTitle:(NSString *)title destructiveButtonTitle:(NSString *)destructiveButtonTitle allowsEditing:(BOOL)editing;
@end

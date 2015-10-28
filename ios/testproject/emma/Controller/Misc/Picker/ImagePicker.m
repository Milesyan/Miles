//
//  ImagePicker.m
//  emma
//
//  Created by Eric Xu on 5/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#define ACTIONSHEET_INDEX_CAMERA 0
#define ACTIONSHEET_INDEX_LIBRARY 1

#import <MobileCoreServices/MobileCoreServices.h>
#import "ImagePicker.h"

@interface ImagePicker()<UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate>{
    id<ImagePickerDelegate> delegate;
    BOOL allowsEditing;
}

@property (nonatomic, strong) UIViewController *controller;
@end

@implementation ImagePicker
static ImagePicker* picker;

+ (ImagePicker *)sharedInstance {
    if (!picker) {
        picker = [[ImagePicker alloc] init];
    }
    
    return picker;
}

- (void)showInController:(UIViewController *)controller withTitle:(NSString *)title {
    [self showInController:controller withTitle:title destructiveButtonTitle:nil allowsEditing:YES];
}

- (void)showInController:(UIViewController *)controller withTitle:(NSString *)title destructiveButtonTitle:(NSString *)destructiveButtonTitle allowsEditing:(BOOL)editing {
    allowsEditing = editing;
    self.controller = controller;
    if ([controller conformsToProtocol:@protocol(ImagePickerDelegate)]) {
        delegate = (id<ImagePickerDelegate>)controller;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:title delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:destructiveButtonTitle otherButtonTitles:@"Take photo", @"Choose from library", nil];
    [sheet showInView:self.controller.view.window];
}

#pragma mark - UIImagePickerControllerDelegate
- (BOOL) startMediaBrowser:(UIImagePickerControllerSourceType)type fromViewController: (UIViewController*) controller
             usingDelegate: (id <UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          type] == NO)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = type;
    mediaUI.mediaTypes = @[(NSString *)kUTTypeImage];
//    [UIImagePickerController availableMediaTypesForSourceType:
//     type];
    
    mediaUI.allowsEditing = allowsEditing;
    mediaUI.delegate = self;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = nil;
    if (picker.allowsEditing) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    if (delegate && [delegate respondsToSelector:@selector(didPickedImage:)]) {
        [delegate didPickedImage:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (delegate && [delegate respondsToSelector:
        @selector(imagePickerDidCancle:)]) {
        [delegate imagePickerDidCancle:self];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet.destructiveButtonIndex >= 0 && buttonIndex == actionSheet.destructiveButtonIndex) {
        if (delegate && [delegate respondsToSelector:@selector(imagePickerDidClickDestructiveButton)]) {
            [delegate imagePickerDidClickDestructiveButton];
        }
    } else if (buttonIndex == actionSheet.cancelButtonIndex) {
        if (delegate && [delegate respondsToSelector:@selector(imagePickerDidCancle:)]) {
            [delegate imagePickerDidCancle:self];
        }
    } else {
        switch (buttonIndex - actionSheet.firstOtherButtonIndex) {
            case ACTIONSHEET_INDEX_CAMERA:
                [self startMediaBrowser:UIImagePickerControllerSourceTypeCamera
                     fromViewController: self.controller
                          usingDelegate: self];
                
                break;
            case ACTIONSHEET_INDEX_LIBRARY:
                [self startMediaBrowser:UIImagePickerControllerSourceTypePhotoLibrary
                     fromViewController: self.controller
                          usingDelegate: self];
                break;
            default:
                break;
        }
    }
}
@end

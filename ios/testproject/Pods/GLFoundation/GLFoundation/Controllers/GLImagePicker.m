//
//  ImagePicker.m
//  emma
//
//  Created by Eric Xu on 5/31/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <MobileCoreServices/MobileCoreServices.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import "GLImagePicker.h"

@interface GLImagePicker()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    id<GLImagePickerDelegate> delegate;
    BOOL allowsEditing;
}

@property (nonatomic, strong) UIViewController *controller;
@end

@implementation GLImagePicker
static GLImagePicker* picker;

+ (GLImagePicker *)sharedInstance {
    if (!picker) {
        picker = [[GLImagePicker alloc] init];
    }
    
    return picker;
}

- (void)showInController:(UIViewController *)controller withTitle:(NSString *)title {
    [self showInController:controller withTitle:title destructiveButtonTitle:nil allowsEditing:YES];
}

- (void)showInController:(UIViewController *)controller withTitle:(NSString *)title destructiveButtonTitle:(NSString *)destructiveButtonTitle allowsEditing:(BOOL)editing {
    allowsEditing = editing;
    self.controller = controller;
    if ([controller conformsToProtocol:@protocol(GLImagePickerDelegate)])
    {
        delegate = (id<GLImagePickerDelegate>)controller;
    }
    else
    {
        delegate = nil;
    }
    if ([UIAlertController class])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        alert.title = title;
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"Take photo", @"GLFoundationLocalizedString", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self startMediaBrowser:UIImagePickerControllerSourceTypeCamera
                     fromViewController: self.controller
                          usingDelegate: self];
            }]];
        }
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        {
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"Choose from library", @"GLFoundationLocalizedString", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self startMediaBrowser:UIImagePickerControllerSourceTypePhotoLibrary
                     fromViewController: self.controller
                          usingDelegate: self];
            }]];
        }
        if (destructiveButtonTitle)
        {
            [alert addAction:[UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                if (delegate && [delegate respondsToSelector:@selector(imagePickerDidClickDestructiveButton:)]) {
                    [delegate imagePickerDidClickDestructiveButton:self];
                }
            }]];
        }
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"Cancel", @"GLFoundationLocalizedString", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            if (delegate && [delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
                [delegate imagePickerDidCancel:self];
            }
        }]];
        [controller presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        UIActionSheet *sheet = [[UIActionSheet alloc] bk_initWithTitle:title];
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [sheet bk_addButtonWithTitle:NSLocalizedStringFromTable(@"Take photo", @"GLFoundationLocalizedString", nil) handler:^()
             {
                 [self startMediaBrowser:UIImagePickerControllerSourceTypeCamera
                      fromViewController: self.controller
                           usingDelegate: self];
             }];
        }
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
        {
            [sheet bk_addButtonWithTitle:NSLocalizedStringFromTable(@"Choose from library", @"GLFoundationLocalizedString", nil) handler:^()
             {
                 [self startMediaBrowser:UIImagePickerControllerSourceTypePhotoLibrary
                      fromViewController: self.controller
                           usingDelegate: self];
             }];
        }
        if (destructiveButtonTitle)
        {
            [sheet bk_setDestructiveButtonWithTitle:destructiveButtonTitle handler:^()
             {
                 if (delegate && [delegate respondsToSelector:@selector(imagePickerDidClickDestructiveButton:)]) {
                     [delegate imagePickerDidClickDestructiveButton:self];
                 }
             }];
        }
        [sheet bk_setCancelButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"GLFoundationLocalizedString", nil) handler:^()
         {
             if (delegate && [delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
                 [delegate imagePickerDidCancel:self];
             }
         }];
        [sheet showInView:self.controller.view.window];
    }
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
        image = info[UIImagePickerControllerEditedImage];
    } else {
        image = info[UIImagePickerControllerOriginalImage];
    }
    if ([delegate respondsToSelector:@selector(imagePicker:didPickedImage:)]) {
        [delegate imagePicker:self didPickedImage:image];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    if ([delegate respondsToSelector:@selector(imagePickerDidCancel:)]) {
        [delegate imagePickerDidCancel:self];
    }
}

@end

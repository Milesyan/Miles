//
//  GeneralPicker.h
//  emma
//
//  Created by Eric Xu on 12/6/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^Callback)(NSInteger row, NSInteger comp);

@class GLGeneralPicker;
@protocol GLGeneralPickerDelegate <UIPickerViewDelegate>

@required
- (void)doneButtonPressed;

@optional
- (void)startOverPressed;

@end

@protocol GLGeneralPickerDataSource <UIPickerViewDataSource>
@end

@interface GLGeneralPicker : UIViewController
@property (nonatomic, strong) id<GLGeneralPickerDelegate> delegate;
@property (nonatomic, strong) id<GLGeneralPickerDataSource> datasource;
@property (nonatomic) BOOL showStartOverButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *startOverButton;
@property (nonatomic, strong) NSArray *customButtons;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *customButton;


+ (GLGeneralPicker *)picker;
+ (void)presentSimplePickerWithTitle:(NSString *)title
                                rows:(NSArray *)rows
                         selectedRow:(int)selectedRow
                          showCancel:(BOOL)showCancel
                      doneCompletion:(Callback)doneCompletion
                    cancelCompletion:(Callback)cancelCompletion;
+ (void)presentSimplePickerWithTitle:(NSString *)title
                                rows:(NSArray *)rows
                         selectedRow:(int)selectedRow
                          showCancel:(BOOL)showCancel
                       withAnimation:(BOOL)animation
                      doneCompletion:(Callback)doneCompletion
                    cancelCompletion:(Callback)cancelCompletion;
+ (void)presentCancelableSimplePickerWithTitle:(NSString *)title rows:(NSArray *)rows
    selectedRow:(int)selectedRow doneTitle:(NSString *)doneTitle
    showCancel:(BOOL)showCancel withAnimation:(BOOL)animation
    doneCompletion:(Callback)doneCompletion
    cancelCompletion:(Callback)cancelCompletion;

+ (void)presentStartoverSimplePickerWithTitle:(NSString *)title
                                         rows:(NSArray *)rows
                                  selectedRow:(int)selectedRow
                               doneCompletion:(Callback)doneCompletion
                          startoverCompletion:(Callback)startoverCompletion;

- (void)present;
- (void)selectRow:(int)row inComponent:(int)component;
- (int)selectedRowInComponent:(int)component;
- (void)dismiss;
- (void)updateTitle:(NSString *)title;
- (void)setCustomButtonTitle:(NSString *)title;
- (void)setStartOverButtonTitle:(NSString *)title;
- (void)setDoneButtonTitle:(NSString *)title;
- (void)reload;

@end

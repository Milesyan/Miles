//
//  PregnantCongratsDialog.h
//  emma
//
//  Created by Jirong Wang on 4/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLDialogViewController.h"

typedef void(^PregnantCallback)();

@interface PregnantCongratsDialog : UIViewController

@property (nonatomic, strong) GLDialogViewController *dialog;

- (void)giveFiveStars;
- (void)stopGlowFirst;
- (void)presentWithButtonTitle:(NSString *)title action:(PregnantCallback)callback;

@end

//
//  PregnantViewController.h
//  emma
//
//  Created by Eric Xu on 10/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EmmaTextView.h"

#define PREGNANT_VIEW_CONTROLLER_DISMISSED @"event_pregnant_dialog_dismissed"

@interface PregnantViewController : UIViewController <EmmaTextViewDelegate>
@property (nonatomic) BOOL anonymously;
@end

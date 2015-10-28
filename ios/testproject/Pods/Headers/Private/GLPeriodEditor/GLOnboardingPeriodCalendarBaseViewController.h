//
//  GLOnboardingPeriodEditorBaseViewController.h
//  GLPeriodEditor
//
//  Created by ltebean on 15-4-30.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLCycleData.h"
#import <GLFoundation/GLMarkdownLabel.h>

@interface GLOnboardingPeriodCalendarBaseViewController : UIViewController
@property (nonatomic, strong) GLCycleData *cycleData;
@property (nonatomic) BOOL showCancelButton;
;@property (weak, nonatomic) IBOutlet UIButton *doneButton;


- (void)setTipLabelText:(NSString *)text;
+ (instancetype)instanceOfSubClass:(NSString *)classString;
- (void)didClickDoneButtonWithCycleData:(GLCycleData *)cycleData;
- (NSInteger)periodLength;
- (GLCycleData *)initialCycleData;
@end

//
//  BMIPicker.h
//  emma
//
//  Created by Eric Xu on 12/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLFoundation/GLGeneralPicker.h>
#define INCH_TO_CM 2.54
#define KG_TO_POUNDS 2.2

#define INPUT_MODE_HEIGHT 1
#define INPUT_MODE_WEIGHT 2
#define INPUT_MODE_WEIGHT_WITH_BACK 3

#define MIN_FEET 4
#define MAX_FEET 8
#define MIN_POUNDS 50
#define MAX_POUNDS 500

#define DEFAULT_HEIGHT 170
#define DEFAULT_WEIGHT 68

#define INPUT_MODE_HEIGHT 1
#define INPUT_MODE_WEIGHT 2

#define kUnitForBMI @"kUnitForBMI"
#define BMIUnitForInch @"IN/LB"


typedef void(^BMICallback)(NSString *bmi, float weight, float height);

@interface BMIPicker : NSObject

//- (void)presentWithDoneCallback:(BMICallback)cb andCancelback:(Callback)cancelCb;
- (void)presentWithSelectedWeigh:(float)weight andHeight:(float)height andDoneCallback:(BMICallback)cb andCancelback:(Callback)cancelCb;
@end

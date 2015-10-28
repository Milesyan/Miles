//
//  WeightPicker.h
//  emma
//
//  Created by Eric Xu on 12/12/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLFoundation/GLGeneralPicker.h>


typedef void(^WeightCallback)(float h);

@interface WeightPicker : NSObject

@property (nonatomic) BOOL showStartOverButton;

- (WeightPicker *)initWithChoose:(int)kgPosition and:(int)lbPosition;

- (void)presentWithWeightInKG:(float)w andCallback:(WeightCallback)doneCallback;
- (void)presentWithWeightInKG:(float)w andCallback:(WeightCallback)doneCallback andStartoverCallback:(WeightCallback)startoverCallback;

@end

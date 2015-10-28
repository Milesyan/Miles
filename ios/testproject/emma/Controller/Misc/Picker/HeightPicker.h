//
//  WeightPicker.h
//  emma
//
//  Created by Eric Xu on 12/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLFoundation/GLGeneralPicker.h>

typedef void(^HeightCallback)(float h);

@interface HeightPicker : NSObject

- (HeightPicker *)initWithChoose:(int)cmPosition feetPosition:(int)feetPosition inchPosition:(int)inchPosition;

- (void)presentWithHeightInCM:(float)h andCallback:(HeightCallback)doneCallback;

@end

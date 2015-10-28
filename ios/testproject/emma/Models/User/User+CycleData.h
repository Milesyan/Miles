//
//  User+CycleData.h
//  emma
//
//  Created by Peng Gu on 5/9/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "User.h"


@class GLCycleData;

@interface User (CycleData)
@property (nonatomic, assign, readonly) GLCycleData *nextCycle;
@property (nonatomic, assign, readonly) GLCycleData *currentCycle;
@end

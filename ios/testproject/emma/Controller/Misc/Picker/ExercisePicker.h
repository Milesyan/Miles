//
//  HeightPicker.h
//  emma
//
//  Created by Eric Xu on 12/9/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLFoundation/GLGeneralPicker.h>

enum PickerTarget {
    TARGET_SETTING = 1,
    TARGET_DAILY_LOG = 2,
    };

@interface ExercisePicker : NSObject

@property (nonatomic) enum PickerTarget target;

- (void)presentWithSelectedRow:(NSInteger)row inComponents:(NSInteger)component withDoneCallback:(Callback)doneCallback andCancelCallback:(Callback)cancelCallback;
+ (NSString *)titleForFullListIndex:(NSInteger)idx;
+ (NSInteger)valueForFullListIndex:(NSInteger)idx;
+ (NSInteger)indexOfValue:(NSInteger)val;
//- (NSString *)titleForValue:(int)val;

@end

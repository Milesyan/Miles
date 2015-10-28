//
//  RotationLabels.h
//  emma
//
//  Created by Peng Gu on 9/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RotationLabels : NSObject

@property (nonatomic, strong) NSMutableArray *labelArray;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) NSArray *tipStrings;

- (void)prepareLabelsForView:(UIView *)view;
- (void)hide;
- (void)show;
- (void)doLabelRotation;
- (void)setCurrentLabelIndex:(NSInteger)index;

@end

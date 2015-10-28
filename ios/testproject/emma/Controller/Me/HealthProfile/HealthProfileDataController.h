//
//  HealthProfileDataSource.h
//  emma
//
//  Created by Peng Gu on 10/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>



@class HealthProfileItem;

@interface HealthProfileDataController : NSObject

@property (nonatomic, assign) NSUInteger numberOfSections;

+ (CGFloat)completionRate;

- (NSUInteger)numberOfItemsInSection:(NSUInteger)section;
- (HealthProfileItem *)itemAtIndexPath:(NSIndexPath *)indexPath;

- (void)reloadItems;

@end

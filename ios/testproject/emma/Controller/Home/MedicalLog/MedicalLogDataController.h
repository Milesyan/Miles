//
//  MedicalLogDataController.h
//  emma
//
//  Created by Peng Gu on 10/17/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@class MedicalLogItem;


@interface MedicalLogDataController : NSObject

@property (nonatomic, copy) NSString *date;
@property (nonatomic, strong) NSMutableArray *questions;
@property (nonatomic, readonly) BOOL hasChanges;
- (instancetype)initWithDate:(NSString *)dateString;
- (void)saveAllToModel;

@end

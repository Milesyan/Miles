//
//  ClinicsManager.h
//  emma
//
//  Created by Xin Zhao on 13-6-16.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

#define CLINIC_TABLE_CELL_IDENTIFIER  @"content"
#define CLINIC_TABLE_RECOMMEND_IDENTIFIER  @"recommend"

@interface ClinicsManager : NSObject

+ (NSDictionary *)readClinics;
+ (void)writeClinics:(NSString *)clinicsRawString;

@end

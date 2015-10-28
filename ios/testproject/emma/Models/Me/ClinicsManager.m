//
//  ClinicsManager.m
//  emma
//
//  Created by Xin Zhao on 13-6-16.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "ClinicsManager.h"
#import "SyncableAttribute.h"

#define ALL_CLINICS_PLIST_NAME @"clinics"

@implementation ClinicsManager

+ (NSDictionary *)readClinics {
    NSDictionary *dictionary = nil;
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *plistPath = [NSString stringWithFormat:@"%@/%@.plist",docDir,ALL_CLINICS_PLIST_NAME];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:plistPath]) {
        SyncableAttribute *syncableAttrClinics = [SyncableAttribute tsetWithName:ATTRIBUTE_CLINICS];
        if (syncableAttrClinics.stringifiedAttribute) {
            [self writeClinics:syncableAttrClinics.stringifiedAttribute];
        }
    }
    if (![fileManager fileExistsAtPath:plistPath]) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        plistPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", ALL_CLINICS_PLIST_NAME]];
    }
    
    dictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    return dictionary;
}

+ (void)writeClinics:(NSString *)clinicsRawString {
    [Utils writeString:clinicsRawString toDomainFile:ALL_CLINICS_PLIST_NAME];
}

@end

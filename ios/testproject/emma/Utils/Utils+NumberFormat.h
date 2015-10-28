//
//  Utils+NumberFormat.h
//  emma
//
//  Created by Xin Zhao on 14-1-2.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import "Utils.h"

#define US_ZIP_CODE_DIGITS @[@5, @9]

@interface Utils (NumberFormat)
+ (NSString *)stringWithFloatOfOneOrZeroDecimal:(NSString *)stringFormat float:(float)floatNum;
+ (NSString *)stringWithFloatOfTwoToZeroDecimal:(NSString *)stringFormat float:(float)floatNum;

+ (CGFloat)celciusFromFahrenheit:(CGFloat)fs;
+ (CGFloat)fahrenheitFromCelcius:(CGFloat)cs;
+ (NSInteger)inchesFromCm:(CGFloat)cm;
+ (CGFloat)cmFromInches:(NSInteger)inches;
+ (CGFloat)poundsFromKg:(CGFloat)kg;
+ (CGFloat)preciseKgFromPounds:(CGFloat)pounds;
+ (CGFloat)precisePoundsFromKg:(CGFloat)kg;
+ (CGFloat)kgFromPounds:(CGFloat)pounds;
+ (CGFloat)convertTemperature:(CGFloat)temp toUnit:(NSString *)unit;


+ (NSString *)displayTextForWeightInKG:(float)w;
+ (NSString *)displayTextForHeightInCM:(float)h;
+ (NSString *)displayTextForTemperatureInCelcius:(float)c;

+ (NSString *)usaZipCodeWithOldString:(NSString *)old replacementString:
        (NSString *)string;
+ (NSString *)cardNumberWithOldString:(NSString *)old replacementString:
        (NSString *)string;
+ (NSString *)expireWithOldString:(NSString *)old replacementString:
        (NSString *)string;
+ (NSString *)cvcWithOldString:(NSString *)old replacementString:
        (NSString *)string;
+ (BOOL)cardIsAmericanExpress:(NSString *)number;
+ (BOOL)validateCardNumber:(NSString *)cardNumber;
+ (BOOL)validateCardExpire:(NSString *)expire;
+ (BOOL)validateCardCVC:(NSString *)cvc;
@end

//
//  Utils+NumberFormat.m
//  emma
//
//  Created by Xin Zhao on 14-1-2.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import "Utils+NumberFormat.h"

#define INCH_TO_CM 2.54
#define KG_TO_POUNDS 2.20462262

@implementation Utils (NumberFormat)
+ (NSString *)stringWithFloatOfOneOrZeroDecimal:(NSString *)stringFormat float:
        (float)floatNum {
    NSInteger floatMultiply10 = roundf(floatNum * 10);
    if (floatMultiply10 % 10 != 0) {
        stringFormat = [stringFormat stringByReplacingOccurrencesOfString:@"%f"
                withString:@"%.1f"];
    }
    else {
        stringFormat = [stringFormat stringByReplacingOccurrencesOfString:@"%f"
                withString:@"%.0f"];
    }
    return [NSString stringWithFormat:stringFormat, floatNum];
}

+ (NSString *)stringWithFloatOfTwoToZeroDecimal:(NSString *)stringFormat float:
        (float)floatNum {
    NSInteger floatMultiply100 = roundf(floatNum * 100);
    if (floatMultiply100 % 10 != 0) {
        stringFormat = [stringFormat stringByReplacingOccurrencesOfString:@"%f"
                withString:@"%.2f"];
    }
    else if (floatMultiply100 % 100 != 0) {
        stringFormat = [stringFormat stringByReplacingOccurrencesOfString:@"%f"
                withString:@"%.1f"];
    }
    else {
        stringFormat = [stringFormat stringByReplacingOccurrencesOfString:@"%f"
                withString:@"%.0f"];
    }
    return [NSString stringWithFormat:stringFormat, floatNum];
}

+ (CGFloat)celciusFromFahrenheit:(CGFloat)fs {
    return (fs - 32.0f) * 5.0f / 9.0f;
}

+ (CGFloat)fahrenheitFromCelcius:(CGFloat)cs {
    return cs * 9.0f / 5.0f + 32.0f;
}

+ (NSInteger)inchesFromCm:(CGFloat)cm {
    return (cm / INCH_TO_CM + 0.5);
}

+ (CGFloat)cmFromInches:(NSInteger)inches {
    return inches * INCH_TO_CM;
}

+ (CGFloat)kgFromPounds:(CGFloat)pounds {
    return pounds / KG_TO_POUNDS;
}

+ (CGFloat)poundsFromKg:(CGFloat)kg {
    return kg * KG_TO_POUNDS;
}

+ (CGFloat)preciseKgFromPounds:(CGFloat)pounds {
    return pounds / KG_TO_POUNDS;
}

+ (CGFloat)precisePoundsFromKg:(CGFloat)kg {
    return kg * KG_TO_POUNDS;
}

+ (CGFloat)convertTemperature:(CGFloat)temp toUnit:(NSString *)unit; {
    if ([unit isEqualToString:@"℃"]) {
        return [self celciusFromFahrenheit:temp];
    }
    else if ([unit isEqualToString:@"℉"]) {
        return [self fahrenheitFromCelcius:temp];
    }
    return -1;
}

+ (NSString *)displayTextForWeightInKG:(float)w {
    if ([[Utils getDefaultsForKey:kUnitForWeight] isEqualToString:UNIT_KG]) {
        return [self stringWithFloatOfOneOrZeroDecimal:@"%.1f kg" float:w];
    } else {
        NSLog(@"peng debug: %f -> %f", w, [Utils poundsFromKg:w]);
        return [NSString stringWithFormat:@"%.1f lbs", [Utils poundsFromKg:w]];
    }
}

+ (NSString *)displayTextForHeightInCM:(float)h {
    if ([[Utils getDefaultsForKey:kUnitForHeight] isEqualToString:UNIT_CM]) {
        return [NSString stringWithFormat:@"%.0f cm", h];
    } else {
        NSInteger feet = [Utils inchesFromCm:h] / 12;
        NSInteger inches = [Utils inchesFromCm:h] % 12;
        return [NSString stringWithFormat:@"%ldft  %ldin", feet, inches];
    }
}

+ (NSString *)displayTextForTemperatureInCelcius:(float)c {
    NSString *unit = [Utils getDefaultsForKey:kUnitForTemp];
    if (!unit) {
        unit = UNIT_FAHRENHEIT;
    }
    float val = c;
    if (![unit isEqual:UNIT_CELCIUS]) {
        val = [Utils fahrenheitFromCelcius:c];
    }

    return [NSString stringWithFormat:@"%.2f %@", val, unit];
}

+ (NSString *)usaZipCodeWithOldString:(NSString *)old replacementString:
        (NSString *)string {
    NSUInteger lengthOfString = string.length;
    // NSInteger validLength = [US_ZIP_CODE_DIGITS[0] intValue];
    NSInteger validLengthExpended = [US_ZIP_CODE_DIGITS[1] integerValue];
    if (!string.length) {
        // allow backspace
        if (old.length == 7) {
            return [old substringToIndex:old.length - 1];
        }
        return nil;
    } else {
        // max length check
        NSString *combined = [NSString stringWithFormat:@"%@%@",
                [old stringByReplacingOccurrencesOfString:@"-" withString:@""],
                string];
        if (combined.length > validLengthExpended) {
            return nil;
        }
        // digital input check
        for (NSInteger index = 0; index < lengthOfString; index++) {
            unichar character = [string characterAtIndex:index];
            if (character < 48) return nil; // 48 unichar for 0
            if (character > 57) return nil; // 57 unichar for 9
        }
        if (combined.length > 5) {
            combined = [NSString stringWithFormat:@"%@-%@",
                    [combined substringWithRange:NSMakeRange(0, 5)],
                    [combined substringWithRange:NSMakeRange(5, combined.length - 5)]];
        }
        return combined;
    }
}

+ (NSString *)cardNumberWithOldString:(NSString *)old replacementString:
        (NSString *)new
{
    NSUInteger lengthOfString = new.length;

    if (!new.length) {
        BOOL isAmericanExpress = [self cardIsAmericanExpress:old];
        NSArray * spacePositions = isAmericanExpress ? @[@4, @11]
                : @[@4, @9, @14];
        // allow backspace
        for (NSInteger i = 0; i < spacePositions.count; i++) {
            NSInteger position = [[spacePositions objectAtIndex:i] integerValue];
            if (old.length == position + 1) {
                // remove one more
                return [old substringToIndex:old.length-1];
            }
        }
        return nil;
    } else {
        NSString * inputString = new;
        if (lengthOfString > 1) {
            // pasted
            inputString = [new stringByReplacingOccurrencesOfString:@","
                    withString:@""];
            inputString = [inputString stringByReplacingOccurrencesOfString:@"."
                    withString:@""];
        }
        
        // digital input check
        for (NSInteger index = 0; index < inputString.length; index++) {
            unichar character = [inputString characterAtIndex:index];
            if (character < 48) return nil; // 48 unichar for 0
            if (character > 57) return nil; // 57 unichar for 9
        }
        
        NSString * tmp = [NSString stringWithFormat:@"%@%@", old, inputString];
        NSMutableString * wholeNumber = [NSMutableString stringWithString:[tmp
                stringByReplacingOccurrencesOfString:@" " withString:@""]];
        
        BOOL isAmericanExpress = [self cardIsAmericanExpress:old];
        NSArray * spacePositions = isAmericanExpress ? @[@4, @11]
                : @[@4, @9, @14];

        // add spacing
        for (NSInteger i = 0; i < spacePositions.count; i++) {
            NSInteger position = [[spacePositions objectAtIndex:i] integerValue];
            if (wholeNumber.length >= position) {
                [wholeNumber insertString:@" " atIndex:position];
            }
        }
        
        NSInteger maxLength = isAmericanExpress ? 17 : 19;
        if (wholeNumber.length > maxLength) {
            return [wholeNumber substringToIndex:maxLength];
        } else {
            return wholeNumber;
        }
    }
}

+ (BOOL)cardIsAmericanExpress:(NSString *)number {
    // American Express 15 numbers, 340-379,
    // other cards are all default by 16 numbers
    // remove the " "
    NSString * newNumber = [number stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (newNumber.length <= 1) return NO;
    else {
        NSInteger start = [[newNumber substringToIndex:2] integerValue];
        return (start >= 34 && start < 38);
    }
}

+ (NSString *)expireWithOldString:(NSString *)old replacementString:
        (NSString *)string {
    NSUInteger lengthOfString = string.length;
    NSInteger seperatePosition = 2;
    NSInteger maxLength = 5;
    if (!string.length) {
        // allow backspace
        if (old.length == seperatePosition + 2) {
            // remove one more
            old = [old substringToIndex:old.length-1];
        }
        return old;
    } else {
        // max length check
        if (old.length + lengthOfString > maxLength) {
            return nil;
        }
        // digital input check
        for (NSInteger index = 0; index < lengthOfString; index++) {
            unichar character = [string characterAtIndex:index];
            if (character < 48) return nil; // 48 unichar for 0
            if (character > 57) return nil; // 57 unichar for 9
        }
        NSInteger num = [string integerValue];
        if (old.length == 0) {
            // MM is 1 -- 12
            if (num >= 2) {
                old = @"0";
                return old;
            }
        } else if (old.length == 1) {
            NSInteger month = [old integerValue] * 10 + num;
            if ((month >= 1) && (month <= 12)) {
                return old;
            }
            else {
                return nil;
            }
        } else if (old.length == seperatePosition) {
            old = [NSString stringWithFormat:@"%@/", old];
        }
        return old;
    }
}

+ (NSString *)cvcWithOldString:(NSString *)old replacementString:
        (NSString *)string {
    NSUInteger lengthOfString = string.length;
    NSInteger maxLength = 4;
    if (!string.length) {
        // allow backspace
        return old;
    } else {
        // max length check
        if (old.length + lengthOfString > maxLength) {
            return nil;
        }
        // digital input check
        for (NSInteger index = 0; index < lengthOfString; index++) {
            unichar character = [string characterAtIndex:index];
            if (character < 48) return nil; // 48 unichar for 0
            if (character > 57) return nil; // 57 unichar for 9
        }
        return string;
    }
}

+ (BOOL)validateCardNumber:(NSString *)cardNumberString {
    // check card number
    // some card is 14 digitals, in this case, we will as "xxxx xxxx xxxx xx" which is 17 len
    return cardNumberString.length >= 17;
}

+ (BOOL)validateCardExpire:(NSString *)expire {
    BOOL passed = YES;
    if (expire.length < 5)
        passed = NO;
    else {
        // check expire
        NSInteger m = [[NSDate date] getMonth];
        NSInteger y = [[NSDate date] getYear];
        if (y > [self getCardYearFromExpire:expire]) {
            passed = NO;
        } else if ((y == [self getCardYearFromExpire:expire]) &&
                (m >= [self getCardMonthFromExpire:expire])) {
            passed = NO;
        }
    }
    return passed;
}

+ (NSInteger)getCardMonthFromExpire:(NSString *)expire {
    if (expire.length < 5)
        return 0;
    else
        return [[expire substringToIndex:2] integerValue];
}

+ (NSInteger)getCardYearFromExpire:(NSString *)expire {
    if (expire.length < 5)
        return 0;
    else
        return [[expire substringFromIndex:3] integerValue] + 2000;
}

+ (BOOL)validateCardCVC:(NSString *)cvc {
    BOOL passed = YES;
    if ((cvc.length < 3) ||
        (cvc.length > 4))
        passed = NO;
    return passed;
}

@end

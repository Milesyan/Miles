//
//  UserDailyData+Symptom.m
//  emma
//
//  Created by Peng Gu on 7/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "UserDailyData+Symptom.h"
#import "DailyLogConstants.h"


@implementation UserDailyData (Symptom)


+ (int64_t)getPhysicalDiscomfortFromPhysicalSymptomOne:(uint64_t)symptom1 symptomTwo:(uint64_t)symptom2
{
    int64_t res1 = [self oldValueFromNewSymptomValue:symptom1 field:SymptomFieldOne type:SymptomTypePhysical];
    int64_t res2 = [self oldValueFromNewSymptomValue:symptom2 field:SymptomFieldTwo type:SymptomTypePhysical];
    return res1 + res2;
}


+ (int64_t)getMoodsFromEmotionalSymptomOne:(uint64_t)symptom1 symptomTwo:(uint64_t)symptom2
{
    int64_t res1 = [self oldValueFromNewSymptomValue:symptom1 field:SymptomFieldOne type:SymptomTypeEmotional];
    int64_t res2 = [self oldValueFromNewSymptomValue:symptom2 field:SymptomFieldTwo type:SymptomTypeEmotional];
    return res1 + res2;
}


+ (int64_t)oldValueFromNewSymptomValue:(uint64_t)symptom field:(SymptomField)field type:(SymptomType)type
{
    if (symptom == 0) {
        return 0;
    }
    
    NSDictionary *mapping = nil;
    if (field == SymptomFieldOne) {
        if (type == SymptomTypePhysical) {
            mapping = @{@(PhysicalSymptomMigraine): @(16),
                        @(PhysicalSymptomCramps): @(32),
                        @(PhysicalSymptomConstipation): @(64),
                        @(PhysicalSymptomDiarrhea): @(64),
                        @(PhysicalSymptomFatigue): @(1024),
                        @(PhysicalSymptomNausea): @(4096),
                        @(PhysicalSymptomBloating): @(8192),
                        @(PhysicalSymptomBackache): @(16384)};
        }
        else {
            mapping = @{@(EmotionalSymptomAngry): @(32),
                        @(EmotionalSymptomMoody): @(128),
                        @(EmotionalSymptomAnxious): @(256)};
        }

    }
    else {
        if (type == SymptomTypePhysical) {
            mapping = @{@(PhysicalSymptomSoreBreasts): @(128),
                        @(PhysicalSymptomPainDuringSex): @(512),
                        @(PhysicalSymptomVaginalPain): @(2048)};
        }
        else {
            mapping = @{@(EmotionalSymptomSad): @(16)};
        }

    }
    
    BOOL hadGIPain = NO;
    int64_t value = 0;
    for (NSNumber *each in mapping) {
        if ([self symptom:each.unsignedLongLongValue inValue:symptom]) {
            
            if ([each isEqualToNumber:@(PhysicalSymptomConstipation)] ||
                [each isEqualToNumber:@(PhysicalSymptomDiarrhea)]) {
                if (hadGIPain) {
                    continue;
                }
                hadGIPain = YES;
            }
            value += [mapping[each] integerValue];
        }
    }
    return value;
}


#pragma mark - Convert Old Value to New Symptom Value

+ (void)convertPhysicalDiscomfortToSymptom:(uint64_t)discomfort completion:(void (^)(uint64_t, uint64_t))completion
{
    uint64_t ps1 = 0;
    uint64_t ps2 = 0;
    
    for (NSNumber *each in PHYSICAL_DISCOMFORT_NAME) {
        int64_t key = [each integerValue];
        if ((discomfort & key) == 0) {
            continue;
        }
        
        if (key == 16) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomMigraine);
        }
        else if (key == 32) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomCramps);
        }
        else if (key == 64) {
            // GI Pain -> Constipation and Diarrhea
            ps1 += (SymptomIntensityModerate << PhysicalSymptomConstipation);
            ps1 += (SymptomIntensityModerate << PhysicalSymptomDiarrhea);
        }
        else if (key == 128) {
            ps2 += (SymptomIntensityModerate << (PhysicalSymptomSoreBreasts - 64));
        }
        else if (key == 512) {
            ps2 += (SymptomIntensityModerate << (PhysicalSymptomPainDuringSex - 64));
        }
        else if (key == 1024) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomFatigue);
        }
        else if (key == 2048) {
            ps2 += (SymptomIntensityModerate << (PhysicalSymptomVaginalPain - 64));
        }
        else if (key == 4096) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomNausea);
        }
        else if (key == 8192) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomBloating);
        }
        else if (key == 16384) {
            ps1 += (SymptomIntensityModerate << PhysicalSymptomBackache);
        }
    }
    
    completion(ps1, ps2);
}


+ (void)convertMoodsToSymptom:(uint64_t)moods completion:(void (^)(uint64_t, uint64_t))completion
{
    uint64_t es1 = 0;
    uint64_t es2 = 0;
    
    for (NSNumber *each in MOODS_NAME) {
        int64_t key = [each integerValue];
        if ((moods & key) == 0) {
            continue;
        }
        
        if (key == 16) {
            es2 += (SymptomIntensityModerate << (EmotionalSymptomSad - 64));
        }
        else if (key == 32) {
            es1 += (SymptomIntensityModerate << EmotionalSymptomAngry);
        }
//        else if (key == 64) {
//            ps1 += (SymptomIntensityModerate << EmotionalSymptomDepressed);
//        }
        else if (key == 128) {
            es1 += (SymptomIntensityModerate << EmotionalSymptomMoody);
        }
        else if (key == 256) {
            es1 += (SymptomIntensityModerate << EmotionalSymptomAnxious);
        }
    }
    
    completion(es1, es2);
}


#pragma mark - Symptoms

+ (NSArray *)allSymptomsInField:(SymptomField)field type:(SymptomType)type
{
    if (type == SymptomTypePhysical) {
        return field == SymptomFieldOne ? PhysicalSymptomFieldOne : PhysicalSymptomFieldTwo;
    }
    return field == SymptomFieldOne ? EmotionalSymptomFieldOne : EmotionalSymptomFieldTwo;
}


+ (NSDictionary *)getSymptomsFromValue:(uint64_t)value field:(SymptomField)field type:(SymptomType)type
{
    if (value == 0) {
        return [NSDictionary dictionary];
    }
    
    NSMutableDictionary *symps = [NSMutableDictionary dictionary];
    uint64_t offset = field == SymptomFieldOne ? 0 : 64;
    
    for (NSNumber *symp in [self allSymptomsInField:field type:type]) {
        uint64_t sympIndex = [symp unsignedLongLongValue];
        uint64_t intensity = (value >> (sympIndex-offset)) & 0xf;
        if (intensity > 0) {
            symps[symp] = @(intensity);
        }
    }
    
    return symps;
}


+ (uint64_t)getValueFromSymptoms:(NSDictionary *)symptoms field:(SymptomField)field type:(SymptomType)type
{
    NSArray *allSymps = [self allSymptomsInField:field type:type];
    uint64_t offset = field == SymptomFieldOne ? 0 : 64;
    uint64_t value = 0;
    
    for (NSNumber *symp in symptoms) {
        uint64_t sympIndex = [symp unsignedLongLongValue];
        uint64_t intensity = [symptoms[symp] unsignedLongLongValue];
        
        if ([allSymps containsObject:symp]) {
            value += intensity << (sympIndex - offset);
        }
    }
    return value;
}


+ (void)convertSymptomsToValues:(NSDictionary *)symptoms
                           type:(SymptomType)type
                     completion:(void (^)(uint64_t, uint64_t))completion
{
    NSMutableDictionary *symp1 = [NSMutableDictionary dictionary];
    NSMutableDictionary *symp2 = [NSMutableDictionary dictionary];
    for (NSNumber *each in symptoms) {
        if ([each integerValue] >= 64) {
            symp2[each] = symptoms[each];
        }
        else {
            symp1[each] = symptoms[each];
        }
    }
    
    uint64_t val1 = [self getValueFromSymptoms:symp1 field:SymptomFieldOne type:type];
    uint64_t val2 = [self getValueFromSymptoms:symp2 field:SymptomFieldTwo type:type];
    
    completion(val1, val2);
}


+ (NSDictionary *)getSymptomsFromFieldOneValue:(uint64_t)value1
                                 fieldTwoValue:(uint64_t)value2
                                          type:(SymptomType)type
{
    if (value1 == 0 && value2 == 0) {
        return [NSDictionary dictionary];
    }
    
    NSDictionary *symptoms1 = [self getSymptomsFromValue:value1 field:SymptomFieldOne type:type];
    NSDictionary *symptoms2 = [self getSymptomsFromValue:value2 field:SymptomFieldTwo type:type];
    NSMutableDictionary *merged = [NSMutableDictionary dictionaryWithDictionary:symptoms1];
    [merged addEntriesFromDictionary:symptoms2];
    
    return merged;
}


+ (uint64_t)removeSymptom:(uint64_t)symptom fromValue:(uint64_t)value
{
    if (symptom >= 64) {
        symptom -= 64;
    }
    
    uint64_t intensity = (value >> symptom) & 0xf;
    if (intensity == 0) {
        return value;
    }
    
    value = value - (intensity << symptom);
    return value;
}


+ (BOOL)symptom:(uint64_t)symptom inValue:(uint64_t)value
{
    return [self intensityForSymptom:symptom inValue:value] == SymptomIntensityNone ? NO : YES;
}


+ (SymptomIntensity)intensityForSymptom:(uint64_t)symptom inValue:(uint64_t)value
{
    if (symptom >= 64) {
        symptom -= 64;
    }
    
    uint64_t intensity = (value >> symptom) & 0xf;
    return [NSNumber numberWithUnsignedLongLong:intensity].integerValue;
}


#pragma mark - Helpers
- (NSDictionary *)getPhysicalSymptoms
{
    return [UserDailyData getSymptomsFromFieldOneValue:self.physicalSymptom1
                                         fieldTwoValue:self.physicalSymptom2
                                                  type:SymptomTypePhysical];
}


- (NSDictionary *)getEmotionalSymptoms
{
    return [UserDailyData getSymptomsFromFieldOneValue:self.emotionalSymptom1
                                         fieldTwoValue:self.emotionalSymptom2
                                                  type:SymptomTypeEmotional];
}


@end






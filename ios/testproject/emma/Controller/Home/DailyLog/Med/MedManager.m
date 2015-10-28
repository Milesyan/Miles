//
//  MedManager.m
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "MedManager.h"
#import "SyncableAttribute.h"
#import "UserMedicalLog.h"
#import "UserDailyData.h"
#import "UserStatusDataManager.h"

#define DRUGS_PLIST_NAME @"drugs"

#define kId @"id"
#define kName @"name"
#define kForm @"form"
#define kTotal @"total"
#define kPerDosage @"perDosage"
#define kReminderId @"reminderId"
#define kSourceType @"sourceType"

@implementation Medicine

- (NSDictionary *)toData {
    GLLog(@"total; %d",self.total);
    return @{
             kId: self.id,
             kName: self.name,
             kForm: self.form,
             kTotal: @(self.total),
             kPerDosage: @(self.perDosage),
             kReminderId: self.reminderUUID? self.reminderUUID: @"",
             kSourceType: @(self.sourceType)
             };
}

+ (Medicine *)fromData:(NSDictionary *)data {
    Medicine *med = [[Medicine alloc] init];
    med.id = data[kId];
    med.name = data[kName];
    med.form = data[kForm];
    med.total = [data[kTotal] integerValue];
    med.perDosage = [data[kPerDosage] integerValue];
    med.reminderUUID = data[kReminderId];
    med.sourceType = [data[kSourceType] integerValue];
    return med;
}

@end


@interface MedManager ()

@property (nonatomic, strong, readwrite) NSMutableDictionary *updatedMedLogs;

@end


@implementation MedManager


+ (NSArray *)medForms {
    static NSArray *forms;
    if (!forms) {
        forms = @[
                  @"Cream",
                  @"Injectable",
                  @"Oil/Drops",
                  @"Patches",
                  @"Solution",
                  @"Spray",
                  @"Suppository",
                  @"Tablet",
                  @"Vaginal Ring",
                  @"Other",
                  ];
    }
    return forms;
}

+ (NSString *)unitOfPerTakeForForm:(NSString *)form withPlural:(BOOL)plural {
    static NSDictionary *d;
    if (!d) {
        d = @{
              @"Cream":@[@"application", @"applications"],
              @"Injectable": @[@"injection", @"injections"],
              @"Oil/Drops": @[@"drop", @"drops"],
              @"Patches": @[@"patch", @"patches"],
              @"Solution": @[@"solution", @"solutions"],
              @"Spray": @[@"spray", @"sprays"],
              @"Suppository": @[@"suppository", @"suppositories"],
              @"Tablet": @[@"tablet", @"tablets"],
              @"Vaginal Ring": @[@"ring", @"rings"],
              @"Other": @[@"", @""],
              };
    }
    
    if (form) {
        NSArray *units = d[form];
        if (units) {
            return units[(plural? 1: 0)];
        }
    }
    
    return @"";
}

+ (NSString *)unitOfTotalInPackageForForm:(NSString *)form withPlural:(BOOL)plural {
    static NSDictionary *d;
    if (!d) {
        d = @{
              @"Cream":@[@"gram", @"grams"],
              @"Injectable": @[@"ml", @"ml"],
              @"Oil/Drops": @[@"ml", @"ml"],
              @"Patches": @[@"patch", @"patches"],
              @"Solution": @[@"ml", @"solutions"],
              @"Spray": @[@"ml", @"sprays"],
              @"Suppository": @[@"suppository", @"suppositories"],
              @"Tablet": @[@"tablet", @"tablets"],
              @"Vaginal Ring": @[@"ring", @"rings"],
              @"Other": @[@"", @""],
              };
    }
    
    if (form) {
        NSArray *units = d[form];
        if (units) {
            return units[(plural? 1: 0)];
        }
    }
    
    return @"";
}

+ (NSString *)getForm:(NSString *)medName {
    return [self medDict][medName];
}

+ (NSDictionary *)medDict {
    static NSDictionary *dict;
    if (!dict) {
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *plistPath = [NSString stringWithFormat:@"%@/%@.plist",docDir,DRUGS_PLIST_NAME];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:plistPath]) {
            SyncableAttribute *syncableAttrDrugs = [SyncableAttribute tsetWithName:ATTRIBUTE_DRUGS];
            if (syncableAttrDrugs.stringifiedAttribute) {
                [self writeDrugs:syncableAttrDrugs.stringifiedAttribute];
            }
        }
        if (![fileManager fileExistsAtPath:plistPath]) {
            NSString *path = [[NSBundle mainBundle] bundlePath];
            plistPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", DRUGS_PLIST_NAME]];
        }
        
        dict = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    }
    return dict;
}

+ (NSArray *)medList {
    return [[self medDict] allKeys];
}

+ (void)writeDrugs:(NSString *)raw {
    [Utils writeString:raw toDomainFile:DRUGS_PLIST_NAME];
}


+ (NSDictionary *)medsForUser:(User *)user {
    NSDictionary *meds = user.settings.meds;
    if (!meds || ![meds isKindOfClass:[NSDictionary class]]) {
        return @{};
    } else {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSDictionary *data in meds.allValues) {
            Medicine *med = [Medicine fromData:data];
            [dict setObject:med forKey:med.name];
        }
        return dict;
    }
}

+ (Medicine *)userMedWithName:(NSString *)medName {
    NSDictionary *dict = [MedManager medsForUser:[User currentUser]];
    return [dict objectForKey:medName];
}

+ (void)user:(User *)user upsertMed:(Medicine *)med {
    NSDictionary *meds = user.settings.meds;
    if (!meds || ![meds isKindOfClass:[NSDictionary class]]) {
        meds = @{};
    }
    
    NSMutableDictionary *md = [NSMutableDictionary dictionaryWithDictionary:meds];
    for (NSDictionary *m in md.allValues) {
        if ([m[@"id"] isEqual:med.id]) {
            [md removeObjectForKey:m[@"name"]];
            break;
        }
    }
    [md setObject:[med toData] forKey:med.name];
    [user.settings update:@"meds" value:[NSDictionary dictionaryWithDictionary:md]];
    [user save];
    
    [user publish:EVENT_MED_UPDATED];
}

+ (void)user:(User *)user removeMed:(NSString *)medName {
    NSDictionary *meds = user.settings.meds;
    if (!meds || ![meds isKindOfClass:[NSDictionary class]]) {
        //
    } else {
        NSMutableDictionary *medsCopy = [NSMutableDictionary dictionaryWithDictionary:meds];
        NSDictionary *med = medsCopy[medName];
        if (med && [Utils isNotEmptyString:med[kReminderId]]) {
            [Reminder deleteByUUID:med[kReminderId]];
        }
        [medsCopy removeObjectForKey:medName];
        [user.settings update:@"meds" value:[NSDictionary dictionaryWithDictionary:medsCopy]];
        [user save];
    }
}


#pragma mark - data

@synthesize userAddedMeds = _userAddedMeds;

- (instancetype)initWithDate:(NSString *)date
{
    self = [super init];
    if (self) {
        _date = date;
        _medLogs = [MedManager medLogsOnDate:date];
        _updatedMedLogs = [NSMutableDictionary dictionary];
    }
    return self;
}


- (void)setDate:(NSString *)date
{
    if (![_date isEqualToString:date]) {
        _date = date;
        _medLogs = [MedManager medLogsOnDate:_date];
        _updatedMedLogs = [NSMutableDictionary dictionary];
    }
}

+ (NSArray *)defaultFertilityMeds
{
    static NSArray *defaultFertilityMeds;
    if (!defaultFertilityMeds) {
        defaultFertilityMeds = @[@"Clomiphene citrate (Clomid; Serophene)",
                                 @"Human menopausal gonadotropin or hMG (Repronex; Pergonal)",
                                 @"Follicle-stimulating hormone or FSH (Gonal-F; Follistim)",
                                 @"Gonadotropin-releasing hormone (Gn-RH)",
                                 @"Metformin (Glucophage)",
                                 @"Bromocriptine (Parlodel)"];
    }
    return defaultFertilityMeds;
}

- (NSArray *)defaultFertilityMeds
{
    return [MedManager defaultFertilityMeds];
}


- (NSArray *)userAddedMeds
{
    if (!_userAddedMeds) {
        NSDictionary *userMeds = [MedManager medsForUser:[User currentUser]];
        _userAddedMeds = userMeds.allKeys;
    }
    return _userAddedMeds;
}


- (void)updateMedLog:(NSString *)medName withValue:(NSInteger)value
{
    NSNumber *loggedValue = self.medLogs[medName];
    if (loggedValue.integerValue == value) {
        [self.updatedMedLogs removeObjectForKey:medName];
    }
    else {
        self.updatedMedLogs[medName] = @(value);
    }
    
    if ([self.delegate respondsToSelector:@selector(medManangerDidUpdateMedLog:withValue:)]) {
        [self.delegate medManangerDidUpdateMedLog:medName withValue:value];
    }
}


- (BOOL)hasUpdatesForMedLogs
{
    return self.updatedMedLogs.count > 0;
}


- (NSUInteger)numberOfLogs
{
    NSInteger num = self.medLogs.count;
    NSMutableArray *userMeds = [MedManager medsForUser:[User currentUser]].allKeys.mutableCopy;
    [userMeds addObjectsFromArray:[MedManager defaultFertilityMeds]];
    
    for (NSString *each in self.medLogs) {
        NSNumber *value = self.medLogs[each];
        if (value.integerValue == 0 || ![userMeds containsObject:each]) {
            num -= 1;
        }
    }
    
    for (NSString *medName in self.updatedMedLogs) {
        if (![self.medLogs objectForKey:medName]) {
            // new added med log
            num += 1;
        }
        else {
            // updated med log
            NSUInteger oldValue = [self.medLogs[medName] integerValue];
            NSUInteger value = [self.updatedMedLogs[medName] integerValue];
            if (value == 0) {
                num -= 1;
            }
            else if (oldValue == 0) {
                num += 1;
            }
        }
    }
    return num;
}


- (void)saveUpdatedMedLogs
{
    User *user = [User currentUser];
    
    // for fertility treatment user, we save to UserMedicalLog
    //  for other users, save to UserDailyData
    UserStatus *userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:self.date forUser:[User userOwnsPeriodInfo]];
    if ([userStatus inTreatment]) {
        for (NSString *medName in self.updatedMedLogs) {
            NSString *dataKey = [kMedicationItemKeyPrefix stringByAppendingString:medName];
            NSString *dataValue = [self.updatedMedLogs[medName] stringValue];
            
            UserMedicalLog *log = [UserMedicalLog medicalLogWithKey:dataKey date:self.date user:user];
            if (!log) {
                log = [UserMedicalLog newInstance:[User currentUser].dataStore];
                log.date = self.date;
                log.dataKey = dataKey;
                log.user = user;
            }
            
            [log update:@"dataValue" value:dataValue];
        }
    }
    else {
        for (NSString *medName in self.updatedMedLogs) {
            UserDailyData *dailyData = [UserDailyData tset:self.date forUser:user];
            NSNumber *value = self.updatedMedLogs[medName];
            [dailyData logMed:medName withValue:value];
        }
    }
}


- (void)medAdded:(NSString *)medName
{
    _userAddedMeds = nil;
}


- (void)medDeleted:(NSString *)medName
{
    _userAddedMeds = nil;
    [self.updatedMedLogs removeObjectForKey:medName];
}


- (void)med:(NSString *)oldName updatedWithNewName:(NSString *)newName
{
    _userAddedMeds = nil;
    
    NSNumber *value = self.updatedMedLogs[oldName];
    if (value) {
        [self.updatedMedLogs removeObjectForKey:oldName];
        self.updatedMedLogs[newName] = value;
    }
}


+ (NSDictionary *)medLogsOnDate:(NSString *)date
{
    NSMutableDictionary *loggedMeds = [NSMutableDictionary dictionary];
    NSMutableArray *userMeds = [MedManager medsForUser:[User currentUser]].allKeys.mutableCopy;
    
    
    // For fertility treatment users, we get logs from UserMedicalLog;
    //  for others, we get logs from UserDailyData
    UserStatus *userStatus = [[UserStatusDataManager sharedInstance] statusOnDate:date forUser:[User userOwnsPeriodInfo]];
    if ([userStatus inTreatment]) {
        [userMeds addObjectsFromArray:[MedManager defaultFertilityMeds]];
        
        NSSet *set = [UserMedicalLog medicalLogsOnDate:date forUser:[User currentUser]];
        for (UserMedicalLog *each in set) {
            if ([each.dataKey hasPrefix:kMedicationItemKeyPrefix]) {
                NSString *key = [each.dataKey substringFromIndex:kMedicationItemKeyPrefix.length];
                if ([userMeds containsObject:key]) {
                    loggedMeds[key] = @([each.dataValue integerValue]);
                }
            }
        }
    }
    else {
        UserDailyData *dailyData = [UserDailyData getUserDailyData:date forUser:[User currentUser]];
        NSDictionary *meds = [dailyData medsLog];
        for (NSString *each in meds.allKeys) {
            if ([userMeds containsObject:each]) {
                loggedMeds[each] = meds[each];
            }
        }
    }
    
    return loggedMeds;
}


@end





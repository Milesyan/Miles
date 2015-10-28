//
//  Insight.m
//  emma
//
//  Created by Jirong Wang on 8/1/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "Insight.h"
#import "User.h"
#import "Contact.h"

#define MAX_INSIGHTS 3

@implementation Insight

@dynamic title;
@dynamic body;
@dynamic link;
@dynamic unread;
@dynamic date;
@dynamic type;
@dynamic source;
@dynamic expire;
@dynamic timeCreated;
@dynamic priority;
@dynamic likeCount;
@dynamic liked;
@dynamic shareCount;
@dynamic pageUrl;
@dynamic user;

- (NSDictionary *)attrMapper {
    return @{
             @"type"         : @"type",
             @"title"        : @"title",
             @"body"         : @"body",
             @"date"         : @"date",
             @"source"       : @"source",
             @"link"         : @"link",
             @"priority"     : @"priority",
             @"time_created" : @"timeCreated",
             @"expire"       : @"expire",
             @"like_count"   : @"likeCount",
             @"share_count"  : @"shareCount",
             @"liked"        : @"liked",
             @"page_url"     : @"pageUrl",
             };
}


+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    Insight *ins = [Insight tset:[data objectForKey:@"type"] forDate:[data objectForKey:@"date"] forUser:user];
    [ins updateAttrsFromServerData:data];
    return ins;
}

+ (id)tset:(NSNumber *)insightType forDate:(NSString *)date forUser:(User *)user {
    Insight *obj = [self fetchObject:@{
        @"type" : insightType,
        @"date" : date,
        @"user.id" : user.id
    } dataStore:user.dataStore];
    if (!obj) {
        obj = [self newInstance:user.dataStore];
        obj.user = user;
        obj.type = [insightType longLongValue];
        obj.date = date;
        obj.unread = YES;
    }
    return obj;
}

-(DataStore *)dataStore {
    return self.user.dataStore;
}

- (void)setDirty:(BOOL)val {
    [super setDirty:val];
    if (val) {
        self.user.dirty = YES;
        
    }
}

/*
+ (void)removeReadInsights:(User *)user {
    for (Insight *ins in [user.insights copy]) {
        if (ins.unread == NO) {
            ins.user = nil;
            [Insight deleteInstance:ins];
        }
    }
}
 */

+ (NSArray *)sortedInsightsForCurrentUserWithDate:(NSString *)date
{
    NSSortDescriptor *sorter = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO];
    NSArray *results = [[User currentUser].insights sortedArrayUsingDescriptors:@[sorter]];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"date != nil AND date == %@", date];
    return [results filteredArrayUsingPredicate:predicate];
}


+ (NSArray *)sortedInsightsForGenius:(User *)user {
    NSSortDescriptor *dateSD = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    NSSortDescriptor *prioritySD = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO];
    NSSortDescriptor *typeSD = [NSSortDescriptor sortDescriptorWithKey:@"type" ascending:YES];
    NSArray * insights = [user.insights sortedArrayUsingDescriptors:@[dateSD, prioritySD, typeSD]];
    
    /*
    for (Insight * ins in insights) {
        NSLog(@"AAAAAA jr debug, date = %@, id = %lld", ins.date, ins.type);
    }
    */
    
    if (insights.count == 0) {
        return @[];
    } else {
        NSString * currentDate = nil;
        NSMutableArray * result = [[NSMutableArray alloc] init];
        for (Insight * ins in insights) {
            if (currentDate == nil) {
                currentDate = ins.date;
            }
            if ([ins.date isEqualToString:currentDate]) {
                [result addObject:ins];
                if (result.count >= 3) {
                    break;
                }
            }
        }
        return result;
    }
}

/*
+ (void)cutInsights:(User *)user {
    NSArray * sortedInsights = [Insight sortedInsights:user];
    for (int i = MAX_INSIGHTS; i < sortedInsights.count; i++) {
        Insight *ins = sortedInsights[i];
        [Insight deleteInstance:ins];
        ins.user = nil;
    }
}
*/

+ (void)upsertInsightList:(NSArray *)insightList forUser:(User *)user { 
    if ((!insightList) || (insightList.count == 0)) {
        return;
    }
    // we do not need remove insights now, because insights now are based on date
    
    // 1. remove read insights
    // [Insight removeReadInsights:user];
    
    // 2. insert new insights
    BOOL changed = NO;
    for (NSDictionary *d in insightList) {
        if (!changed) {
            // check if any changes
            Insight *obj = [self fetchObject:@{
                                               @"type" : [d objectForKey:@"type"] ,
                                               @"date" : [d objectForKey:@"date"],
                                               @"user.id" : user.id
                                               } dataStore:user.dataStore];
            if (!obj) {
                changed = YES;
            }
        }
        [Insight upsertWithServerData:d forUser:user];
    }
    // 3. cut off insights
    // [Insight cutInsights:user];
    
    [user save];
    if (changed) {
        [user publish:EVENT_INSIGHT_UPDATED];
    }
}

+ (void)upsertTestInsightListForUser:(User *)user {
    // get 0 - 4
    NSInteger r = arc4random() % 5;
    NSArray * _testData = [Insight testData];
    NSInteger total = _testData.count;
    
    NSMutableArray * array = [[NSMutableArray alloc] init];
    for (int i = 0; i < r; i++) {
        NSInteger j = arc4random() % total;
        NSDictionary * d = _testData[j];
        NSMutableDictionary * dd = [[NSMutableDictionary alloc] initWithDictionary:d];
        [dd setObject:@([[NSDate date] timeIntervalSince1970]) forKey:@"time_created"];
        [dd setObject:@([[Utils dateByAddingDays:1 toDate:[NSDate date]] timeIntervalSince1970]) forKey:@"expire"];
        
        [array addObject:dd];
    }
    
    return [Insight upsertInsightList:array forUser:user];
}

+ (void)setInsightsRead:(NSDate *)date {
    NSArray * ary = [Insight sortedInsightsForCurrentUserWithDate:[date toDateLabel]];
    for (Insight * ins in ary) {
        if (ins.unread == YES) {
            [ins update:@"unread" boolValue:NO];
            [ins.user save];
        }
    }
}

+ (NSArray *)createPushRequestForUser:(User *)user {
    NSMutableArray *readInsights = [[NSMutableArray alloc] init];
    for (Insight *ins in user.insights) {
        if (ins.unread == NO) {
            if ((ins.changedAttributes != nil) && ([ins.changedAttributes containsObject:@"unread"])) {
                [readInsights addObject:@{@"type": @(ins.type)}];
            }
        }
    }
    return readInsights;
}

+ (NSArray *)testData {
    return @[
             @{
                 @"type": @1,
                 @"title": @"Your level of cervical mucus (CM) is in an optimal level.",
                 @"body": @"Studies have shown that having intercourse while your cervical mucus is optimal (such as now) maximizes the chance of conception, regardless of when you ovulate.",
                 @"source": @"The Mayo Clinic",
                 @"link": @"http://www.mayoclinic.com/health/polycystic-ovary-syndrome/DS00423",
                 @"priority": @200,
                 },
             @{
                 @"type": @14,
                 @"title": @"Semen analysis is important!",
                 @"body": @"In approximately 40% of infertile couples, the male partner is either the sole or contributing cause of infertility. Therefore a semen analysis is important for couples trying to concieve for more than 6 months. ",
                 @"source": @"The Mayo Clinic",
                 @"link": @"http://www.mayoclinic.com/health/home-pregnancy-tests/PR00100/NSECTIONGROUP=2",
                 @"priority": @200,
                 },
             @{
                 @"type": @25,
                 @"title": @"You have entered a BMI of (user BMI).",
                 @"body": @"Several studies have demonstrated that women with elevated BMI have decreased levels of fertility. However the good news is that even a limited amount of weight loss can help! ",
                 @"source": @"Reproductive Biomedicine Online",
                 @"link": @"http://www.rbmojournal.com/article/S1472-6483(11)00351-8/fulltext?refuid=S1472-6483(11)00416-0&refissn=1472-6483",
                 @"priority": @80,
                 },
             @{
                 @"type": @37,
                 @"title": @"Great Start!",
                 @"body": @"Untimed intercourse averaging once per week would produce a 15% chance of conception per cycle  - but we can do better than that! ",
                 @"source": @"New England Journal of Medicine",
                 @"link": @"http://www.nejm.org/doi/full/10.1056/NEJM199512073332301#t=articleResults",
                 @"priority": @100,
                 },
             @{
                 @"type": @40,
                 @"title": @"Killer cramps are not normal!",
                 @"body": @"While some cramping is to be expected during your period, painful cramping that might make you miss work or other engagements is not normal and may be a sign of endometriosis. ",
                 @"source": @"The Endometriosis Foundation of America",
                 @"link": @"http://www.endofound.org/endometriosis",
                 @"priority": @80,
                 },
             @{
                 @"type": @63,
                 @"title": @"You've been trying to get pregnant for (insert # of months) months.",
                 @"body": @"Studies show that women over the age 35 who have not successfully concieved after 6 months of trying would benefit from speaking to their specialist or doctor. ",
                 @"source": @"Human Reproduction",
                 @"link": @"http://humrep.oxfordjournals.org/content/18/9/1959.full",
                 @"priority": @100,
                 },
             @{
                 @"type": @74,
                 @"title": @"Great! You keep taking your prenatal vitamins! ",
                 @"body": @"Research suggests that prenatal vitamins decrease the risk of low birth weight.",
                 @"source": @"The Mayo Clinic",
                 @"link": @"http://www.mayoclinic.com/health/prenatal-vitamins/PR00160",
                 @"priority": @80,
                 },
             ];
}


- (NSString *)insightPageUrl {
    return self.pageUrl;
//    return [NSString stringWithFormat:@"%@/%@/%d", EMMA_BASE_URL, INSIGHT_PAGE_URL, self.type];
}

@end

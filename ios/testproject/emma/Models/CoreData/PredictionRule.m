//
//  PredictionRules.m
//  emma
//
//  Created by Xin Zhao on 13-3-6.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

#import "PredictionRule.h"
#import "User.h"

@interface PredictionRule()
@end

@implementation PredictionRule

@dynamic args;
@dynamic body;
@dynamic name;
@dynamic user;

- (NSDictionary *)attrMapper {
    return @{@"name"           : @"name",
             @"args"           : @"args",
             @"body"           : @"body"
             };
}

- (NSArray *)getBody {
    NSData *data = [self.body dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

- (NSArray *)getArgs {
    NSData *data = [self.args dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
}

+ (id)upsertWithServerData:(NSDictionary *)data forUser:(User *)user {
    PredictionRule *rule = [PredictionRule tset:[data objectForKey:@"name"] forUser:user];
    [rule updateAttrsFromServerData:data];
    return rule;
}

+ (id)tset:(NSString *)name forUser:(User *)user {
    DataStore *ds = user.dataStore;
    PredictionRule *rule = (PredictionRule *)[self fetchObject:@{
                                             @"user.id" : user.id,
                                             @"name" : name
                                             } dataStore:ds];
    if (!rule) {
        rule = [PredictionRule newInstance:ds];
        rule.name = name;
        rule.user = user;
    }
    return rule;
}

+ (id)getInstance:(NSString *)name forUser:(User *)user {
    DataStore *ds = user.dataStore;
    PredictionRule *rule = (PredictionRule *)[self fetchObject:@{
                                                @"user.id" : user.id,
                                                @"name" : name
                                                } dataStore:ds];
    return rule;
}

+ (void)loadLocalRulesForUser:(User *)user {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"predictionrules" ofType:@"txt"];
    if (filePath) {
        NSString *myText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        if (myText) {
//            GLLog(@"read content %@", myText);
            NSArray *rulesArray = [myText componentsSeparatedByString:@"\n"];
//            GLLog(@"rules array %@", rulesArray);
            for (int i = 0; i < [rulesArray count]; i += 3) {
                if ([self getInstance:[rulesArray objectAtIndex:i] forUser:user]) {
                    continue;
                }
                [self upsertWithServerData:@{@"name":[rulesArray objectAtIndex:i],
                 @"args":[rulesArray objectAtIndex:i+1],
                 @"body":[rulesArray objectAtIndex:i+2]} forUser:user];
            }
        }
    }
}

@end

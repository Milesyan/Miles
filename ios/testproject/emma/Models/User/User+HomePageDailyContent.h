//
//  User+HomePageDailyContent.h
//  emma
//
//  Created by ltebean on 15-3-13.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "User.h"

@interface User (HomePageDailyContent)
- (void)fetchDailyContentOnDate:(NSDate *)date forceSendCall:(BOOL)forceSendCall forceRenegerate:(BOOL)forceRegenerate completionHandler:(void (^)(BOOL, NSDate *))completionHandler;
@end

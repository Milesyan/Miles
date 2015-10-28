//
//  User+Prediction.h
//  emma
//
//  Created by ltebean on 15/8/28.
//  Copyright © 2015年 Upward Labs. All rights reserved.
//

#import "User.h"

@interface User (Prediction)
- (void)turnOffPrediction;
- (void)turnOnPredictionWithLatestPeriod:(NSDictionary *)period;
@end

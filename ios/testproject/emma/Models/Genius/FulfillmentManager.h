//
//  FulfillmentManager.h
//  emma
//
//  Created by Xin Zhao on 14-1-3.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FulfillmentManager : NSObject

typedef void (^FulfillmentRequestCallback)(NSDictionary *result, NSError *error);

+ (void)sendFulfillmentRequestWithGoods:(NSDictionary *)goodsInfo completion:
        (FulfillmentRequestCallback) callback;
+ (void)sendTestNotification:(NSInteger)goodsId;

@end

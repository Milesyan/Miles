//
//  FulfillmentManager.m
//  emma
//
//  Created by Xin Zhao on 14-1-3.
//  Copyright (c) 2014年 Upward Labs. All rights reserved.
//

#import "FulfillmentManager.h"
#import "Network.h"
#import "User.h"


@implementation FulfillmentManager

+ (void)sendFulfillmentRequestWithGoods:(NSDictionary *)goodsInfo completion:(FulfillmentRequestCallback)callback{
    NSString *url = @"users/fulfillment/purchase";
    NSDictionary *request = [[User currentUser] postRequest:
            @{@"goods_info": goodsInfo}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES timeout:NETWORK_PAYMENT_TIMEOUT completionHandler:^(NSDictionary *result, NSError *err) {
                if (err) {
                    GLLog(@"zx debug sth wrong");
                }
                else {
                    GLLog(@"zx debug purchase done!");
                }
                if (callback) {
                    callback(result, err);
                }
            }];
}

+ (void)sendTestNotification:(NSInteger)goodsId {
    NSString *url = @"users/fulfillment/send_notif";
    NSDictionary *request = [[User currentUser] postRequest:
            @{@"goods_type": @(goodsId)}];
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:
            ^(NSDictionary *result, NSError *err){}];
}

@end

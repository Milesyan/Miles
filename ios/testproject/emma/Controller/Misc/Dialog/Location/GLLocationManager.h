//
//  GLLocationManager.h
//  emma
//
//  Created by Jirong Wang on 12/10/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^GLLocationSuccessCallback)(NSString *location);
typedef void (^GLLocationCancelCallback)();

@interface GLLocationManager : NSObject

- (void)startUpdatingLocation:(GLLocationSuccessCallback)successCallback failCallback:(GLLocationCancelCallback)failCallback;

@end

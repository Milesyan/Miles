//
//  GLLocationManager.m
//  emma
//
//  Created by Jirong Wang on 12/10/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "GLLocationManager.h"
#import "User.h"
#import <CoreLocation/CoreLocation.h>

@interface GLLocationManager () <CLLocationManagerDelegate> {
    GLLocationSuccessCallback successCb;
    GLLocationCancelCallback failCb;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation GLLocationManager

- (void)startUpdatingLocation:(GLLocationSuccessCallback)successCallback failCallback:(GLLocationCancelCallback)failCallback {
    successCb = successCallback;
    failCb    = failCallback;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    if (IOS8_OR_ABOVE) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (locations.count <= 0) {
        return;
    }
    CLLocation * loc = (CLLocation *)locations.lastObject;
    [User currentUser].currentLocation = loc;
    [self.locationManager stopUpdatingLocation];
    
    NSString * locationStr = [NSString stringWithFormat:@"%@, %@", @(loc.coordinate.latitude), @(loc.coordinate.longitude)];
    
    [Logging log:USER_LOCATION_UPDATED eventData:@{@"location": locationStr}];
    
    if (successCb) {
        // to avoid callback be called multiple times
        GLLocationSuccessCallback _successCb = successCb;
        successCb = nil;
        failCb = nil;
        _successCb(locationStr);
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (failCb) {
        // to avoid callback be called multiple times
        GLLocationCancelCallback _failCb = failCb;
        successCb = nil;
        failCb = nil;
        _failCb();
    }
}




@end

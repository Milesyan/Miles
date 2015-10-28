//
//  Network.h
//  emma
//
//  Created by Ryan Ye on 2/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define EVENT_NETWORK_ERROR @"network_error"
#define EVENT_UPGRADE_APP_VERSION  @"upgrade_app_version"

#define EMMA_ERROR_DOMAIN_NETWORK   @"EMMA_NETWORK_ERROR"

typedef NS_ENUM(NSInteger, EmmaNetworkErrorCode) {
    EmmaNetworkErrorUnknown = 1,
    EmmaNetworkErrorServerError = 2,
};

typedef NS_ENUM(NSInteger, EmmaImageType) {
    EmmaImageTypePNG = 1,
    EmmaImageTypeJPEG = 2,
};

typedef void(^JSONResponseHandler)(NSDictionary *response, NSError *err);
typedef void(^ImageResponseHandler)(UIImage *image, NSError *err);

@interface Network : NSObject

@property (nonatomic, strong)NSDate *remindUpgradeTime;
@property (nonatomic, strong)NSOperationQueue *callbackQueue;

+ (Network *)sharedNetwork;

// only for sending synce logs
- (NSDictionary *)syncPost:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login timeout:(NSTimeInterval)timeout error:(NSError **)error;
// only for sending debug report
- (void)asyncPostFile:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login files:(NSArray *)files completionHandler:(JSONResponseHandler)handler;

// normal APIs
- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login completionHandler:(JSONResponseHandler)handler;
- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login timeout:(NSTimeInterval)timeout completionHandler:(JSONResponseHandler)handler;
- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login image:(UIImage *)image completionHandler:(JSONResponseHandler)handler;
- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login images:(NSDictionary *)images completionHandler:(JSONResponseHandler)handler;

- (void)get:(NSString *)url data:(NSDictionary *)data completionHandler:(JSONResponseHandler)handler;
- (void)get:(NSString *)url completionHandler:(JSONResponseHandler)handler;
- (void)getImage:(NSString *)url completionHandler:(ImageResponseHandler)handler;

- (void)getNonGlowURL:(NSString *)url
                query:(NSDictionary *)query
    completionHandler:(JSONResponseHandler)handler;
- (void)pingWithCompletionHandler:(void(^)(BOOL))completionHandler;

@end

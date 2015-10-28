//
//  Network.m
//  emma
//
//  Created by Ryan Ye on 2/7/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//
#include <stdlib.h>
#import "Network.h"
#import "Utils.h"

#define REQUEST_RC_TOO_OLD_VERSION -100
#define REQUEST_RC_USER_REMOVED    -200
#define REQUEST_RC_TOKEN_EXPIRED   -300

@interface Network()

@end

@implementation Network

+ (Network *)sharedNetwork {
    static Network *_network = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _network = [[Network alloc] init];
    });
    return _network;
}

- (NSOperationQueue *)callbackQueue {
    return _callbackQueue ? _callbackQueue : [NSOperationQueue currentQueue];
}

#pragma mark - support functions
- (NSString *)networkRandomString {
    u_int32_t x = arc4random_uniform(1<<30);
    return [NSString stringWithFormat:@"%u_%lld", x, (int64_t)([[NSDate date] timeIntervalSince1970] * 1000)];
}

- (NSError *)checkErrorFromHttpResponse:(NSHTTPURLResponse *)response data:(NSData *)data {
    NSError *error = nil;
    NSInteger statusCode = [response statusCode];
    GLLog(@"Status code: %d", statusCode);
    if (statusCode == 500) {
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_SERVER_ERROR userInfo:nil];
    } else if (statusCode == 404) {
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_NOT_FOUND userInfo:nil];
    } else if (statusCode == 503) {
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_SERVICE_UNAVAILBLE userInfo:nil];
    } else if (data == nil) {
        error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_UNKNOWN_NEWORK_ERROR userInfo:nil];
    }
    return error;
}

- (BOOL)checkTokenIsValid:(NSDictionary *)result {
    NSNumber *rc             = [result objectForKey:@"rc"];
    if (rc && [rc intValue] == REQUEST_RC_TOKEN_EXPIRED) {
        [self publish:EVENT_TOKEN_EXPIRED];
        return NO;
    }
    return YES;
}

// return "No" if the app is too old
- (BOOL)checkAppVersion:(NSDictionary *)result {
    NSNumber *rc             = [result objectForKey:@"rc"];
    NSNumber *tooOld         = [result objectForKey:@"too_old_version"];
    NSNumber *newVersion     = [result objectForKey:@"has_new_version"];
    
    if ((rc && [rc intValue] == REQUEST_RC_TOO_OLD_VERSION) && (tooOld && [tooOld intValue] == 1)) {
        [self publish:EVENT_UPGRADE_APP_VERSION data:result];
        return NO;
    } else if (newVersion && [newVersion intValue] == 1) {
        [self publish:EVENT_UPGRADE_APP_VERSION data:result];
    }
    return YES;
}

// return "No" if user is removed
- (BOOL)checkUserExist:(NSDictionary *)result {
    NSNumber *rc             = [result objectForKey:@"rc"];
    if (rc && [rc intValue] == REQUEST_RC_USER_REMOVED) {
        [self publish:EVENT_USER_REMOVED_FROM_SERVER];
        return NO;
    }
    return YES;
}

- (NSString *)genRandStringLength:(int)len inChars:(NSString *)chars {
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [chars characterAtIndex: arc4random() % [chars length]]];
    }
    
    return randomString;
}

#pragma mark - basic function, asyncRequest and syncRequest
/*
 * Basic function
 *   - asyncRequest 
 *   - syncRequest
 *
 * NOTE, 
 * 1.This basic function only work for connecting "Glow"
 *   url will be followed by "https://glowing.com/"
 *   If you need call none-glow url, you need write another function
 *
 * 2.We should never open these functions as API, because they do not
 *   contain "device_id", "app_version", "locale"
 */
- (NSURLRequest *)makeJsonRequest:url method:(NSString *)method data:(NSDictionary *)data timeout:(NSTimeInterval)timeout {
    url = [Utils apiUrl:url query:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    if (![method isEqual:@"GET"]) {
        [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    }
    [request setHTTPMethod:method];
    [request setTimeoutInterval:timeout];
    if (data != nil) {
        NSData *requestData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
        [request setHTTPBody:requestData];
    }
    return request;
}

- (void)asyncRequest:(NSString *)url method:(NSString *)method data:(NSDictionary *)data timeout:(NSTimeInterval)timeout completionHandler:(JSONResponseHandler)handler{
    NSURLRequest *request = [self makeJsonRequest:url method:method data:data timeout:timeout];
    GLLog(@"Send network request: %@", request);
    [NSURLConnection sendAsynchronousRequest:request queue:self.callbackQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            GLLog(@"Network request error: %@", error);
            [self publish:EVENT_NETWORK_ERROR];
        } else {
            error = [self checkErrorFromHttpResponse:(NSHTTPURLResponse *)response data:data];
        }
        if (!handler) {
            return;
        }
        if (error) {
            handler(nil, error);
        } else {
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeErr];
            if (!decodeErr) {
                // check if the user is removed
                if (![self checkUserExist:result])
                    return;
                // check the app version
                if (![self checkAppVersion:result])
                    return;
                
                if (![self checkTokenIsValid:result])
                    return;
            }
            handler(result, decodeErr);
        }
    }];
}

- (NSDictionary *)syncRequest:(NSString *)url method:(NSString *)method data:(NSDictionary *)data timeout:(NSTimeInterval)timeout error:(NSError **)error{
    NSURLRequest *request = [self makeJsonRequest:url method:method data:data timeout:timeout];
    GLLog(@"Send network request: %@", request);
    NSData *rawData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:error];
    NSDictionary *jsonObj = nil;
    if (rawData) {
        jsonObj = [NSJSONSerialization JSONObjectWithData:rawData options:0 error:error];
    }
    return jsonObj;
}

#pragma mark - basic function, asyncPost/syncPost and asyncGet
/*----------------------------------------------------------------------------
 * 1. asyncPost
 * 2. asyncPostFile
 * 3. syncPost    (no file)
 * 4. asyncGet    (currently, we don't have syncGet)
 * 5. asyncGetImage
 *
 * In this block, I need add "device_id", "app_version", "locale", "random" to 
 * each functions.
 *----------------------------------------------------------------------------
 */
- (BOOL)checkRequireLogin:(NSDictionary *)data {
    if ([data objectForKey:@"ut"] || [data objectForKey:@"user_id"]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)asyncPost:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login timeout:(NSTimeInterval)timeout completionHandler:(JSONResponseHandler)handler{
    if (login && [self checkRequireLogin:data] == NO) {
        [self publish:EVENT_NETWORK_ERROR];
        if (handler) {
            NSError * error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_BAD_REQUEST userInfo:nil];
            handler(nil, error);
        }
        return;
    }
    
    // add version to requestData
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] initWithDictionary:data];
    [requestData setObject:[Utils appVersion] forKey:@"app_version"];
    [requestData setObject:[Utils UUID] forKey:@"device_id"];
    [requestData setObject:[Utils localeString] forKey:@"locale"];
    [requestData setObject:[self networkRandomString] forKey:@"random"];
    [requestData setObject:[Utils modelString] forKey:@"model"];
    [self asyncRequest:url method:@"POST" data:requestData timeout:timeout completionHandler:handler];
}

- (void)asyncPostFile:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login files:(NSArray *)files completionHandler:(JSONResponseHandler)handler {
    if (login && [self checkRequireLogin:data] == NO) {
        [self publish:EVENT_NETWORK_ERROR];
        if (handler) {
            NSError * error = [NSError errorWithDomain:ERROR_DOMAIN_NETWORK code:ERROR_CODE_BAD_REQUEST userInfo:nil];
            handler(nil, error);
        }
        return;
    }
    
    // Upload files along with form data
    //
    // Args:
    //     files: Array of dictionary, each dictionary has "name", "data" and "filename" fields
    //
    url = [Utils apiUrl:url query:nil];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = [NSString stringWithFormat:@"----------------------%@", [self genRandStringLength:30 inChars:@"01234566789"]];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    /*
     now lets create the body of the post
     */
    NSMutableData *body = [NSMutableData data];
    
    // request data
    NSMutableDictionary *requestData = [NSMutableDictionary dictionaryWithDictionary:(data ? data : @{})];
    [requestData setObject:[Utils appVersion] forKey:@"app_version"];
    [requestData setObject:[Utils UUID] forKey:@"device_id"];
    [requestData setObject:[Utils localeString] forKey:@"locale"];
    [requestData setObject:[self networkRandomString] forKey:@"random"];
    [requestData setObject:[Utils modelString] forKey:@"model"];
    
    for (NSString *k in [requestData allKeys]) {
        NSString *val = (NSString *)[requestData objectForKey:k];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", k] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", val] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // request files
    for (NSDictionary *file in files) {
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"%@\"; filename=\"%@\"\r\n",
                           file[@"name"], file[@"filename"]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:file[@"data"]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    [request setTimeoutInterval:NETWORK_MULTIPART_TIMEOUT];
    [NSURLConnection sendAsynchronousRequest:request queue:self.callbackQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            GLLog(@"Network request error: %@", error);
            [self publish:EVENT_NETWORK_ERROR];
        } else {
            error = [self checkErrorFromHttpResponse:(NSHTTPURLResponse *)response data:data];
        }
        if (!handler) {
            return;
        }
        if (error) {
            handler(nil, error);
        } else {
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeErr];
            if (!decodeErr) {
                // check if the user is removed
                if (![self checkUserExist:result])
                    return;
                // check the app version
                if (![self checkAppVersion:result])
                    return;
                
                if (![self checkTokenIsValid:result])
                    return;
            }
            handler(result, decodeErr);
        }
    }];
}

- (NSDictionary *)syncPost:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login timeout:(NSTimeInterval)timeout error:(NSError **)error {
    if (login && [self checkRequireLogin:data] == NO) {
        // [self publish:EVENT_NETWORK_ERROR];
        return @{};
    }
    
    // add version to requestData
    NSMutableDictionary *requestData = [[NSMutableDictionary alloc] initWithDictionary:data];
    [requestData setObject:[Utils appVersion] forKey:@"app_version"];
    [requestData setObject:[Utils UUID] forKey:@"device_id"];
    [requestData setObject:[Utils localeString] forKey:@"locale"];
    [requestData setObject:[self networkRandomString] forKey:@"random"];
    [requestData setObject:[Utils modelString] forKey:@"model"];
    return [self syncRequest:url method:@"POST" data:requestData timeout:timeout error:error];
}

- (void)asyncGet:(NSString *)url data:(NSDictionary *)data completionHandler:(JSONResponseHandler)handler
{
    NSString *newUrl = [NSString stringWithFormat:@"%@%@app_version=%@&locale=%@&device_id=%@&random=%@&model=%@", url, ([url rangeOfString:@"?"].location != NSNotFound) ? @"&" : @"?", [Utils appVersion], [Utils localeString], [Utils UUID], [self networkRandomString], [Utils modelString]];
    [self asyncRequest:newUrl method:@"GET" data:data timeout:NETWORK_TIMEOUT_INTERVAL completionHandler:handler];
}

- (void)asyncGet:(NSString *)url completionHandler:(JSONResponseHandler)handler {
    // add version to url
    NSString *newUrl = [NSString stringWithFormat:@"%@%@app_version=%@&locale=%@&device_id=%@&random=%@&model=%@", url, ([url rangeOfString:@"?"].location != NSNotFound) ? @"&" : @"?", [Utils appVersion], [Utils localeString], [Utils UUID], [self networkRandomString], [Utils modelString]];
    [self asyncRequest:newUrl method:@"GET" data:nil timeout:NETWORK_TIMEOUT_INTERVAL completionHandler:handler];
}

- (void)asyncGetImage:(NSString *)url completionHandler:(ImageResponseHandler)handler {
    //
    // By default, for async call, the callback will be handled in a none-main thread
    // But, in this function, the image will be handled in main queue
    //
    NSString *newUrl = [NSString stringWithFormat:@"%@%@app_version=%@&locale=%@&device_id=%@&random=%@&model=%@", url, ([url rangeOfString:@"?"].location != NSNotFound) ? @"&" : @"?", [Utils appVersion], [Utils localeString], [Utils UUID], [self networkRandomString], [Utils modelString]];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:newUrl]];
    [request setHTTPMethod:@"GET"];
    [NSURLConnection sendAsynchronousRequest:request queue:self.callbackQueue  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        UIImage *image = nil;
        if (error) {
            GLLog(@"Network request error: %@", error);
        } else {
            image = [UIImage imageWithData:data];
        }
        dispatch_async(dispatch_get_main_queue(),^ {
            handler(image, error);
        });
    }];
}

#pragma mark - API, post and get
/*----------------------------------------------------------------------------
 *
 * post
 *    1. post: data: completionHandler:
 *       most used, post to our server with default timeout (20 seconds)
 *    2. post: data: timeout: completionHandler:
 *       used when the "post" needs more timeout data
 *       most use cases is payment / 3rd part
 *    3. post: data: files: completionHandler:
 *       post with file, only for send debug report
 *    4. post: data: image: completionHandler:
 *       upload profile image
 *    5. post: data: images: completionHandler:
 *       GL upload multiple images
 *
 * get
 *    1. get: completionHandler:
 *       most used, get from OUR server
 *    2. getImage: completionHandler:
 *       get image from s3
 *
 */
- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login completionHandler:(JSONResponseHandler)handler {
    [self asyncPost:url data:data requireLogin:login timeout:NETWORK_TIMEOUT_INTERVAL completionHandler:handler];
}

- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login timeout:(NSTimeInterval)timeout completionHandler:(JSONResponseHandler)handler {
    [self asyncPost:url data:data requireLogin:login timeout:timeout completionHandler:handler];
}

- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login images:(NSDictionary *)images completionHandler:(JSONResponseHandler)handler imageType:(EmmaImageType)imageType {
    // currently, this is not an API, because we only post "JPEG" now
    NSMutableArray *files = [[NSMutableArray alloc] init];
    for (NSString *key in [images allKeys]) {
        NSData *imageData = nil;
        if (imageType == EmmaImageTypePNG) {
            imageData = [NSData dataWithData:UIImagePNGRepresentation(images[key])];
        } else {
            imageData = [NSData dataWithData:UIImageJPEGRepresentation(images[key], 0.8)];
        }
        [files addObject:@{
                           @"name": @"image",
                           @"filename": key,
                           @"data": imageData
                           }];
    }
    [self asyncPostFile:url data:data requireLogin:login files:files completionHandler:handler];
}

- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login image:(UIImage *)image completionHandler:(JSONResponseHandler)handler {
    [self post:url data:data requireLogin:login images:@{@"image":image} completionHandler:handler];
}

- (void)post:(NSString *)url data:(NSDictionary *)data requireLogin:(BOOL)login images:(NSDictionary *)images completionHandler:(JSONResponseHandler)handler
{
    [self post:url data:data requireLogin:login images:images completionHandler:handler imageType:EmmaImageTypeJPEG];
}

- (void)get:(NSString *)url data:(NSDictionary *)data completionHandler:(JSONResponseHandler)handler
{
    [self asyncGet:url data:data completionHandler:handler];
}

- (void)get:(NSString *)url completionHandler:(JSONResponseHandler)handler {
    [self asyncGet:url completionHandler:handler];
}

- (void)getImage:(NSString *)url completionHandler:(ImageResponseHandler)handler {
    [self asyncGetImage:url completionHandler:handler];
}

- (void)getNonGlowURL:(NSString *)url
                query:(NSDictionary *)query
    completionHandler:(JSONResponseHandler)handler
{
    
    if (query) {
        NSString *queryString = [Utils urlEncodedStringFromDictionary:query];
        url = [NSString stringWithFormat:@"%@?%@", url, queryString];
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"GET";
    [request setTimeoutInterval:NETWORK_TIMEOUT_INTERVAL];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:self.callbackQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error)
    {
        if (error) {
            GLLog(@"Network request error: %@", error);
            [self publish:EVENT_NETWORK_ERROR];
        }
        else {
            error = [self checkErrorFromHttpResponse:(NSHTTPURLResponse *)response data:data];
        }
        
        if (!handler) {
            return;
        }
        
        if (error) {
            handler(nil, error);
        }
        else {
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&decodeErr];
            handler(result, decodeErr);
        }

   }];
}

- (void)pingWithCompletionHandler:(void(^)(BOOL))completionHandler
{
    NSString *url = [Utils makeUrl:@"/ping"];
    NSURLRequest *request = [self makeJsonRequest:url method:@"GET" data:nil timeout:NETWORK_TIMEOUT_INTERVAL];
    [NSURLConnection sendAsynchronousRequest:request queue:self.callbackQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError || [(NSHTTPURLResponse *)response statusCode] != 200) {
            return completionHandler(NO);
        } else {
            return completionHandler(YES);
        }
    }];

}


@end




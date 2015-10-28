//
//  ForumAPI.m
//  ShareTest
//
//  Created by ltebean on 15/5/29.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "ForumAPI.h"
#import <TFHpple.h>
#import "Config.h"
#import <GLCommunity/Forum.h>
#include <sys/types.h>
#include <sys/sysctl.h>

@interface ForumAPI()
@end

@implementation ForumAPI
+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
}

- (void)fetchGroups:(void(^)(BOOL, NSArray *))completionHandler
{
    NSString *url = [NSString stringWithFormat:@"%@/api/forum/group/group_page?ut=%@", EMMA_BASE_URL, self.userToken];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            return completionHandler(NO, nil);
        }
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        NSInteger rc = [result[@"rc"] integerValue];
        if (rc != 0) {
            return completionHandler(NO, nil);
        }
        return completionHandler(YES, result[@"_group_page"][@"subscribed"]);
    }];

}

- (void)postImage:(UIImage *)image title:(NSString *)title groupId:(NSInteger)groupId anonymous:(BOOL)anonymous tmi:(BOOL)tmi
{
    NSString *url = [NSString stringWithFormat:@"%@/api/forum/photo/create", EMMA_BASE_URL];

    NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithDictionary:[self postBody]];
    [postData addEntriesFromDictionary:@{@"ut": self.userToken,
                                        @"group_id": @(groupId),
                                        @"title": title,
                                        @"anonymous": @(anonymous ? 1 : 0),
                                        @"warning": @(tmi ? 1 : 0),
                                        @"share_extension": @(1)
                                         }];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    NSString *boundary = [NSString stringWithFormat:@"----------------------%@", [self genRandStringLength:30 inChars:@"01234566789"]];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];

    NSMutableData *body = [NSMutableData data];
    NSMutableDictionary *requestData = [NSMutableDictionary dictionaryWithDictionary:(postData ? postData : @{})];
    for (NSString *key in [requestData allKeys]) {
        NSString *val = (NSString *)[requestData objectForKey:key];
        
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"%@\r\n", val] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: attachment; name=\"image\"; filename=\"file\"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:UIImageJPEGRepresentation(image, 0.8)]];
    [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:body];
    
    NSURLSessionConfiguration *config =  [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:APP_GROUPS];
    config.sharedContainerIdentifier = APP_GROUPS;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request];
    [postDataTask resume];
    
}

- (void)postURL:(NSURL *)url title:(NSString *)title groupId:(NSInteger)groupId anonymous:(BOOL)anonymous
{
    [self fetchUrl:url completionHander:^(BOOL success, NSDictionary *result) {
        if (success && result) {
            NSString *endpoint = [NSString stringWithFormat:@"%@/api/forum/url_topic/create", EMMA_BASE_URL];
            NSMutableDictionary *postData = [NSMutableDictionary dictionaryWithDictionary:[self postBody]];
            [postData addEntriesFromDictionary:@{@"ut": self.userToken,
                                                 @"group_id": @(groupId),
                                                 @"title": title,
                                                 @"url_path": url.absoluteString,
                                                 @"url_title": result[@"title"],
                                                 @"url_abstract": result[@"desc"],
                                                 @"thumbnail_url": result[@"thumbnail"],
                                                 @"share_extension": @(1)
                                                 }];

            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:endpoint]];
            [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [request setHTTPMethod:@"POST"];
            NSData *requestData = [NSJSONSerialization dataWithJSONObject:postData options:0 error:nil];
            [request setHTTPBody:requestData];
            NSURLSessionConfiguration *config =  [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:APP_GROUPS];
            config.sharedContainerIdentifier = APP_GROUPS;
            NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
            NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request];
            [postDataTask resume];
        }
    }];
}

- (void)fetchUrl:(NSURL *)url completionHander:(void(^)(BOOL, NSDictionary*))completionHandler
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSData  *data = [NSData dataWithContentsOfURL:url];
        TFHpple * doc = [[TFHpple alloc] initWithHTMLData:data];
        TFHppleElement *image  = [[doc searchWithXPathQuery:@"//meta[@property='og:image']"] firstObject];
        NSLog(@"ELEMENT: %@", image.attributes[@"content"]);
        NSString *ogImage = image.attributes[@"content"];
        NSString *ogImageUrl = nil;
        if (![ogImage isEqualToString:@""]) {
            if ([ogImage hasPrefix:@"http"]) {
                ogImageUrl = ogImage;
            } else {
                ogImageUrl = [[NSURL URLWithString:ogImage relativeToURL:url] absoluteString];
            }
        }
        TFHppleElement *title  = [[doc searchWithXPathQuery:@"//meta[@property='og:title']"] firstObject];
        NSString *ogTitle = title.attributes[@"content"];
        if ([ogTitle isEqualToString:@""]) {
            ogTitle = nil;
        }
        TFHppleElement *description  = [[doc searchWithXPathQuery:@"//meta[@property='og:description']"] firstObject];
        NSString *ogDesc = description.attributes[@"content"];
        if ([ogDesc isEqualToString:@""]) {
            ogDesc = nil;
        }
        
        if (ogImageUrl && ogTitle && ogDesc) {
            return completionHandler(YES, @{@"title": ogTitle, @"desc": ogDesc, @"thumbnail": ogImageUrl});
        } else {
            NSString *readabilityUrl = [NSString stringWithFormat:@"%@?url=%@&token=%@", FALLBACK_READABILITY_URL, url.absoluteString, FALLBACK_READABILITY_TOKEN];
            NSData *readabilityData = [NSData dataWithContentsOfURL:[NSURL URLWithString:readabilityUrl]];
            if (!data) {
                return completionHandler(NO, nil);
            }
            NSError *decodeErr = nil;
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:readabilityData options:0 error:&decodeErr];
            if (!decodeErr) {
                NSString *title = ogTitle?: (result[@"title"]?: @"");
                NSString *description = ogDesc?: (result[@"excerpt"]?: @"");
                NSString *thumbnail = ogImageUrl?: (result[@"lead_image_url"]?: @"");
                if (title && ![title isEqualToString:@""]) {
                    return completionHandler(YES, @{@"title": title, @"desc": description, @"thumbnail": thumbnail});
                } else {
                    return completionHandler(NO, nil);
                }
            } else {
                return completionHandler(NO, nil);
            }
        }
    });
}


- (NSString *)genRandStringLength:(int)len inChars:(NSString *)chars {
    NSMutableString *randomString = [NSMutableString stringWithCapacity: len];
    
    for (int i=0; i<len; i++) {
        [randomString appendFormat: @"%C", [chars characterAtIndex: arc4random() % [chars length]]];
    }
    
    return randomString;
}

- (NSDictionary *)postBody
{
    NSMutableDictionary *requestData = [NSMutableDictionary dictionary];
    [requestData setObject:[ForumAPI appVersion] forKey:@"app_version"];
//    [requestData setObject:[Utils UUID] forKey:@"device_id"];
    [requestData setObject:[ForumAPI localeString] forKey:@"locale"];
    [requestData setObject:[self networkRandomString] forKey:@"random"];
    [requestData setObject:[ForumAPI modelString] forKey:@"model"];
    return requestData;
}

- (NSString *)networkRandomString {
    u_int32_t x = arc4random_uniform(1<<30);
    return [NSString stringWithFormat:@"%u_%lld", x, (int64_t)([[NSDate date] timeIntervalSince1970] * 1000)];
}

+ (NSString *)appVersion {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return [[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
}

+ (NSString*)modelString {
    int name[] = {CTL_HW,HW_MACHINE};
    size_t size = 100;
    sysctl(name, 2, NULL, &size, NULL, 0); // getting size of answer
    char *hw_machine = malloc(size);
    
    sysctl(name, 2, hw_machine, &size, NULL, 0);
    NSString *hardware = [NSString stringWithUTF8String:hw_machine];
    free(hw_machine);
    return hardware;
}

+ (NSString *)localeString {
    NSLocale *curLocale = [NSLocale currentLocale];
    return curLocale.localeIdentifier;
}

@end

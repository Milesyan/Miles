//
//  OAuth1_0.m
//  emma
//
//  Created by Eric Xu on 3/7/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "OAuth1_0.h"
#import <CommonCrypto/CommonHMAC.h>

static NSString* nonce() {
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    CFStringRef s = CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return (id)CFBridgingRelease(s) ;
}

static NSString* base64(const uint8_t* input) {
    static const char map[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    NSMutableData* data = [NSMutableData dataWithLength:28];
    uint8_t* out = (uint8_t*) data.mutableBytes;
    
    for (int i = 0; i < 20;) {
        int v  = 0;
        for (const int N = i + 3; i < N; i++) {
            v <<= 8;
            v |= 0xFF & input[i];
        }
        *out++ = map[v >> 18 & 0x3F];
        *out++ = map[v >> 12 & 0x3F];
        *out++ = map[v >> 6 & 0x3F];
        *out++ = map[v >> 0 & 0x3F];
    }
    out[-2] = map[(input[19] & 0x0F) << 2];
    out[-1] = '=';
    return [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
}

@implementation OAuth1_0


- (id)initWithConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret accessToken:(NSString *)accessToken tokenSecret:(NSString *)tokenSecret {
    int ts = [[NSDate date] toTimestamp];
    params = [NSDictionary dictionaryWithObjectsAndKeys:
              consumerKey,                  @"oauth_consumer_key",
              [[NSUUID UUID] UUIDString],   @"oauth_nonce",
              @(ts),                        @"oauth_timestamp",
              @"1.0",                       @"oauth_version",
              @"HMAC-SHA1",                 @"oauth_signature_method",
              @"fitbit-glow://",            @"oauth_callback",
              accessToken,                  @"oauth_token",
              nil];
    signature_secret = [NSString stringWithFormat:@"%@&%@", consumerSecret, tokenSecret ?: @""];
    return self;
}

- (NSString *)signature_base {
    NSMutableString *p3 = [NSMutableString stringWithCapacity:256];
    NSArray *keys = [[params allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in keys) {
        [p3 appendString:[self pcen:key]];
        [p3 appendString:@"="];
        id v = params[key];
        if (![v isKindOfClass:[NSString class]]) {
            [p3 appendString:[v stringValue]];
        } else {
            [p3 appendString:v];
        }
        [p3 appendString:@"&"];
    }
    int n = [p3 length] - 1;
    if (n >= 0)
        [p3 deleteCharactersInRange:NSMakeRange(n, 1)];
    
    return [NSString stringWithFormat:@"%@&%@%%3A%%2F%%2F%@%@&%@",
            method,
            url.scheme.lowercaseString,
            [self pcen:url.host.lowercaseString],
            [self pcen:url.path],
            [self pcen:p3]];
}

- (NSString *)pcen:(NSString *)str {
    return (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef) str, NULL, (CFStringRef) @"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8));
}

- (NSString *)signature {
    NSData *sigbase = [[self signature_base] dataUsingEncoding:NSUTF8StringEncoding];
    GLLog(@"signaure base string: %@", [self signature_base]);
    NSData *secret = [signature_secret dataUsingEncoding:NSUTF8StringEncoding];
    
    uint8_t digest[20] = {0};
    CCHmacContext cx;
    CCHmacInit(&cx, kCCHmacAlgSHA1, secret.bytes, secret.length);
    CCHmacUpdate(&cx, sigbase.bytes, sigbase.length);
    CCHmacFinal(&cx, digest);
    
    return base64(digest);
}

- (NSString *)authorizationHeader {
    NSMutableString *header = [NSMutableString string];
    [header appendString:@"OAuth "];
    for (NSString *key in params.allKeys) {
        [header appendString:key];
        [header appendString:@"=\""];
        id v = params[key];
        if (![v isKindOfClass:[NSString class]]) {
            [header appendString:[v stringValue]];
        } else {
            [header appendString:v];
        }

        [header appendString:@"\","];
    }
    [header appendString:@"oauth_signature=\""];
    [header appendString:[self pcen:[self signature]]];
    [header appendString:@"\""];
    return header;
//    return [[header dataUsingEncoding:NSASCIIStringEncoding] base64Encoding];
}

- (NSMutableURLRequest *)request {
    NSMutableURLRequest *rq = [NSMutableURLRequest requestWithURL:url
                                                      cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                  timeoutInterval:30];
//#ifdef TDUserAgent
//    [rq setValue:TDUserAgent forHTTPHeaderField:@"User-Agent"];
//#endif
    GLLog(@"header: %@", [self authorizationHeader]);
    [rq setValue:[self authorizationHeader] forHTTPHeaderField:@"Authorization"];
//    [rq setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [rq setHTTPMethod:method];
    return rq;
}

- (id)addParameters:(NSDictionary *)unencodedParameters {
    if (!unencodedParameters.count)
        return nil;
    
    NSMutableString *queryString = [NSMutableString string];
    NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionaryWithDictionary:params];
    for (NSString *key in unencodedParameters.allKeys) {
        NSString *enkey = [self pcen:key];
        NSString *envalue = [self pcen:[unencodedParameters objectForKey:key]];
        [encodedParameters setObject:envalue forKey:enkey];
        [queryString appendString:enkey];
        [queryString appendString:@"="];
        [queryString appendString:envalue];
        [queryString appendString:@"&"];
    }
    int n = [queryString length] - 1;
    if (n >= 0)
        [queryString deleteCharactersInRange:NSMakeRange(n, 1)];
    
    params = encodedParameters;
    
    return queryString;
}

+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPathWithoutQuery
                      GETParameters:(NSDictionary *)unencodedParameters
                             scheme:(NSString *)scheme
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret;
{
    if (!host || !unencodedPathWithoutQuery)
        return nil;
    
    OAuth1_0 *oauth = [[OAuth1_0 alloc] initWithConsumerKey:consumerKey
                                             consumerSecret:consumerSecret
                                                accessToken:accessToken
                                                tokenSecret:tokenSecret];
    
    // We don't use pcen as we don't want to percent encode eg. /, this
    // is perhaps not the most all encompassing solution, but in practice
    // it works everywhere and means that programmer error is *much* less
    // likely.
    NSString *encodedPathWithoutQuery = [unencodedPathWithoutQuery stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    id path = [oauth addParameters:unencodedParameters];
    if (path) {
        [path insertString:@"?" atIndex:0];
        [path insertString:encodedPathWithoutQuery atIndex:0];
    } else {
        path = encodedPathWithoutQuery;
    }
    
    oauth->method = @"GET";
    oauth->url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@://%@%@", scheme, host, path]];
    
    NSURLRequest *rq = [oauth request];
    return rq;
}

+ (NSURLRequest *)URLRequestForPath:(NSString *)unencodedPath
                     POSTParameters:(NSDictionary *)unencodedParameters
                               host:(NSString *)host
                        consumerKey:(NSString *)consumerKey
                     consumerSecret:(NSString *)consumerSecret
                        accessToken:(NSString *)accessToken
                        tokenSecret:(NSString *)tokenSecret
{
    if (!host || !unencodedPath)
        return nil;
    
    OAuth1_0 *oauth = [[OAuth1_0 alloc] initWithConsumerKey:consumerKey
                                             consumerSecret:consumerSecret
                                                accessToken:accessToken
                                                tokenSecret:tokenSecret];
    oauth->url = [[NSURL alloc] initWithScheme:@"https" host:host path:unencodedPath];
    oauth->method = @"POST";
    
    NSMutableString *postbody = [oauth addParameters:unencodedParameters];
    NSMutableURLRequest *rq = [oauth request];

    if (postbody.length) {
        [rq setHTTPBody:[postbody dataUsingEncoding:NSUTF8StringEncoding]];
        [rq setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [rq setValue:[NSString stringWithFormat:@"%u", rq.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    }

    return rq;
}


@end

//
//  LocalResourceHttpURLProtocol.m
//  emma
//
//  Created by Bob on 14-5-15.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "LocalResourceHttpURLProtocol.h"

@implementation LocalResourceHttpURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    GLLog(@"LocalResourceHttpURLProtocol init with request: %@", [[request URL] absoluteString]);
	if ([[[request URL] absoluteString] rangeOfString:@"install_data"].location != NSNotFound) {
        int pause = 0;
        pause++;
    }
    return [[[request URL] scheme] isEqualToString:@"appresource"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
	return request;
}

- (void)startLoading {
    id<NSURLProtocolClient> client = [self client];
    NSURLRequest* request = [self request];
    NSString *pathString = [[request URL] resourceSpecifier];
    pathString = [pathString stringByReplacingOccurrencesOfString:@"//" withString:@""];
    GLLog(@"LocalResourceHttpURLProtocol Start loading");
    
    NSString* fileToLoad = nil;
    fileToLoad = [[NSBundle mainBundle] pathForResource:pathString ofType:nil];
    
    NSData *data = nil;
    if (fileToLoad) {
        data = [NSData dataWithContentsOfFile:fileToLoad];
    }
    else {
        GLLog(@"LocalResourceHttpURLProtocol fail to load resource %@",pathString);
        NSString* d = @"";
        data = [d dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    NSHTTPURLResponse* response = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:[NSDictionary dictionary]];
    
    [client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    
    
    [client URLProtocol:self didLoadData:data];
    [client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading {
    
}

@end

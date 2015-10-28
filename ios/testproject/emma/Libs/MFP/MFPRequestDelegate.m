/* -*- mode: objc; tab-width: 2; tab-always-indent: t; basic-offset: 2; comment-column: 0 -*-
   Copyright (c) 2012 MyFitnessPal, LLC. All rights reserved.

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#import "MFPRequestDelegate.h"
#import "MFP.h"

@interface MFPRequestDelegate ()
@property (nonatomic, strong) NSMutableData *data;

@end


@implementation MFPRequestDelegate


- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)response {
  if (_data)
    return;
  long long length = [response expectedContentLength];
  if (length == -1)
    _data = [NSMutableData new];
  else
    _data = [[NSMutableData alloc] initWithCapacity:(NSUInteger)length];
}


- (void)connection: (NSURLConnection *)thisConnection didReceiveData: (NSData *)data {
  [_data appendData:data];
}


- (void)connection: (NSURLConnection *)connection didFailWithError: (NSError *)error {
  @autoreleasepool {
    id <MFPDelegate> delegate = [_MFP delegate];

    NSDictionary *r = nil;
    if ([_data length]) {
      NSString *JSONString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
      r = [delegate MFP:_MFP JSONStringToDictionary:JSONString];
    }

    if ([r objectForKey:@"error"]) {
      [self reportFailureWithDictionary:r];
      return;
    }

    r = @{
      @"error": [error domain],
      @"error_description": [@"Network error: " stringByAppendingString:[error localizedDescription]]
    };

    [self reportFailureWithDictionary:r];
  }
}


- (void)connectionDidFinishLoading: (NSURLConnection *)connection {
  @autoreleasepool {
    id <MFPDelegate> delegate = [_MFP delegate];

    NSDictionary *r = nil;
    if ([_data length]) {
      NSString *JSONString = [[NSString alloc] initWithData:_data encoding:NSUTF8StringEncoding];
      r = [delegate MFP:_MFP JSONStringToDictionary:JSONString];
    }

    if ([r isKindOfClass:[NSDictionary class]] && [r objectForKey:@"error"]) {
      [self reportFailureWithDictionary:r];
      return;
    }

    [self reportSuccessWithDictionary:r];
  }
}


- (void)reportFailureWithDictionary:(NSDictionary *)dictionary {
  id <MFPDelegate> delegate = [_MFP delegate];
  if ([delegate respondsToSelector:@selector(MFP:requestFailed:)])
    [delegate MFP:_MFP requestFailed:dictionary];

  if (_failureCallback)
    _failureCallback(dictionary);
}


- (void)reportSuccessWithDictionary:(NSDictionary *)dictionary {
  id <MFPDelegate> delegate = [_MFP delegate];
  if ([delegate respondsToSelector:@selector(MFP:requestSucceeded:)])
    [delegate MFP:_MFP requestSucceeded:dictionary];

  if (_successCallback)
    _successCallback(dictionary);
}


@end

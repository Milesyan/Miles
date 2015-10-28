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

#import <Foundation/Foundation.h>
#import "MFP.h"


/* private class, should not be used by public code. */
@interface MFPRequestDelegate : NSObject <NSURLConnectionDelegate>
@property (nonatomic, strong) MFPCallback successCallback;
@property (nonatomic, strong) MFPCallback failureCallback;

@property (nonatomic, unsafe_unretained) MFP *MFP;

@end

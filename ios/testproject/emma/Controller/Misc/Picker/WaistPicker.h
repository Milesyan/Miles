//
//  WaistPicker.h
//  emma
//
//  Created by Peng Gu on 3/26/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^WaistCallback)(float waist);

@interface WaistPicker : NSObject

- (void)presentWithWaistInCM:(float)waist
            withDoneCallback:(WaistCallback)doneCallback
              cancelCallback:(WaistCallback)cancelCallback;

@end

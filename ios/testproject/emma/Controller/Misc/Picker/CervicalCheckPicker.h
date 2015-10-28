//
//  CervicalCheckPicker.h
//  emma
//
//  Created by Eric Xu on 12/17/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLFoundation/GLGeneralPicker.h>

typedef void (^CervicalDoneCallback)(NSDictionary *cervical);

@interface CervicalCheckPicker : NSObject

- (void)presentWithCervicalPosition:(NSDictionary *)cervical
                       doneCallback:(CervicalDoneCallback)doneCallback
                  startoverCallback:(Callback)startoverCallback;

@end

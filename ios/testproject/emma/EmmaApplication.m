//
//  EmmaApplication.m
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "EmmaApplication.h"

#define TIME_ELAPSED_BEFORE_IDLE 3

@interface EmmaApplication()
@property (nonatomic, retain) NSTimer * idleTimer;
@end

@implementation EmmaApplication

- (BOOL)openURL:(NSURL*)url {
    GLLog(@"openURL:%@", url);
    return [super openURL:url];
}

- (void)sendEvent:(UIEvent *)event {
    // Only want to reset the timer on a Began touch or an Ended touch, to reduce the number of timer resets.
    NSSet *allTouches = [event allTouches];
    if ([allTouches count] > 0) {
        // allTouches count only ever seems to be 1, so anyObject works here.
        UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
        if (phase == UITouchPhaseEnded)
            [self resetIdleTimer];
    }
    
    // move this call at the end, because call the super method first it
    // will pass it to all UIResponders that may eventually eat the event
    [super sendEvent:event];
}

- (void)resetIdleTimer {
    if (self.idleTimer) {
        [self.idleTimer invalidate];
    }
    
    self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:TIME_ELAPSED_BEFORE_IDLE target:self selector:@selector(idleTimerExceeded) userInfo:nil repeats:NO];
}

- (void)idleTimerExceeded {
    GLLog(@"idle time exceeded");
    [self publish:EVENT_APP_IDLE];
}

@end

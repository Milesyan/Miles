//
//  AnimationSequence.m
//  emma
//
//  Created by Ryan Ye on 6/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AnimationSequence.h"

@interface AnimationBlock()
- (id)initWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(AnimationsFunc)animations;
@end

@implementation AnimationBlock 
+ (id)duration:(NSTimeInterval)duration animations:(AnimationsFunc)animations {
    return [[AnimationBlock alloc] initWithDuration:duration delay:0 options:0 animations:animations];
}

+ (id)duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(AnimationsFunc)animations {
    return [[AnimationBlock alloc] initWithDuration:duration delay:delay options:options animations:animations];
}

- (id)initWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(AnimationsFunc)animations{
    if (self = [super init]) {
        self.duration = duration;
        self.delay = delay;
        self.options = options;
        self.animations = animations;
    }
    return self;
}
@end

@implementation AnimationSequence
- (id)initWithAnimationBlocks:(NSArray *)blocks {
    if (self = [super init]) {
        self.animationBlocks = blocks;
    }
    return self;
}

- (void)perform {
    [self performAnimationAtIndex:0];
}

- (void)performAnimationAtIndex:(int)index {
    if (index >= [self.animationBlocks count]) {
        if (self.completion) self.completion(YES);
        return;
    }
    AnimationBlock *ab = [self.animationBlocks objectAtIndex:index];
    [UIView animateWithDuration:ab.duration delay:ab.delay options:0 animations:ab.animations completion:^(BOOL finished) {
        if (finished) {
            [self performAnimationAtIndex:index+1];
        } else {
            if (self.completion) self.completion(NO);
        }
    }];
}

+ (void)performAnimations:(NSArray *)blocks completion:(SequenceCompletionFunc)completion {
    AnimationSequence *seq = [[AnimationSequence alloc] initWithAnimationBlocks:blocks];
    seq.completion = completion;
    [seq perform];
}

+ (void)performAnimations:(NSArray *)blocks {
    AnimationSequence *seq = [[AnimationSequence alloc] initWithAnimationBlocks:blocks];
    [seq perform];
}

@end

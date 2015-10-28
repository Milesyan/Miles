//
//  AnimationSequence.h
//  emma
//
//  Created by Ryan Ye on 6/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AnimationsFunc)(void);
typedef void (^SequenceCompletionFunc)(BOOL finished);

@interface AnimationBlock : NSObject
@property (nonatomic)NSTimeInterval duration;
@property (nonatomic)NSTimeInterval delay;
@property (nonatomic)UIViewAnimationOptions options;
@property (nonatomic, strong)AnimationsFunc animations;

+ (id)duration:(NSTimeInterval)duration animations:(AnimationsFunc)animations;
+ (id)duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(AnimationsFunc)animations;
@end

@interface AnimationSequence : NSObject
@property (nonatomic, strong)NSArray *animationBlocks;
@property (nonatomic, strong)SequenceCompletionFunc completion;

- (id)initWithAnimationBlocks:(NSArray *)blocks;
- (void)perform;
- (void)performAnimationAtIndex:(int)index;
+ (void)performAnimations:(NSArray *)blocks;
+ (void)performAnimations:(NSArray *)blocks completion:(SequenceCompletionFunc)completion;
@end

//
//  AnimationSequence.h
//  emma
//
//  Created by Ryan Ye on 6/27/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^GLAnimationsFunc)(void);
typedef void (^GLSequenceCompletionFunc)(BOOL finished);

@interface GLAnimationBlock : NSObject
@property (nonatomic)NSTimeInterval duration;
@property (nonatomic)NSTimeInterval delay;
@property (nonatomic)UIViewAnimationOptions options;
@property (nonatomic, strong)GLAnimationsFunc animations;

+ (id)duration:(NSTimeInterval)duration animations:(GLAnimationsFunc)animations;
+ (id)duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(GLAnimationsFunc)animations;
@end

@interface GLAnimationSequence : NSObject
@property (nonatomic, strong)NSArray *animationBlocks;
@property (nonatomic, strong)GLSequenceCompletionFunc completion;

- (id)initWithAnimationBlocks:(NSArray *)blocks;
- (void)perform;
- (void)performAnimationAtIndex:(int)index;
+ (void)performAnimations:(NSArray *)blocks;
+ (void)performAnimations:(NSArray *)blocks completion:(GLSequenceCompletionFunc)completion;
@end

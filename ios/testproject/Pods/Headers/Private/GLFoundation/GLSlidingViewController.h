//
//  GLSlidingViewController.h
//  emma
//
//  Created by ltebean on 15-1-4.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SlideDirection) {
    left,
    right
};

@protocol GLSlidingViewTransition <NSObject>
- (void)updateSourceView:(UIView*) sourceView destinationView:(UIView*) destView withProgress:(CGFloat)percent direction:(SlideDirection)direction;
@end

@interface GLSlidingViewController : UIViewController
@property(nonatomic,strong) UIScrollView* scrollView;
@property(nonatomic,strong) id<GLSlidingViewTransition> animator;
- (void)scrollToPage:(int)page animated:(BOOL)animated;
- (void)removeAllChildViewControllers;
- (void)didScrollToPage:(int)page;
@end

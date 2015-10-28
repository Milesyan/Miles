//
//  WalkThroughNew.m
//  emma
//
//  Created by Peng Gu on 8/26/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalkThrough.h"
#import "UIView+Helpers.h"


@interface WalkThrough ()

@end


@implementation WalkThrough

- (id)init
{
    return [self initWithParentViewController:nil];
}


- (instancetype)initWithParentViewController:(UIViewController *)parentViewController
{
    self = [super init];
    if (self) {
        [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
        
        self.walkThroughViewController = [[WalkThroughViewController alloc] init];
        self.walkThroughViewController.delegate = self;
        self.walkThroughViewController.dataSource = self;

        [self setupViews]; 
        self.parentViewController = parentViewController;
    }
    return self;
}


- (void)setParentViewController:(UIViewController *)parentViewController
{
    if (parentViewController) {
        _parentViewController = parentViewController;
        
        [parentViewController.view insertSubview:self.walkThroughViewController.view atIndex:0];
        [parentViewController addChildViewController:self.walkThroughViewController];
        [self.walkThroughViewController didMoveToParentViewController:parentViewController];
    }
}


- (void)setupViews
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must implement %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}



@end

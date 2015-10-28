//
//  UIWebView+Emma.h
//  emma
//
//  Created by Allen Hsu on 12/2/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWebView (Emma)

@property (assign, nonatomic) BOOL hackishlyHidesInputAccessoryView;

- (void)hideGradientBackgrounds;

@end

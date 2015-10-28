//
//  GradientLabel.m
//  emma
//
//  Created by Jirong Wang on 3/29/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "GradientLabel.h"
#define GRADIENT_TOP_TO_BOTTOM           1
#define GRADIENT_LEFT_TO_RIGHT           2
#define GRADIEND_LEFTTOP_TO_RIGHTBOTTOM  3
#define GRADIEND_RIGHTTOP_TO_LEFTBOTTOM  4

@implementation GradientLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

// interface to set the gradient
- (void)initGradientColor:(UIColor *)startColor endColor:(UIColor *)endColor direction:(NSUInteger)direction{
    self.textColor = [UIColor colorWithPatternImage:[self gradientImage:startColor endColor:endColor direction:direction]];
}

+ (NSInteger)topToBottom {
    return GRADIENT_TOP_TO_BOTTOM;
}
+ (NSInteger)leftToRight {
    return GRADIENT_LEFT_TO_RIGHT;
}
+ (NSInteger)leftTopToRightBottom {
    return GRADIEND_LEFTTOP_TO_RIGHTBOTTOM;
}
+ (NSInteger)rightTopToLeftBottom {
    return GRADIEND_RIGHTTOP_TO_LEFTBOTTOM;
}

- (UIImage *)gradientImage:(UIColor *)startColor endColor:(UIColor *)endColor direction:(NSUInteger)direction {
    // get width and height for the image
    /*
    CGSize  textSize = [self.text sizeWithFont:self.font];
    CGFloat width    = textSize.width;
    int lines = self.numberOfLines > 0 ? self.numberOfLines : 1;
    CGFloat height   = textSize.height * lines;
    */
    // use the frame size
    CGFloat width    = self.frame.size.width;
    CGFloat height   = self.frame.size.height;
    
    // create a new bitmap image context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // get context
    CGContextRef context = UIGraphicsGetCurrentContext();
    // push context to make it current (need to do this manually because we are not drawing in a UIView)
    UIGraphicsPushContext(context);
    
    // create gradient, with 2 colors (startColor and endColor)
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    
    CGFloat c[8];
    [startColor getRed:&c[0] green:&c[1] blue:&c[2] alpha:&c[3]];
    [endColor getRed:&c[4] green:&c[5] blue:&c[6] alpha:&c[7]];
    CGFloat locations[2] = { 0.0, 1.0 };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(rgbColorspace, c, locations, 2);
    
    // draw
    CGPoint startPoint;
    CGPoint endPoint;
    switch (direction) {
        case GRADIENT_LEFT_TO_RIGHT:
            startPoint = CGPointMake(0, 0);
            endPoint   = CGPointMake(width, 0);
            break;
        case GRADIEND_LEFTTOP_TO_RIGHTBOTTOM:
            startPoint = CGPointMake(0, 0);
            endPoint   = CGPointMake(width, height);
            break;
        case GRADIEND_RIGHTTOP_TO_LEFTBOTTOM:
            startPoint = CGPointMake(width, height);
            endPoint   = CGPointMake(0, 0);
            break;
        default:
            // top to bottom
            startPoint = CGPointMake(0, 0);
            endPoint   = CGPointMake(0, height);
            break;
    }
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(rgbColorspace);
    
    // pop context
    UIGraphicsPopContext();
    
    // get a UIImage from the image context
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // clean up drawing environment
    UIGraphicsEndImageContext();
    
    return  gradientImage;
}

@end

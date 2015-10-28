//
//  GLPeriodEditorAppearance.m
//  GLPeriodEditor
//
//  Created by ltebean on 15-4-30.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "GLPeriodEditorAppearance.h"
#import "GLCalendarDayCell.h"
#import "GLCalendarView.h"
#import "GLPeriodEditorHeader.h"
#import <GLFoundation/GLTheme.h>

@implementation GLPeriodEditorAppearance
+ (void)setupAppearance
{
    NSInteger screenWidth = [UIScreen mainScreen].bounds.size.width;
    
    CGFloat paddingAll = screenWidth % 7 + 7;
    
    [GLCalendarView appearance].rowHeight = (screenWidth - paddingAll) / 7 + 3;
    [GLCalendarView appearance].padding = paddingAll / 2;
    [GLCalendarView appearance].weekDayTitleAttributes = @{NSFontAttributeName:[GLTheme defaultFont:11], NSForegroundColorAttributeName:[UIColor grayColor]};
    [GLCalendarView appearance].monthCoverAttributes = @{NSFontAttributeName:[GLTheme boldFont:32]};
    
    [GLCalendarView appearance].backToTodayButtonColor = GLOW_COLOR_PURPLE;
    [GLCalendarView appearance].backToTodayButtonBorderColor = UIColorFromRGBA(0x5a62d260);
    [GLCalendarView appearance].backToTodayButtonImage = [GLPeriodEditorAppearance image:[UIImage imageNamed:@"gl-foundation-back.png"] withColor:[UIColor whiteColor]];
    
    [GLCalendarDayCell appearance].dayLabelAttributes = @{NSFontAttributeName:[GLTheme lightFont:24]};
    [GLCalendarDayCell appearance].futureDayLabelAttributes = @{NSFontAttributeName:[GLTheme lightFont:24], NSForegroundColorAttributeName:GLOW_COLOR_FUTURE_DAY};
    [GLCalendarDayCell appearance].todayLabelAttributes = @{NSFontAttributeName:[GLTheme semiBoldFont:24]};
    [GLCalendarDayCell appearance].monthLabelAttributes = @{NSFontAttributeName:[GLTheme boldFont:8]};
    
    [GLCalendarDayCell appearance].editCoverBorderWidth = 2;
    [GLCalendarDayCell appearance].editCoverBorderColor = GLOW_COLOR_PURPLE;
    [GLCalendarDayCell appearance].editCoverPointSize = 14;
    [GLCalendarDayCell appearance].editCoverPointScale = 1.3;
    
    if (screenWidth <= 320) {
        [GLCalendarView appearance].monthCoverAttributes = @{NSFontAttributeName:[GLTheme boldFont:30]};
        [GLCalendarDayCell appearance].editCoverPadding = 1.5;
        [GLCalendarDayCell appearance].dayLabelAttributes = @{NSFontAttributeName:[GLTheme lightFont:22]};
        [GLCalendarDayCell appearance].todayLabelAttributes = @{NSFontAttributeName:[GLTheme semiBoldFont:22]};
        [GLCalendarDayCell appearance].futureDayLabelAttributes = @{NSFontAttributeName:[GLTheme lightFont:22], NSForegroundColorAttributeName:GLOW_COLOR_FUTURE_DAY};
        [GLCalendarDayCell appearance].monthLabelAttributes = @{NSFontAttributeName:[GLTheme boldFont:7]};
    }
}

+ (UIImage *)image:(UIImage *)image withColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect area = CGRectMake(0, 0, image.size.width, image.size.height);
    
    CGContextScaleCTM(ctx, 1, -1);
    CGContextTranslateCTM(ctx, 0, -area.size.height);
    CGContextSaveGState(ctx);
    CGContextClipToMask(ctx, area, image.CGImage);
    [color set];
    CGContextFillRect(ctx, area);
    CGContextRestoreGState(ctx);
    // CGContextSetBlendMode(ctx, kCGBlendModeMultiply);
    // CGContextDrawImage(ctx, area, image.CGImage);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
@end

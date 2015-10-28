//
//  InterfaceController.m
//  watch WatchKit Extension
//
//  Created by ltebean on 15/3/8.
//  Copyright (c) 2015年 ltebean. All rights reserved.
//

#import "MainInterfaceController.h"
#import "DataController.h"
#import "DayRow.h"

@interface MainInterfaceController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *noUserLabel;

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *todayGroup;
@property (weak, nonatomic) IBOutlet WKInterfaceGroup *buttonGroup;

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *circle;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *titleLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *button;

@property (assign, nonatomic, readonly) BOOL isLargerScreen;

@property (nonatomic, assign) ButtonType buttonType;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger currentCircleIndex;

@property (nonatomic, strong) DataController *dataController;

@end


@implementation MainInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    NSLog(@"Today awake");
    [self updateNoUserAvailableVisibility:YES];
    
    self.dataController = [DataController sharedInstance];
    [self.dataController sendRequestToParentApp:RequestTypeRefreshWatchData
                                          reply:^(NSDictionary *replyInfo, NSError *error)
    {
        if (!error) {
            [self updateUI];
        }
    }];
}


- (void)willActivate
{
    [super willActivate];
    
    [self.dataController sendRequestToParentApp:RequestTypeLogTodayPage reply:nil];
    
    if (!self.timer) {
        self.timer = [[NSTimer alloc] initWithFireDate:[NSDate date]
                                              interval:4
                                                target:self
                                              selector:@selector(updateUI)
                                              userInfo:nil
                                               repeats:YES];
        
        NSRunLoop *runner = [NSRunLoop currentRunLoop];
        [runner addTimer:self.timer forMode: NSDefaultRunLoopMode];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI)
                                                 name:kNotificationWatchDataUpdated
                                               object:nil];
}



- (void)didDeactivate
{
    [super didDeactivate];
    
    [self.timer invalidate];
    self.timer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (BOOL)isLargerScreen
{
    CGRect bounds = [[WKInterfaceDevice currentDevice] screenBounds];
    return bounds.size.width >= 156;
}


- (void)updateNoUserAvailableVisibility:(BOOL)visible
{
    [self.noUserLabel setHidden:!visible];
    
    [self.todayGroup setHidden:visible];
    [self.circle setHidden:visible];
    [self.buttonGroup setHidden:visible];
}


- (void)updateUI
{
    NSLog(@"Update Today");
    
    if (self.dataController.noUserAvailable) {
        [self updateNoUserAvailableVisibility:YES];
        return;
    }

    [self updateNoUserAvailableVisibility:NO];
    
    NSDictionary *todayData = self.dataController.todayData;
    NSArray *circlesData = todayData[kCirclesData];
    self.buttonType = [todayData[kButtonType] integerValue];
    
    [self updateButtonWithType:self.buttonType];
    [self updateCircleWithCirclesData:circlesData];
}


- (void)updateButtonWithType:(ButtonType)buttonType
{
    if (buttonType == ButtonTypeNone) {
        [self.button setHidden:YES];
        [self setCircleSize: self.isLargerScreen ? 130 : 120];
    }
    else if (buttonType == ButtonTypeMyPeriodIsLate) {
        [self.button setHidden:NO];
        [self.button setTitle:@"Period is late"];
        [self setCircleSize: self.isLargerScreen ? 100 : 84];
    }
    else {
        [self.button setHidden:NO];
        [self.button setTitle:@"Period started today"];
        [self setCircleSize: self.isLargerScreen ? 100 : 84];
    }
}


- (void)updateCircleWithCirclesData:(NSArray *)circlesData
{
    if (circlesData.count == 0) {
        return;
    }
    
    if (self.currentCircleIndex == 0 && circlesData.count > 1) {
        self.currentCircleIndex = 1;
    }
    else {
        self.currentCircleIndex = 0;
    }
    
    NSDictionary *circle = circlesData[self.currentCircleIndex];
    
    NSInteger hexColor = [circle[kCircleBackgroundColor] integerValue];
    UIColor *color = UIColorFromRGB(hexColor);
    
    [self.titleLabel setAttributedText:[self attributedTextForCircle:circle]];
    [self.circle setBackgroundColor:color];
}


- (NSAttributedString *)attributedTextForCircle:(NSDictionary *)circle
{
    NSString *title = circle[kCircleTitle];
    NSString *text = circle[kCircleText];
    CGFloat titleFontSize = self.isLargerScreen ? 22 : 20;
    CGFloat textFontSize = self.isLargerScreen ? 14 : 12;
    
    if (self.buttonType == ButtonTypeMyPeriodIsLate) {
        titleFontSize -= 8;
        textFontSize -= 4;
    }
    
    NSDictionary *titleAttrs = @{NSFontAttributeName: [UIFont systemFontOfSize:titleFontSize],
                                 NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    NSDictionary *textAttrs = @{NSFontAttributeName: [UIFont systemFontOfSize:textFontSize],
                                NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    title = [title stringByAppendingString:@"\n"];
    NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title
                                                                                  attributes:titleAttrs];
    
    if (text) {
        [attrTitle appendAttributedString:[[NSAttributedString alloc] initWithString:text
                                                                          attributes:textAttrs]];
    }

    return attrTitle;
}


- (void)setCircleSize:(CGFloat)size
{
    [self.circle setWidth:size];
    [self.circle setHeight:size];
    [self.circle setCornerRadius:size / 2];
}


- (IBAction)buttonPressed
{
    RequestType requestType = RequestTypePeriodIsLate;
    
    if (self.buttonType == ButtonTypeMyPeriodStartedToday) {
        requestType = RequestTypePeriodStartedToday;
    }
    
    [self.dataController sendRequestToParentApp:requestType reply:^(NSDictionary *replyInfo, NSError *error) {
        
    }];

}


@end




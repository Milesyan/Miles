//
//  GlanceController.m
//  emma WatchKit Extension
//
//  Created by Peng Gu on 5/1/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "GlanceController.h"
#import "DataController.h"

@interface GlanceController()

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *noUserLabel;

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *titleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *subTitleLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceLabel *textLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *circle;

@property (nonatomic, strong) DataController *dataController;

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    NSLog(@"Glance awake");
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

    [self.dataController sendRequestToParentApp:RequestTypeLogGlancePage reply:nil];
    
    [self updateUI];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI)
                                                 name:kNotificationWatchDataUpdated
                                               object:nil];
}


- (void)didDeactivate
{
    [super didDeactivate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateNoUserAvailableVisibility:(BOOL)visible
{
    [self.noUserLabel setHidden:!visible];
    
    [self.circle setHidden:visible];
    [self.titleLabel setHidden:visible];
    [self.subTitleLabel setHidden:visible];
    [self.textLabel setHidden:visible];
}


- (void)updateUI
{
    if (self.dataController.noUserAvailable) {
        [self updateNoUserAvailableVisibility:YES];
        return;
    }
    
    [self updateNoUserAvailableVisibility:NO];
    
    NSLog(@"Update Glance UI");
    NSDictionary *data = self.dataController.glanceData;
    
    NSInteger hexColor = [data[kGlanceCircleColor] integerValue];
    UIColor *color = UIColorFromRGB(hexColor);
    [self.circle setBackgroundColor:color];
    
    [self.titleLabel setText:data[kGlanceTitle]];
    [self.subTitleLabel setText:data[kGlanceSubtitle]];
    [self.textLabel setText:data[kGlanceText]];
    [self.textLabel setTextColor:color];
}


@end




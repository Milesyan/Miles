//
//  PredictionInterfaceController.m
//  emma
//
//  Created by Peng Gu on 5/13/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "PredictionInterfaceController.h"
#import "DayRow.h"
#import "DataController.h"


@interface PredictionInterfaceController ()

@property (nonatomic, weak) IBOutlet WKInterfaceLabel *noUserLabel;
@property (nonatomic, weak) IBOutlet WKInterfaceGroup *contentGroup;
@property (nonatomic, weak) IBOutlet WKInterfaceTable *table;
@property (nonatomic, strong) DataController *dataController;

@end

@implementation PredictionInterfaceController

- (void)awakeWithContext:(id)context
{
    [super awakeWithContext:context];
    NSLog(@"Prediction awake");
    [self.noUserLabel setHidden:NO];
    [self.contentGroup setHidden:YES];

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
    
    [self.dataController sendRequestToParentApp:RequestTypeLogPredictionPage reply:nil];
    
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


- (void)updateUI
{
    NSLog(@"Update three days predictions");
    
    if (self.dataController.noUserAvailable) {
        [self.noUserLabel setHidden:NO];
        [self.contentGroup setHidden:YES];
        return;
    }
    
    [self.noUserLabel setHidden:YES];
    [self.contentGroup setHidden:NO];
    
    NSInteger count = self.dataController.predictionData.count;
    [self.table setNumberOfRows:count withRowType:@"DayRow"];
    
    for (NSInteger i = 0; i < count; i++) {
        DayRow* row = [self.table rowControllerAtIndex:i];
        row.data = self.dataController.predictionData[i];
    }
}




@end


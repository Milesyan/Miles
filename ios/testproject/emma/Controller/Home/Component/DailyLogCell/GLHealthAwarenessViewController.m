//
//  GLHealthAwarenessViewController.m
//  kaylee
//
//  Created by Eric Xu on 11/17/14.
//  Copyright (c) 2014 Glow, Inc. All rights reserved.
//

#import <GLFoundation/GLDialogViewController.h>
#import "GLHealthAwarenessViewController.h"
#import <DACircularProgress/DACircularProgressView.h>
#import "GLMeterView.h"
#import "HealthAwareness.h"
#import "Tooltip.h"

@interface GLHealthAwarenessViewController ()

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) GLDialogViewController *dialog;

@property (nonatomic, strong) IBOutlet DACircularProgressView *emotionalProgressView;
@property (nonatomic, strong) IBOutlet UILabel *emotionalProgressLabel;
@property (nonatomic, strong) IBOutlet DACircularProgressView *fertilityProgressView;
@property (nonatomic, strong) IBOutlet UILabel *fertilityProgressLabel;
@property (nonatomic, strong) IBOutlet DACircularProgressView *physicalProgressView;
@property (nonatomic, strong) IBOutlet UILabel *physicalProgressLabel;

@property (nonatomic, strong) IBOutlet GLMeterView *overallProgressView;
@property (nonatomic, strong) IBOutlet UILabel *overallProgressLabel;

@property (strong, nonatomic) IBOutlet UILabel *dateLabel;

@end


@implementation GLHealthAwarenessViewController

static GLHealthAwarenessViewController *inst;

+ (instancetype)viewController
{
    if (!inst) {
        inst = [[GLHealthAwarenessViewController alloc] initWithNibName:@"GLHealthAwarenessViewController" bundle:nil];
    }
    return inst;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.emotionalProgressView setRoundedCorners:YES];
    [self.emotionalProgressView setClockwiseProgress:YES];
    [self.emotionalProgressView setProgressTintColor:UIColorFromRGB(0xF14157)];
    [self.emotionalProgressView setTrackTintColor:UIColorFromRGB(0xF5C3BA)];
    [self.emotionalProgressView setThicknessRatio:0.2];
//    [self.emotionalProgressView setIndeterminate:YES];

    [self.fertilityProgressView setRoundedCorners:YES];
    [self.fertilityProgressView setClockwiseProgress:YES];
    [self.fertilityProgressView setProgressTintColor:UIColorFromRGB(0xF14157)];
    [self.fertilityProgressView setTrackTintColor:UIColorFromRGB(0xF5C3BA)];
    [self.fertilityProgressView setThicknessRatio:0.2];

    [self.physicalProgressView setRoundedCorners:YES];
    [self.physicalProgressView setClockwiseProgress:YES];
    [self.physicalProgressView setProgressTintColor:UIColorFromRGB(0xF14157)];
    [self.physicalProgressView setTrackTintColor:UIColorFromRGB(0xF5C3BA)];
    [self.physicalProgressView setThicknessRatio:0.2];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.overallProgressView setProgress:0 animated:NO];
    [self.emotionalProgressView setProgress:0 animated:NO];
    [self.physicalProgressView setProgress:0 animated:NO];
    [self.fertilityProgressView setProgress:0 animated:NO];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.dateLabel.text = [self.date toReadableDate];
    
    float emo = [self.awarenessScores[kEmotionalAwareness] floatValue];
    [self.emotionalProgressView setProgress:emo animated:YES];
    [self.emotionalProgressLabel setText:[NSString stringWithFormat:@"%d%%", (int)(emo * 100)]];

    float pre = [self.awarenessScores[kFertilityAwareness] floatValue];
    [self.fertilityProgressView setProgress:pre animated:YES];
    [self.fertilityProgressLabel setText:[NSString stringWithFormat:@"%d%%", (int)(pre * 100)]];
    
    float phy = [self.awarenessScores[kPhysicalAwareness] floatValue];
    [self.physicalProgressView setProgress:phy animated:YES];
    [self.physicalProgressLabel setText:[NSString stringWithFormat:@"%d%%", (int)(phy * 100)]];
   
    float all = [self.awarenessScores[kHealthAwareness] floatValue];
    [self.overallProgressView setProgress:all animated:YES];
    [self.overallProgressLabel setText:[NSString stringWithFormat:@"%d%%", (int)(all * 100)]];

}


- (void)presentForDate:(NSDate *)date
{
    self.date = date;
    
    self.dialog = [GLDialogViewController sharedInstance];
    [self.dialog presentWithContentController:self];
}


- (IBAction)improveLogPressed:(id)sender
{
    [Logging log:BTN_CLK_HOME_INCREASE_MY_AWARENESS];

    [self.dialog close];
    [self publish:EVENT_GO_TO_LOG_REQUESTED data:self.date];
}


- (IBAction)infoButtonClicked:(id)sender
{
    [self subscribeOnce:EVENT_DIALOG_DISMISSED obj:self.dialog handler:^(Event *evt){
        [Tooltip tip:@"Today's health awareness"];
    }];
    [self.dialog close];
}


@end

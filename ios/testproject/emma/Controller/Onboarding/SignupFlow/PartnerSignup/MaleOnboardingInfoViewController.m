//
//  OnboardingInfoViewController.m
//  emma
//
//  Created by Peng Gu on 3/20/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "MaleOnboardingInfoViewController.h"
#import <GLFoundation/GLGeneralPicker.h>
#import <GLFoundation/GLPickerViewController.h>
#import "SignUpViewController.h"
#import "PillButton.h"
#import "OnboardingDataProvider.h"
#import "HeightPicker.h"
#import "WeightPicker.h"
#import "StepsNavigationItem.h"
#import "UILinkLabel.h"
#import "Tooltip.h"

@interface MaleOnboardingInfoViewController ()
@property (nonatomic, weak) IBOutlet PillButton *weightButton;
@property (nonatomic, weak) IBOutlet PillButton *heightButton;
@property (nonatomic, weak) IBOutlet UILabel *bmiLabel;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *nextButton;
@property (nonatomic, weak) IBOutlet UILinkLabel *bmiTitleLabel;

@end


@implementation MaleOnboardingInfoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    if ([self.navigationItem isKindOfClass:[StepsNavigationItem class]]) {
        StepsNavigationItem *navItem = (StepsNavigationItem *)self.navigationItem;
        navItem.currentStep = @(1);
        navItem.allSteps = @(2);
        [navItem redraw];
    }
    
    [Tooltip setCallbackForAllKeywordOnLabel:self.bmiTitleLabel];
    
    [self updateButtonTitles];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_ONBOARDING_MALE_1];
}


- (void)updateButtonTitles
{
  
    NSString *weightText = self.weight ? [Utils displayTextForWeightInKG:self.weight.floatValue] : @"Weight";
    NSString *heightText = self.height ? [Utils displayTextForHeightInCM:self.height.floatValue] : @"Height";
    
    [self.weightButton setLabelText:weightText bold:NO];
    [self.heightButton setLabelText:heightText bold:NO];
    
    [self.weightButton setSelected:self.weight ? YES : NO];
    [self.heightButton setSelected:self.height ? YES : NO];
    
    if (self.weight && self.height) {
        CGFloat bmi = [Utils calculateBmiWithHeightInCm:self.height.floatValue
                                             weightInKg:self.weight.floatValue];
        self.bmiLabel.text = [NSString stringWithFormat:@"Your BMI: %.2f", bmi];
    }
    else {
        self.bmiLabel.text =  @"Your BMI: --";
    }
    
    BOOL finishInfo = self.weight && self.height;
    self.nextButton.enabled = finishInfo;
}


- (IBAction)cancel:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)chooseHeight:(id)sender
{
    float height = self.height.floatValue;
    int cmPosition      = CHOOSE_POSITION_HEIGHT_CM;
    int feetPosition    = CHOOSE_POSITION_HEIGHT_FEET;
    int inchPosition    = CHOOSE_POSITION_HEIGHT_INCH;
    
    HeightPicker *heightPicker = [[HeightPicker alloc] initWithChoose:cmPosition feetPosition:feetPosition inchPosition:inchPosition];
    @weakify(self);
    [heightPicker presentWithHeightInCM:height
                            andCallback:^(float h) {
                                @strongify(self);
                                
                                if (h > 0) {
                                    self.height = @(h);
                                    [self updateButtonTitles];
                                }
                                else {
                                    self.height = nil;
                                    [self.heightButton setLabelText:@"Height" bold:NO];
                                    [self.heightButton setSelected:NO];
                                }
                            }];
}


- (IBAction)chooseWeight:(id)sender
{
    float weight = self.weight.floatValue;
    int kgPosition    = CHOOSE_POSITION_WEIGHT_KG;
    int lbPosition    = CHOOSE_POSITION_WEIGHT_LB;
    
    WeightPicker *weightPicker = [[WeightPicker alloc] initWithChoose:kgPosition and:lbPosition];
    @weakify(self);
    [weightPicker presentWithWeightInKG:weight
                            andCallback:^(float w) {
                                @strongify(self);
                                
                                if (w > 0) {
                                    self.weight = @(w);
                                    [self updateButtonTitles];
                                }
                                else {
                                    self.weight = nil;
                                    [self.weightButton setLabelText:@"Weight" bold:NO];
                                    [self.weightButton setSelected:NO];
                                }
                            }];
}



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"partnerSignupToStep3"]) {
        NSDictionary *onboardingInfo = @{@"height": self.height, @"weight": self.weight};
        [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:onboardingInfo];
        
        SignUpViewController *vc = (SignUpViewController *)segue.destinationViewController;
        vc.isMaleSignup = YES;
    }
}


@end

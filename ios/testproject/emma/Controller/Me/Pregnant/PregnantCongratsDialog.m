//
//  PregnantCongratsDialog.m
//  emma
//
//  Created by Jirong Wang on 4/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PregnantCongratsDialog.h"
#import "PillGradientButton.h"
#import "AskRateDialog.h"
#import "Logging.h"
#import "GlowFirst.h"

@interface PregnantCongratsDialog () <UIActionSheetDelegate> {
    PregnantCallback cb;
    NSString *buttonTitle;
}
@property (strong, nonatomic) IBOutlet PillGradientButton *rateUsButton;

- (IBAction)rateUsButtonPressed:(id)sender;

@end

@implementation PregnantCongratsDialog

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    // set button color
    [self.rateUsButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    self.rateUsButton.titleLabel.textAlignment = NSTextAlignmentCenter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    self.rateUsButton.titleLabel.text = buttonTitle;
    [self.rateUsButton setTitle:buttonTitle forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)rateUsButtonPressed:(id)sender {
    if (cb) {
        cb();
        cb = nil;
    }
}

- (void)giveFiveStars {
    [CrashReport leaveBreadcrumb:@"PregnantDialog - give 5 stars"]; 
    [self presentWithButtonTitle:@"Give Glow 5 stars!" action:^{
        //[Logging syncLog:BTN_CLK_HOME_CONGRATS_RATE eventData:nil];
        [self.dialog close];
        [[AskRateDialog getInstance] goToRatePage];
    }];
}

- (void)stopGlowFirst {
    [CrashReport leaveBreadcrumb:@"PregnantDialog - stop glow first"]; 
    [self presentWithButtonTitle:@"Stop Glow First contributions" action:^{
        [Logging log:BTN_CLK_FUND_STOP_CONTRIBUTION];
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to stop contributing to Glow First?" delegate:self cancelButtonTitle:@"No, don't stop" destructiveButtonTitle:nil otherButtonTitles:@"Yes, please stop", nil];
        [actionSheet showInView:self.view.window];
    }];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    [self.dialog close];
    if (buttonIndex == 0) {
        /*
         * TODO(jirong), since we removed menuViewController, I don't know how to get 
         * the TabbarController from this dialog?
         * The pregnant button is redesigning, so I just comment these code.
         */
        /*
        MenuViewController *menuViewController = [MenuViewController getInstance];
        [menuViewController switchToViewControllerWithSegueId:@"fund"];
        */
        [[GlowFirst sharedInstance] userPregnant];
    }
}

- (void)presentWithButtonTitle:(NSString *)title action:(PregnantCallback)callback {
    buttonTitle = title;
    self.dialog = [GLDialogViewController sharedInstance];
    [self.dialog presentWithContentController:self];

    [self subscribeOnce:EVENT_DIALOG_CLOSE_BUTTON_CLICKED obj:self.dialog handler:^(Event *evt){
        //[Logging syncLog:BTN_CLK_HOME_CONGRATS_NO eventData:nil];
    }];
    
    cb = callback;
}
@end

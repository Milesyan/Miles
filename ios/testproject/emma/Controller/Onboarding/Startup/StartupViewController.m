

//
//  StartupViewController.m
//  emma
//
//  Created by Eric Xu on 3/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define TAG_SIGNUP 1
#define TAG_LOGIN 2

#import "AnimationSequence.h"
#import "Events.h"
#import "FacebookSDK/FacebookSDK.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "ResetPasswordViewController.h"
#import "SignUpViewController.h"
#import "StartupViewController.h"
#import "StatusBarOverlay.h"
#import "UILinkLabel.h"
#import "UIStoryboard+Emma.h"
#import "User.h"
#import "Tooltip.h"
#import "VariousPurposesConstants.h"
#import "GLSSOService.h"
#import "GLNameFormatter.h"
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "WalkThroughFlowController.h"
#import "WalkThrough.h"
#import "UIView+Helpers.h"
#import <GLFoundation/NSString+Markdown.h>
#import "SingleColorImageView.h"
#define MOVE_OFFSET 30
#define SLIDE_INTERVAL 4
#define TRANSITION_DURATION 0.8


@interface ChooseJourneyViewController ()

@property (nonatomic, weak) IBOutlet UIView *ttcView;
@property (nonatomic, weak) IBOutlet UIView *nttcView;
@property (nonatomic, weak) IBOutlet UIView *fertilityView;
@property (weak, nonatomic) IBOutlet UIView *maleView;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *cycleBgs;
@property (weak, nonatomic) IBOutlet SingleColorImageView *malePathIndicator;

@end

@implementation ChooseJourneyViewController{
    __weak IBOutlet UILinkLabel *noteLabel;
    __weak IBOutlet UIImageView *bgImageView;
    __weak IBOutlet UIScrollView *scrollView;
    __weak IBOutlet UIView *scrollContentView;
}

- (void)viewDidLoad
{
    scrollView.contentSize = CGSizeMake(scrollContentView.frame.size.width, scrollContentView.frame.size.height + 64);
    bgImageView.image = [Utils imageNamed:@"startup2"];
    noteLabel.clipsToBounds = NO;
    [noteLabel setCallback:^(NSString *kw){[Tooltip tip:kw];} forKeyword:@"NFP"];
    
    //cycleBgs
    for (UIView * v in self.cycleBgs) {
        v.layer.cornerRadius = 20;
    }
    
    // We need set the title in code, because of IOS6!
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    label.text = @"Choose your journey";
    label.font = [Utils boldFont:20];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    self.navigationItem.titleView = label;

    
    self.ttcView.layer.cornerRadius = 6;
    self.nttcView.layer.cornerRadius = 6;
    self.fertilityView.layer.cornerRadius = 6;
    self.maleView.layer.cornerRadius = 6;
    
    self.malePathIndicator.image = [Utils image:self.malePathIndicator.image withColor:[UIColor blackColor]];
    self.malePathIndicator.layer.cornerRadius = self.malePathIndicator.width / 2;

    
}

- (void)viewDidAppear:(BOOL)animated {
    [Utils setDefaultsForKey:@"defaults_partner_signup" withValue:nil];
    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:nil];
    
    // logging
    [Logging syncLog:PAGE_IMP_CHOOSE_JOURNEY eventData:@{}];
    [CrashReport leaveBreadcrumb:@"ChooseJourneyViewController"];
}

- (IBAction)backButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)tryingToConceiveClicked:(id)sender {
    [Logging syncLog:BTN_CLK_CHOOSE_TTC eventData:@{}];
    
    NSDictionary *setting = @{SETTINGS_KEY_CURRENT_STATUS: @(AppPurposesTTC)};
    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:setting];
    [self performSegueWithIdentifier:@"onboarding" sender:self from:self];
}

- (IBAction)notTryingClicked:(id)sender {
    [Logging syncLog:BTN_CLK_CHOOSE_NO_TTC eventData:@{}];
    
    NSDictionary *setting = @{SETTINGS_KEY_CURRENT_STATUS: @(AppPurposesNormalTrack)};
    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:setting];
    [self performSegueWithIdentifier:@"onboarding" sender:self from:self];
}

- (IBAction)treatmentClicked:(id)sender {
    [Logging syncLog:BTN_CLK_CHOOSE_TTC_TREATMENT eventData:@{}];
    
    NSDictionary *setting = @{SETTINGS_KEY_CURRENT_STATUS: @(AppPurposesTTCWithTreatment)};
    [Utils setDefaultsForKey:DEFAULTS_ONBOARDING_ANSWERS withValue:setting];
    [self performSegueWithIdentifier:@"onboarding" sender:self from:self];
}

- (IBAction)malePathClicked:(id)sender {
    [Logging syncLog:BTN_CLK_CHOOSE_MALE eventData:@{}];
    [self performSegueWithIdentifier:@"male" sender:self from:self];
}


@end



@interface StartupViewController () <TTTAttributedLabelDelegate>
{
    BOOL firstAppear;
    GLSSOServiceLoginStatus *loginStatus;
}

@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIView *blurView;

@property (weak, nonatomic) IBOutlet UIView *singleLoginView;
@property (weak, nonatomic) IBOutlet UIButton *continueAsButton;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *notYouLabel;

@property (weak, nonatomic) IBOutlet UIView *mewContainerView;
@property (weak, nonatomic) IBOutlet UIButton *mewSignupButton;
@property (weak, nonatomic) IBOutlet UIButton *mewLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *mewParterSignupButton;

@property (strong, nonatomic) WalkThroughFlowController *walkThroughFlowController;


- (IBAction)signupButtonClicked:(id)sender;
- (IBAction)loginButtonClicked:(id)sender;
- (void)showNetworkLoading;
- (void)hideNetworkLoading;
@end

@implementation StartupViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([Utils getDefaultsForKey:USER_DEFAULTS_KEY_UNDER_HOME_PAGE_TRANSITION]) {
        return;
    }
    
    // logging
    [Logging syncLog:PAGE_IMP_START eventData:@{}];
    [CrashReport leaveBreadcrumb:@"StartupViewController"];
    

    if ([User currentUser]) {
        // This is because the user click "continue as" first, then click back to the start up page.
        [[User currentUser] logout];
    }
    
    [self publish:EVENT_STARTUP_VIEW_APPEAR];
    
    [self checkResetPasswordRequest];
    
    /* leve the code here as example
       after analyze the a/b test result, we will use flow A
    [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ONBOARDING_PICKER withValue:nil];
    if (firstAppear) {
        NSNumber * pickerAB = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_ONBOARDING_PICKER];
        if (!pickerAB) {
            [Utils setDefaultsForKey:USER_DEFAULTS_KEY_ONBOARDING_PICKER withValue:@(AB_TEST_ONBOARDING_PICKER_NORMAL)];
        }
    }
    */
    
    if (firstAppear) {
        self.walkThroughFlowController = [[WalkThroughFlowController alloc] initWithParentViewController:self];
        [self.walkThroughFlowController setupWalkThroughFlow];
        [self stylishViews];
        [self startupAnimation];
        firstAppear = NO;
    }
    
    [self subscribe:EVENT_APP_BECOME_ACTIVE selector:@selector(checkResetPasswordRequest)];
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self unsubscribe:EVENT_APP_BECOME_ACTIVE];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstAppear = YES;
    
    [self setupViews];
}


- (void)dealloc
{
    [self unsubscribeAll];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)setupViews
{
    loginStatus = [[GLSSOServiceCore sharedInstance] loginStatus];
    if (loginStatus) {
        self.continueAsButton.layer.cornerRadius = self.continueAsButton.frame.size.height / 2;
        [self.continueAsButton addTarget:self action:@selector(touchOnSignUpButton:) forControlEvents:UIControlEventTouchDown];
        [self.continueAsButton addTarget:self action:@selector(touchEndOnSignUpButton:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        NSString *displayName = [GLNameFormatter stringFromFirstName:loginStatus.firstname lastName:loginStatus.lastname];
        NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"Continue as %@", nil), displayName]];
        NSRange nameRange = [[title string] rangeOfString:displayName];
        [title addAttribute:NSFontAttributeName value:[Utils boldFont:18] range:nameRange];
        [title addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0, title.length)];
        [self.continueAsButton setAttributedTitle:title forState:UIControlStateNormal];
        
        self.notYouLabel.delegate = self;
        {
            UIColor *unselectColor = self.notYouLabel.textColor;
            UIColor *selectColor = [UIColor grayColor];
            NSRange range = [self.notYouLabel.text rangeOfString:NSLocalizedString(@"Click here to switch user",nil)];
            self.notYouLabel.linkAttributes = @{NSForegroundColorAttributeName : (id)unselectColor.CGColor, NSUnderlineStyleAttributeName: @1};
            self.notYouLabel.activeLinkAttributes = @{NSForegroundColorAttributeName : (id)selectColor.CGColor, NSUnderlineStyleAttributeName: @1};
            [self.notYouLabel addLinkToURL:[NSURL URLWithString:[Utils makeUrl:TOS_URL]] withRange:range];
        }
    }
    else {
        [self stylishViews];
    }
}


- (void)stylishViews {
    
    self.singleLoginView.alpha = 0;
    self.mewContainerView.alpha = 0;
    self.blurView.top = self.view.height;
    
    self.mewSignupButton.layer.cornerRadius = self.mewSignupButton.height / 2;
    
    NSDictionary *attrs = @{NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle),
                            NSForegroundColorAttributeName: UIColorFromRGB(0x5a62d2)};
    self.mewLoginButton.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Log in"
                                                                                 attributes:attrs];
    self.mewParterSignupButton.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Sign up here"
                                                                                           attributes:attrs];
}

#pragma mark -
- (void)showNetworkLoading {
    [NetworkLoadingView showWithoutAutoClose];
}

- (void)hideNetworkLoading {
    [NetworkLoadingView hide];
}


# pragma mark - Animations
- (void)startupAnimation
{
    if (loginStatus) {
        [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
            self.singleLoginView.alpha = 1.0;
        } completion:nil];
        
        return;
    }
    
    [self showSignupView];
}


- (void)showSignupView
{
    if (self.walkThroughFlowController.flowType == WalkThroughFlowTypeA) {
        [UIView animateWithDuration:0.5 delay:1.2 options:0 animations:^{
            self.blurView.top = self.view.height - self.blurView.height;
        } completion:NULL];
    }
    else {
        [UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
            self.mewContainerView.alpha = 1.0;
        } completion:NULL];
    }
}


# pragma mark - Reset password request
- (void)checkResetPasswordRequest {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey:kResetPassword] && [defaults stringForKey:kResetPasswordUserToken]) {
        NSString *ut = [defaults stringForKey:kResetPasswordUserToken];
        GLLog(@"the ut:%@", ut);
        [self resetPassword:ut];
        
        [defaults removeObjectForKey:kResetPassword];
        [defaults removeObjectForKey:kResetPasswordUserToken];
        [defaults synchronize];
    }
}


- (void)resetPassword:(NSString *)ut {
    ResetPasswordViewController *c = (ResetPasswordViewController *)[UIStoryboard recoverPassword];
    [c setUt:ut];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:c];
    
    if ([self presentedViewController]) {
        [self dismissViewControllerAnimated:NO completion:^{
            [self presentViewController:nav animated:YES completion:nil];
        }];
    } else {
        [self presentViewController:nav animated:YES completion:nil];
    }
}


#pragma mark - TTTAttributedLabelDelegate
- (void)attributedLabel:(TTTAttributedLabel *)label
   didSelectLinkWithURL:(NSURL *)url
{
    [self notYouTapped:label];
}



# pragma mark - Button Click Actions
- (void)touchOnSignUpButton:(UIButton *)sender {
    sender.backgroundColor = GLOW_COLOR_PURPLE;
}

- (void)touchEndOnSignUpButton:(UIButton *)sender {
    sender.backgroundColor = UIColorFromRGBA(0x5a62d2e5);
}

- (IBAction)signupButtonClicked:(id)sender {
    // we don't have navigation controller, so no need from:self
    [self performSegueWithIdentifier:@"chooseJourney" sender:self];
    [Logging syncLog:BTN_CLK_START_SIGNUP eventData:nil];
}

- (IBAction)loginButtonClicked:(id)sender {
    // we don't have navigation controller, so no need from:self
    [self performSegueWithIdentifier:@"signin" sender:self];
    [Logging syncLog:BTN_CLK_START_LOGIN eventData:nil];
}



- (IBAction)continueAsTapped:(id)sender {
    [self showNetworkLoading];
    [User signInWithToken:loginStatus.token completionHandler:^(NSError *err)
     {
         [self hideNetworkLoading];
         if (err)
         {
             GLLog(@"Token login failed");
             UIAlertView *alertView = [UIAlertView bk_alertViewWithTitle:NSLocalizedString(@"Sorry", nil) message:[err userInfo][@"msg"] ?: NSLocalizedString(@"Sign in failed", nil)];
             __weak typeof(self) wself = self;
             [alertView bk_addButtonWithTitle:NSLocalizedString(@"OK", nil) handler:^()
              {
                  [wself notYouTapped:alertView];
              }];
             [alertView show];
         }
         else
         {
             User *user = [User currentUser];
             if (!user.onboarded)
             {
                 ChooseJourneyViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"chooseJourney"];
                 vc.hidePartnerSignUp = YES;
                 UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                 [self hideNetworkLoading];
                 [self presentViewController:nav animated:YES completion:nil];
             }
             else
             {
                 [self presentViewController:[UIStoryboard main] animated:YES completion:nil];
             }
         }
     }];
}

- (void)notYouTapped:(id)sender
{
    self.singleLoginView.userInteractionEnabled = NO;
    [self showSignupView];
    [UIView animateWithDuration:0.3 animations:^() {
         self.singleLoginView.alpha = 0;
     } completion:NULL];
}

- (IBAction)unwindFromEmailVerification:(UIStoryboardSegue *)segue
{

}


@end

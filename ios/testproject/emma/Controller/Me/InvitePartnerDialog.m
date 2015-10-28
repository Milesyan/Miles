//
//  InvitePartnerDialog.m
//  emma
//
//  Created by Ryan Ye on 3/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define TAG_INVITE_BUTTON_EMAIL 1
#define TAG_INVITE_BUTTON_FB 2

#import "AppDelegate.h"
#import "GLDialogViewController.h"
#import "DropdownMessageController.h"
#import "DropdownMessageController.h"
#import "InvitePartnerDialog.h"
#import "Logging.h"
#import "Network.h"
#import "NetworkLoadingView.h"
#import "PillGradientButton.h"
#import "StatusBarOverlay.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "User.h"
#import <QuartzCore/QuartzCore.h>

@interface InvitePartnerDialog()<UITextFieldDelegate> {
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) IBOutlet UIView *fbInviteView;
@property (strong, nonatomic) IBOutlet UIView *emailInviteView;

@property (nonatomic, strong) IBOutlet UILabel *partnerNameLabel;
@property (nonatomic, strong) IBOutlet PillGradientButton *inviteButton;
@property (nonatomic, strong) IBOutlet UIButton *inviteEmailButton;
@property (nonatomic, strong) IBOutlet UIImageView *profileImageView;
@property (nonatomic, strong) NSDictionary *partnerInfo;
@property (nonatomic, strong) User *user;
@property (nonatomic, strong) GLDialogViewController *dialog;
@property (strong, nonatomic) IBOutlet UIView *profileImageContainer;

@property (strong, nonatomic) IBOutlet UITextField *emailTextField;
@property (strong, nonatomic) IBOutlet UITextField *nameTextField;

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *emailTextFieldBGs;

@property (strong, nonatomic) IBOutlet UILabel *inviteTitleLabel;
@property (strong, nonatomic) IBOutlet UILabel *inviteMainTextLabel;
@property (strong, nonatomic) IBOutlet UILabel *inviteSubTextLabel;

@property (strong, nonatomic) UITapGestureRecognizer *tapRec;
@property (strong, nonatomic) DropdownMessageController *msgController;

- (NSString *)partnerFirstName;
- (IBAction)inviteButtonClicked:(id)sender;

@end 


@implementation InvitePartnerDialog

- (id)initWithUser:(User *)user {
    self = [super initWithNibName:@"InvitePartnerDialog" bundle:nil];
    if (self) {
        self.user = user;
        self.tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:) ];
        [self.view addGestureRecognizer:self.tapRec];
        self.msgController = [DropdownMessageController sharedInstance];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.scrollView.contentSize = CGSizeMake(250, self.emailInviteView.height);

}

- (void)viewDidLoad
{
    [self customizeInviteButton];
    
    for (UIView *bg in self.emailTextFieldBGs) {
        [bg.layer setBorderColor:[UIColorFromRGB(0xdddddd) CGColor]];
        [bg.layer setBorderWidth:0.5];
        [bg.layer setCornerRadius:8];
    }
    
    if (self.user.isMale) {
        self.inviteMainTextLabel.text = @"Track fertility health along with your partner! Just enter their email here and then tell them to use the same email address to create their own account. Your accounts will then be automatically linked.";
        self.inviteSubTextLabel.text = @"Certain data about your weight, masturbation, and erection will be kept private.";
    }

}

- (void)tapped:(UIGestureRecognizer *)sender {
    [self.view findAndResignFirstResponder];
}

- (void)present
{
    [CrashReport leaveBreadcrumb:@"InvitePartnerDialog"];
    self.dialog = [GLDialogViewController sharedInstance];

    @weakify(self)
    [self subscribeOnce:EVENT_DIALOG_CLOSE_BUTTON_CLICKED obj:self.dialog handler:^(Event *evt){
        @strongify(self)
        [Logging log:BTN_CLK_INVITE_PARTNER_CLOSE];
        [self publish:EVENT_INVITE_PARTNER_CANCELLED];
        [self publish:EVENT_INVITE_PARTNER_DIALOG_DISMISS];
    }];
    
    [self showEmailInviteDialog];
}

- (void)showEmailInviteDialog
{
    [self.fbInviteView removeFromSuperview];

    if (self.user.partner && self.user.partner.status == USER_STATUS_NORMAL) {
        //do nothing
    }
    else {
        [self.dialog presentWithContentController:self];
    }
    
}

- (void)missingPartnerAlert {

}


- (void)customizeInviteButton {
    [self.inviteButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    self.inviteEmailButton.layer.cornerRadius = self.inviteEmailButton.height / 2;
}

- (NSString *)partnerFirstName {
    NSString *name = [self.partnerInfo objectForKey:@"name"];
    return [[name componentsSeparatedByString:@" "] objectAtIndex:0];
}


- (IBAction)inviteButtonClicked:(id)sender {
    UIButton *button = (UIButton *)sender;
    
    if (button.tag == TAG_INVITE_BUTTON_EMAIL) {
        [Logging log:BTN_CLK_INVITE_PARTNER_EMAIL];
        BOOL isemail = [Utils isValidEmail:self.emailTextField.text];
        if (isemail && self.nameTextField.text && ![[Utils trim:self.nameTextField.text] isEqualToString:@""]) {
            [self.dialog close];
            [self publish:EVENT_INVITE_PARTNER_DIALOG_DISMISS];
            [self.user invitePartnerByEmail:@{
                                            @"email": self.emailTextField.text,
                                             @"name":[Utils trim:self.nameTextField.text]
                                            }
                          completionHandler:^(User *user, NSError *error) {
                              if (!error) {
                                  [[StatusBarOverlay sharedInstance] postMessage:@"Invitation sent!" duration:3 ];
                                  if (self.user.isFemale && self.user.partner.isFemale) {
                                      [[[UIAlertView alloc] initWithTitle:nil message:@"Heads up! You're attempting to connect to another female user. If this is correct,  know that your partner will no longer be able to track her own cycles. She will see your calendar instead. If your partner is male but set up a female account, please have him set up a new account with a different email address or contact support@glowing.com for assistance." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                                  }
                              } else {
                                  NSString *msg = [error.userInfo objectForKey:@"msg"];
                                  [[[UIAlertView alloc] initWithTitle:@"Failed to invite partner" message:msg delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];
                              }

            }];
        } else {
            if (isemail) {
                [self.nameTextField becomeFirstResponder];
            } else {
                [self.msgController postMessage:@"Please input a valid address." duration:3 position:60 inView:self.view.window];
                [self.emailTextField becomeFirstResponder];
            }
        }
    } else if (button.tag == TAG_INVITE_BUTTON_FB){
        [Logging log:BTN_CLK_INVITE_PARTNER_FB];
        [self.dialog close];

        [self.user invitePartnerOnFacebook:self.partnerInfo completionHandler:nil];
        NSDictionary *params = @{@"to" : [self.partnerInfo objectForKey:@"id"]};
        NSString *fbRequestTitle = [NSString stringWithFormat:@"Invite %@", self.partnerFirstName];
        NSString *fbRequestMessage = self.user.currentPurpose == AppPurposesTTC ? 
            @"Join Glow with me so we can know the best time to try for a baby!" :
            @"Join Glow with me so we can have better insights to our reproductive health!";

        [FBWebDialogs presentRequestsDialogModallyWithSession:[User session]
                                                      message:fbRequestMessage
                                                        title:fbRequestTitle
                                                   parameters:params handler:^(FBWebDialogResult result, NSURL *resultURL, NSError *fbErr) {
                                                       [self publish:EVENT_INVITE_PARTNER_DIALOG_DISMISS];
                                                   }];

    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (textField == self.nameTextField) {
        [self.emailTextField becomeFirstResponder];
    } else if (textField == self.emailTextField) {
        if ([Utils isValidEmail:self.emailTextField.text]) {
            if (!self.nameTextField.text || [[Utils trim:self.nameTextField.text] isEqualToString:@""]) {
                [self.nameTextField becomeFirstResponder];
            } else {
                [textField resignFirstResponder];
                [self inviteButtonClicked:self.inviteEmailButton];
            }
        } else {
            [self.msgController postMessage:@"Please input a valid address." duration:3 position:60 inView:self.view.window];
        }
    }
    
    return YES;
}

+ (void)openDialog {
    InvitePartnerDialog * dlg = [[InvitePartnerDialog alloc] initWithUser:[User currentUser]];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) pushDialog:dlg];
}

@end

//
//  ForumInviteToGroupViewController.m
//  Pods
//
//  Created by Peng Gu on 4/22/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLWebViewController.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDialogViewController.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import "ForumInviteToGroupViewController.h"
#import "Forum.h"


@interface ForumInviteToGroupViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *inviteMessageTextView;
@property (weak, nonatomic) IBOutlet UIView *inviteMessageFrameView;
@property (weak, nonatomic) IBOutlet UILabel *inviteToGroupPlaceholder;


@property (assign, nonatomic) uint64_t groupIdToInvite;
@property (copy, nonatomic) NSString *groupNameToInvite;
@property (strong, nonatomic) ForumGroup *group;
@property (strong, nonatomic) ForumUser *user;
@property (weak, nonatomic) GLDialogViewController *dialog;

@end


@implementation ForumInviteToGroupViewController


+ (void)presentForUser:(ForumUser *)user group:(ForumGroup *)group
{
    [[[ForumInviteToGroupViewController alloc] initWithUser:user group:group] present];
}


- (instancetype)initWithUser:(ForumUser *)user group:(ForumGroup *)group
{
    self = [super initWithNibName:@"ForumInviteToGroupViewController" bundle:nil];
    if (self) {
        _group = group;
        _groupIdToInvite = group.identifier;
        _groupNameToInvite = group.name;
        _user = user;
    }
    return self;
}


- (void)present
{
    self.dialog = [GLDialogViewController sharedInstance];
    [self showInviteView];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.inviteMessageFrameView.layer.borderWidth = 1.0;
    self.inviteMessageFrameView.layer.borderColor = UIColorFromRGB(0xd5d5d2).CGColor;
    self.inviteMessageFrameView.layer.cornerRadius = 5.0;
    
    self.inviteMessageTextView.text = catstr(@"Hi there! Join me in ", self.groupNameToInvite, @"!", nil);
    self.inviteMessageTextView.delegate = self;
}


- (void)showInviteView
{
    [GLNetworkLoadingView show];
    
    [Forum isUser:self.user.identifier alreadyInGroup:self.groupIdToInvite
         callback:^(NSDictionary *result, NSError *error) {
             
             [GLNetworkLoadingView hide];
             UIWindow *window = [UIApplication sharedApplication].keyWindow;
             
             if (error) {
                 NSString *msg = @"Network error. Please try again later.";
                 [[GLDropdownMessageController sharedInstance] postMessage:msg
                                                                  duration:3
                                                                  position:84
                                                                    inView:window];
                 return;
             }
             
             if ([result[@"not_in"] boolValue]) {
                 [self.dialog presentWithContentController:self canClose:YES];
                 return;
             }
             
             NSString *defaultMsg = catstr(self.user.firstName, @" is already in this group!", nil);
             NSString *msg = result[@"msg"] ? result[@"msg"] : defaultMsg;
             [[GLDropdownMessageController sharedInstance] postMessage:msg
                                                              duration:3
                                                              position:84
                                                                inView:window];
         }];
    
}


- (IBAction)sendInvitationButtonClicked:(id)sender {
    [Forum inviteUser:self.user.identifier
              toGroup:self.groupIdToInvite
              message:self.inviteMessageTextView.text];
    
    [[GLDropdownMessageController sharedInstance] postMessage:@"Invitation sent!"
                                                     duration:3 position:84 inView: self.view.window];
    [self.dialog close];
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return NO;
    }
    
    NSUInteger newLength = textView.text.length + text.length - range.length;
    NSUInteger maxLength = 0;
    
    if (textView == self.inviteMessageTextView) {
        maxLength = 100;
        self.inviteToGroupPlaceholder.hidden = newLength > 0;
    }
    
    return (newLength > maxLength) ? NO : YES;
}


@end

//
//  ForumEditProfileViewController.m
//  Pods
//
//  Created by Peng Gu on 4/22/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLTextField.h>
#import <GLFoundation/GLImagePicker.h>
#import <GLFoundation/GLPillGradientButton.h>
#import <GLFoundation/GLDialogViewController.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import <JDStatusBarNotification/JDStatusBarNotification.h>

#import "ForumEditProfileViewController.h"
#import "Forum.h"


#define kTagProfileImage        1001
#define kTagBackgroundImage     1002


@interface ForumEditProfileViewController () <UITextFieldDelegate, UITextViewDelegate, GLImagePickerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *myProfileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *myBackgroundImageView;
@property (weak, nonatomic) IBOutlet GLTextField *firstNameField;
@property (weak, nonatomic) IBOutlet GLTextField *lastNameField;
@property (weak, nonatomic) IBOutlet UITextView *bioTextView;
@property (weak, nonatomic) IBOutlet UILabel *bioPlaceholder;
@property (weak, nonatomic) IBOutlet GLTextField *locationField;
@property (weak, nonatomic) IBOutlet UISwitch *postsPrivacySwitch;
@property (weak, nonatomic) IBOutlet UILabel *privacyLabel;

@property (assign, nonatomic) NSInteger tagWaitingImage;
@property (strong, nonatomic) ForumUser *user;

@end



@implementation ForumEditProfileViewController


- (instancetype)initWithUser:(id)user
{
    ForumEditProfileViewController * vc = [[Forum storyboard] instantiateViewControllerWithIdentifier:@"ForumEditProfile"];
    vc.user = user;
    return vc;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.hidesBottomBarWhenPushed = YES;
    self.myProfileImageView.layer.masksToBounds = YES;
    self.myProfileImageView.layer.cornerRadius = self.myProfileImageView.frame.size.width / 2;
    
    if (self.user.cachedProfileImage) {
        self.myProfileImageView.image = self.user.cachedProfileImage;
    }
    else if (self.user.profileImage.length > 0) {
        @weakify(self)
        [self.myProfileImageView sd_setImageWithURL:[NSURL URLWithString:self.user.profileImage]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
         {
             @strongify(self)
             if (image) {
                 self.user.cachedProfileImage = image;
                 self.myProfileImageView.image = image;
             }
         }];
    }
    
    self.myBackgroundImageView.layer.masksToBounds = YES;
    self.myBackgroundImageView.layer.cornerRadius = 5.0;
    self.myBackgroundImageView.image = self.user.cachedBackgroundImage;
    
    self.bioTextView.delegate = self;
    
    self.firstNameField.text = self.user.firstName;
    self.lastNameField.text = self.user.lastName;
    self.bioTextView.text = self.user.bio;
    self.locationField.text = self.user.location;
    self.bioPlaceholder.hidden = self.bioTextView.text.length > 0;
    
    [self.postsPrivacySwitch setOn:self.user.hidePosts];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (IBAction)saveProfile:(id)sender
{
    [self.view endEditing:YES];
    BOOL modified = NO;
    ForumUser *currentUser = [Forum currentForumUser];
    NSString *firstName = [self.firstNameField.text trim];
    NSString *lastName = [self.lastNameField.text trim];
    NSString *bio = [self.bioTextView.text trim];
    NSString *location = [self.locationField.text trim];
    if (firstName.length == 0) {
        [self.firstNameField becomeFirstResponder];
        [[GLDropdownMessageController sharedInstance] postMessage:@"Please enter your first name." duration:3 position:60 inView:self.view.window];
        return;
    }
    if (firstName && ![currentUser.firstName isEqualToString:firstName]) {
        currentUser.firstName = firstName;
        modified = YES;
    }
    if (lastName && ![currentUser.lastName isEqualToString:lastName]) {
        currentUser.lastName = lastName;
        modified = YES;
    }
    if (bio && ![currentUser.bio isEqualToString:bio]) {
        currentUser.bio = bio;
        modified = YES;
    }
    if (location && ![currentUser.location isEqualToString:location]) {
        currentUser.location = location;
        modified = YES;
    }
    if (currentUser.hidePosts != self.postsPrivacySwitch.isOn) {
        [Forum log:BTN_CLK_FORUM_PROFILE_HIDE_POSTS eventData:@{@"switch_on": @(self.postsPrivacySwitch.isOn)}];
        currentUser.hidePosts = self.postsPrivacySwitch.isOn;
        modified = YES;
    }
    
    if (modified) {
        [Forum updateUserProfile:currentUser];
        [self publish:kForumEditProfileViewControllerDidUpdateProfileInfo];
        [JDStatusBarNotification showWithStatus:@"Updated!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)updateProfilePhoto:(id)sender
{
    self.tagWaitingImage = kTagProfileImage;
    [[GLImagePicker sharedInstance] showInController:self
                                           withTitle:@"Change profile photo"];
}


- (IBAction)updateCoverPhoto:(id)sender
{
    self.tagWaitingImage = kTagBackgroundImage;
    [[GLImagePicker sharedInstance] showInController:self
                                           withTitle:@"Change background image"
                              destructiveButtonTitle:@"Restore default"
                                       allowsEditing:NO];
}


- (IBAction)updatePostPrivacy:(id)sender
{
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSUInteger newLength = textField.text.length + string.length - range.length;
    NSUInteger maxLength = 0;
    if (textField == self.firstNameField || textField == self.lastNameField || textField == self.locationField) {
        maxLength = 25;
    }
    return (newLength > maxLength) ? NO : YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.firstNameField) {
        [self.lastNameField becomeFirstResponder];
    }
    else if (textField == self.lastNameField) {
        [self.bioTextView becomeFirstResponder];
    }
    else {
        [self.view endEditing:YES];
    }
    
    return NO;
}


- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return NO;
    }
    
    NSUInteger newLength = textView.text.length + text.length - range.length;
    NSUInteger maxLength = 0;
    if (textView == self.bioTextView) {
        maxLength = 120;
        self.bioPlaceholder.hidden = newLength > 0;
    }
    
    return (newLength > maxLength) ? NO : YES;
}


#pragma mark - ImagePicker

- (void)imagePicker:(GLImagePicker *)imagePicker didPickedImage:(UIImage *)image
{
    if (self.tagWaitingImage == kTagProfileImage) {
        self.myProfileImageView.image = image;
        self.user.cachedProfileImage = image;
        [Forum updateProfileImage:image];
        [JDStatusBarNotification showWithStatus:@"Updated!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }
    else if (self.tagWaitingImage == kTagBackgroundImage) {
        self.myBackgroundImageView.image = image;
        self.user.cachedBackgroundImage = image;
        [Forum updateBackgroundImage:image];
        [JDStatusBarNotification showWithStatus:@"Updated!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }
}


- (void)imagePickerDidClickDestructiveButton:(GLImagePicker *)imagePicker
{
    if (self.tagWaitingImage == kTagBackgroundImage) {
        [Forum restoreBackgroundImage];
        self.myBackgroundImageView.image = [Forum defaultBackgroundImage];
        self.user.cachedBackgroundImage = self.myBackgroundImageView.image;
        [JDStatusBarNotification showWithStatus:@"Updated!" dismissAfter:2.0 styleName:GLStatusBarStyleSuccess];
    }
}


@end

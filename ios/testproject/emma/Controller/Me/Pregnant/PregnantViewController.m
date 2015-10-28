//
//  PregnantViewController.m
//  emma
//
//  Created by Eric Xu on 10/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "PregnantViewController.h"
#import "UIImage+blur.h"
#import "ImagePicker.h"
#import "User.h"
#import "NetworkLoadingView.h"
#import "PillGradientButton.h"
#import "TabbarController.h"
#import "Logging.h"
#import "UIImage+Resize.h"
#import "StatusBarOverlay.h"
#import "Forum.h"

@interface ShareSettingsViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISwitch *anonymously;
@property (strong, nonatomic) IBOutlet UISwitch *notificaitons;
@property (strong, nonatomic) IBOutlet UISwitch *followUp;

@property (strong, nonatomic) PregnantViewController *ref;

@end

@implementation ShareSettingsViewController

- (void)viewWillAppear:(BOOL)animated
{
    User *u = [User currentUser];
    self.anonymously.on = self.ref.anonymously;
    self.notificaitons.on = u.settings.receivePushNotification != 0;
    self.followUp.on = u.settings.allowFollowUp != 0;
}

- (IBAction)anonymouslySwitched:(id)sender {
    if (self.ref) {
        self.ref.anonymously = self.anonymously.on;
    }
}

- (IBAction)notificationSwitched:(id)sender {
    [[User currentUser].settings update:@"receivePushNotification" intValue:self.notificaitons.on? 0: 1];
}

- (IBAction)followUpSwitched:(id)sender {
    [[User currentUser].settings update:@"allowFollowUp" intValue:self.followUp.on? 1: 0];
}

@end


@interface PregnantViewController () <UITextViewDelegate, ImagePickerDelegate, UIActionSheetDelegate> {
    UIEdgeInsets originInsets;
}
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet EmmaTextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet UIButton *buttonImage;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomViewBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topViewTopConstraint;

@end

@implementation PregnantViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.anonymously = NO;
    self.textView.delegate = self;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[[self navigationController] navigationBar] setNeedsLayout];
    
    [[self navigationItem] setTitle:@"Congrats!"];
}

- (void)viewDidAppear:(BOOL)animated
{
    [Logging log:PAGE_IMP_PREGNANT];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[self navigationItem] setTitle:@""];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillChangeFrame:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [self changeTextViewFrameWithKeyboardHeight:kbSize.height animated:YES];
}

- (void)keyboardWillShow:(NSNotification *)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    [self changeTextViewFrameWithKeyboardHeight:kbSize.height animated:YES];
}

- (void)keyboardWillHide:(NSNotification *)aNotification
{
    [self changeTextViewFrameWithKeyboardHeight:0.0 animated:YES];
}

- (void)changeTextViewFrameWithKeyboardHeight:(CGFloat)kbHeight animated:(BOOL)animated
{
//    GLLog(@"%f", kbHeight);
//    CGRect toolbarFrame = self.bottomView.frame;
//    toolbarFrame.origin.y = self.view.bounds.size.height - toolbarFrame.size.height - kbHeight;
//    
//    CGRect topFrame = self.topView.frame;
//    
//    if (kbHeight > 0.0) {
//        topFrame.origin.y = 64.0 + 5.0 - self.textViewPlaceholder.frame.origin.y;
//        topFrame.size.height = toolbarFrame.origin.y - topFrame.origin.y;
//    } else {
//        topFrame.origin.y = 64.0;
//        topFrame.size.height = toolbarFrame.origin.y - topFrame.origin.y;
//    }
//
//    CGRect cameraFrame = self.buttonImage.frame;
//    cameraFrame.origin.y = toolbarFrame.origin.y - cameraFrame.size.height;
//    self.buttonImage.frame = cameraFrame;
    
//    GLLog(@"peng debug: %@\n%@", NSStringFromCGPoint(toolbarFrame.origin), NSStringFromCGPoint(topFrame.origin));
    
    if (animated) {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomViewBottomConstraint.constant = kbHeight;
            self.topViewTopConstraint.constant = MAX(-160, -kbHeight);
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    else {
        self.bottomViewBottomConstraint.constant = kbHeight;
        self.topViewTopConstraint.constant = -kbHeight;
    }
    //    [self checkTextViewCaretOverflow:self.textView];
}

#pragma mark - Table view data source
//

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.5;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.5)];
    [headerView setBackgroundColor:section == 1? UIColorFromRGB(0xC8C7CC): [UIColor clearColor]];
    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            //
        } else if (indexPath.row == 1) {
            // logging
            [Logging log:BTN_CLK_PREGNANT_ADD_PHOTO];
            [[ImagePicker sharedInstance] showInController:self withTitle:@"Maybe a photo of your pregnancy test!"];
        }
    }
 }

#pragma mark - Button Action

- (IBAction)cancel:(id)sender {
    [self.view endEditing:YES];
    
    // logging
    [Logging log:BTN_CLK_PREGNANT_CANCEL];
    [self publish:EVENT_SWITCH_PREGNANT_CANCELLED];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)later:(id)sender
{
    [self.view endEditing:YES];
    
    // logging
    [Logging log:BTN_CLK_PREGNANT_LATER];
    
    // set LATER_SHARE_CLICK_TIME_KEY to UserDefault, so share success story later
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSDate date] forKey:USER_DEFAULTS_LATER_SHARE_CLIKE_TIME];
    [defaults synchronize];
    
    [self dismissSharePregnant:NO];
}

- (void)dismissSharePregnant:(BOOL)shared {
    [self publish:EVENT_SWITCH_PREGNANT_CONFIRMED];
    [self dismissViewControllerAnimated:YES completion:^{
        [self publish:PREGNANT_VIEW_CONTROLLER_DISMISSED data:@(shared)];
    }];
}

- (IBAction)share:(id)sender
{
    User *user = [User currentUser];
    [user save];
    
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *textContent = [content stringByStrippingHtmlTags];
    
    if (textContent.length < FORUM_MIN_CONTENT_LENGTH) {
        [[StatusBarOverlay sharedInstance] postMessage:@"Sorry, the content is too short" duration:4.0];
        return;
    } else if (textContent.length > FORUM_MAX_CONTENT_LENGTH) {
        [[StatusBarOverlay sharedInstance] postMessage:@"Sorry, the content is too long" duration:4.0];
        return;
    }

    int anony = self.anonymously ? 1 : 0;
    // logging
    NSDictionary *usedImages = self.textView.usedImages;
    [Logging log:BTN_CLK_PREGNANT_SHARE eventData:@{@"anonymous": @(anony),
                                                    @"photos": @(usedImages.count)}];
    
    // clear the later share click time, so that we will not pop the dialog again
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:USER_DEFAULTS_LATER_SHARE_CLIKE_TIME];
    [defaults synchronize];
    
    [self.view endEditing:YES];    
    [self.titleField resignFirstResponder];
    [NetworkLoadingView showWithoutAutoClose];
    
    [user sharePregnant:content withTitle:nil andPhotos:usedImages anonymously:self.anonymously callback:^(NSError *error) {
        GLLog(@"callback");
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error sharing your story"
                                        message:@"Please try again later."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil] show];
        } else {
            [self dismissSharePregnant:YES];
        }
        [NetworkLoadingView hide];
    }];
}


#pragma mark -  UITextViewDelegate
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [UIView animateWithDuration:0.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.textViewPlaceholder.alpha = 0;
                     }
                     completion:nil];
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (!textView.text || [[Utils trim:textView.text] isEqualToString:@""]) {
        [UIView animateWithDuration:0.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.textViewPlaceholder.alpha = 1  ;
                         }
                         completion:nil];
    }
}

#pragma mark -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    GLLog(@"segue:%@ sender:%@", segue.destinationViewController, sender);
    ShareSettingsViewController *dest = (ShareSettingsViewController *)segue.destinationViewController;
    dest.ref = self;
}

#pragma mark - EmmaTextViewDelegate

- (IBAction)insertImage:(id)sender {
    [self.textView saveCursorPosition];
    [self.view endEditing:YES];
    [[ImagePicker sharedInstance] showInController:self withTitle:@"Chose photo to insert" destructiveButtonTitle:nil allowsEditing:NO];
}

- (void)didPickedImage:(UIImage *)image
{
    if (image.size.width > 640.0) {
        image = [image resizedImage:CGSizeMake(640.0, image.size.height / image.size.width * 640.0) interpolationQuality:kCGInterpolationMedium];
    }
    [self.textView insertImage:image];
}

- (void)imagePickerDidCancle:(ImagePicker *)imagePicker
{
    [self.textView recallCursorPosition];
}

- (void)emmaTextView:(EmmaTextView *)textView didChangeToHeight:(CGFloat)height withCursorPosition:(CGFloat)cursorPos
{
    GLLog(@"Hi");
}

- (void)emmaTextViewDidBeginEditing:(EmmaTextView *)textView
{
    self.textViewPlaceholder.hidden = YES;
}

- (void)emmaTextViewDidChange:(EmmaTextView *)textView
{
}

- (void)emmaTextViewDidEndEditing:(EmmaTextView *)textView
{
    [self hidePlaceholderIfNeeded];
}

- (void)emmaTextViewDidFinishLoading:(EmmaTextView *)textView
{
    GLLog(@"Hi");
}

- (void)hidePlaceholderIfNeeded
{
    self.textViewPlaceholder.hidden = ![self.textView isEmpty];
}
@end

//
//  ForumAddTopicViewController.m
//  emma
//
//  Created by Allen Hsu on 11/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLImagePicker.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import "Forum.h"
#import "ForumAddTopicViewController.h"
#import "ForumGroupPickerViewController.h"

#define TAG_ACTIONSHEET_DISCARD     1001
#define BUTTON_TITLE_CANCEL         @"Cancel"
#define BUTTON_TITLE_DISCARD        @"Discard"

@interface ForumAddTopicViewController () <GLImagePickerDelegate, ForumGroupPickerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *titleField;
@property (weak, nonatomic) IBOutlet GLTextView *textView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadingButtonItem;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UIButton *buttonAnonymous;
@property (weak, nonatomic) IBOutlet UIButton *buttonImage;
@property (weak, nonatomic) ForumGroupPickerViewController *groupPicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;

@property (assign, nonatomic) BOOL notFirstTime;

@end

@implementation ForumAddTopicViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"addTopic"];
}

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
	// Do any additional setup after loading the view.
    
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    self.loadingButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingView];
    
    self.textView.delegate = self;
    self.titleField.delegate = self;
    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateDisabled];
    [self.buttonAnonymous setTitleColor:[self.buttonAnonymous titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    if (!self.notFirstTime && self.titleField.enabled) {
        [self.titleField becomeFirstResponder];
        self.notFirstTime = YES;
    }
    
    if (self.topic) {
        [self.postButtonItem setTitle:@"Update"];
    } else if (self.group) {
        [self.postButtonItem setTitle:@"Post"];
    } else {
        [self.postButtonItem setTitle:@"Next"];
    }
    
    [self internalInitializeTitleView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupModel];

    [Forum log:PAGE_IMP_FORUM_ADD_TOPIC eventData:@{@"group_id": @(self.group.identifier)}];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)setupModel {
    if (self.topic && [NSString isEmptyString:[self.textView fullText]]) {
        self.titleField.text = self.topic.title;
        [self.textView insertText:self.topic.content];
        self.buttonAnonymous.selected = self.topic.isAnonymous;
    }
}

- (void)internalInitializeTitleView {
    if (self.topic) {
        self.navigationItem.title = @"Update Topic";
    } else if (self.group) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 30)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 18)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [GLTheme semiBoldFont:18.0];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = @"Add Topic";
        [titleView addSubview:titleLabel];
        UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, 172, 12)];
        categoryLabel.textAlignment = NSTextAlignmentCenter;
        categoryLabel.font = [GLTheme lightFont:12.0];
        categoryLabel.textColor = [UIColor blackColor];
        categoryLabel.backgroundColor = [UIColor clearColor];
        categoryLabel.text = [NSString stringWithFormat:@"In: %@", self.group.name];
        [titleView addSubview:categoryLabel];
        [self.navigationItem setTitleView:titleView];
    } else {
        self.navigationItem.titleView = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeSelf:(id)sender {
    
    [self.view endEditing:YES];
    
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (self.topic) {
        BOOL titleChanged = ![self.topic.title isEqual:title];
        BOOL contentChanged = ![self.topic.content isEqualToString:content];
        BOOL anonymousChanged = self.topic.isAnonymous != self.buttonAnonymous.selected;
        
        if (titleChanged || contentChanged || anonymousChanged) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to discard edit?" delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL destructiveButtonTitle:BUTTON_TITLE_DISCARD otherButtonTitles:nil];
            actionSheet.tag = TAG_ACTIONSHEET_DISCARD;
            [actionSheet showInView:self.view];
        } else {
            [self dismissSelf:self];
        }
    } else if (title.length > 0 || content.length > 0) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to discard your topic?" delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL destructiveButtonTitle:BUTTON_TITLE_DISCARD otherButtonTitles:nil];
        actionSheet.tag = TAG_ACTIONSHEET_DISCARD;
        [actionSheet showInView:self.view];
    } else {
        [self dismissSelf:sender];
    }
}

- (IBAction)dismissSelf:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleAnonymous:(id)sender {
    self.buttonAnonymous.selected = !self.buttonAnonymous.selected;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == TAG_ACTIONSHEET_DISCARD) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:BUTTON_TITLE_DISCARD]) {
            [self dismissSelf:actionSheet];
        } else if ([buttonTitle isEqualToString:BUTTON_TITLE_CANCEL]) {
            // Cancelled, do nothing
        }
    }
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
    GLLog(@"%f", kbHeight);
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone animations:^{
            self.keyboardHeight.constant = kbHeight;
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        self.keyboardHeight.constant = kbHeight;
        [self.view layoutIfNeeded];
    }
//    [self checkTextViewCaretOverflow:self.textView];
}

- (void)checkTextViewCaretOverflow:(UITextView *)textView
{
    CGRect line = [textView caretRectForPosition:textView.selectedTextRange.start];
    if (line.origin.y == INFINITY) return;
    CGFloat overflow = line.origin.y + line.size.height - (textView.contentOffset.y + textView.bounds.size.height);
    if (overflow > 0) {
        CGPoint offset = textView.contentOffset;
        offset.y += overflow + 5;
        [UIView animateWithDuration:.2 animations:^{
            [textView setContentOffset:offset];
        }];
    }
}

- (IBAction)createTopic:(id)sender {
    if (![self validateForm]) {
        return;
    }
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    if (self.topic) {
        [self updateTopic];
    } else if (self.group) {
        [self createTopicInGroup:self.group];
    } else {
        self.groupPicker = [ForumGroupPickerViewController viewController];
        self.groupPicker.delegate = self;
        [self.navigationController pushViewController:self.groupPicker animated:YES from:self];
    }
}

- (BOOL)validateForm
{
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *plainContent = [content stringByStrippingHtmlTags];
    NSString *errMsg = nil;
    if (title.length < FORUM_MIN_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too short";
    } else if (title.length > FORUM_MAX_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too long";
    } else if (plainContent.length < FORUM_MIN_CONTENT_LENGTH) {
        errMsg = @"Sorry, the content is too short";
    } else if (plainContent.length > FORUM_MAX_CONTENT_LENGTH) {
        errMsg = @"Sorry, the content is too long";
    }
    
    if (errMsg != nil) {
        [[GLDropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
        return NO;
    }
    return YES;
}

- (void)updateTopic {
    if (!self.topic) {
        return;
    }
    if (![self validateForm]) {
        return;
    }
    
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    BOOL titleChanged = ![self.topic.title isEqual:title];
    BOOL contentChanged = ![self.topic.content isEqualToString:content];
    BOOL anonymousChanged = self.topic.isAnonymous != self.buttonAnonymous.selected;
    
    if (titleChanged || contentChanged || anonymousChanged) {
        self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
        self.titleField.enabled = NO;
        //        self.textView.editable = NO;
        self.titleField.textColor = [UIColor grayColor];
        //        self.textView.textColor = [UIColor grayColor];
        self.textView.userInteractionEnabled = NO;
        [self.textView resignFirstResponder];
        self.buttonAnonymous.enabled = NO;
        self.buttonImage.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
        [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        @weakify(self)
        [Forum updateTopic:self.topic.identifier
                   inGroup:self.topic.groupId
                        withTitle:title content:content andImages:self.textView.usedImages
                      anonymously:self.buttonAnonymous.selected
                         callback:^(NSDictionary *result, NSError *error) {
                             @strongify(self)
                             GLLog(@"update topic result: %@, error: %@", result, error);
                             BOOL failed = NO;
                             NSString *message = @"Failed to update the topic";
                             NSInteger errCode = [result integerForKey:@"rc"];
                             NSString *errMsg = [result stringForKey:@"msg"];
                             if (error) {
                                 failed = YES;
                             } else {
                                 if (errCode > 0) {
                                     failed = YES;
                                     if (errMsg) {
                                         message = errMsg;
                                     }
                                 } else {
                                     failed = NO;
                                     [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your topic is successfully updated!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                                     
                                     [self.view endEditing:YES];
                                     [self dismissViewControllerAnimated:NO completion:^(){
                                         [self publish:EVENT_FORUM_TOPIC_UPDATED];
                                     }];
                                 }
                             }
                             
                             if (failed) {
                                 self.navigationItem.rightBarButtonItem = self.postButtonItem;
                                 self.titleField.enabled = YES;
                                 self.titleField.textColor = [UIColor blackColor];
                                 self.textView.userInteractionEnabled = YES;
                                 self.buttonAnonymous.enabled = YES;
                                 self.buttonImage.enabled = YES;
                                 self.navigationItem.leftBarButtonItem.enabled = YES;
                                 [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                                 //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                             }
                         }];
    }

}

- (void)createTopicInGroup:(ForumGroup *)group
{
    if (!group) {
        return;
    }
    
    if (![self validateForm]) {
        return;
    }
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    
    NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
    self.titleField.enabled = NO;
//        self.textView.editable = NO;
    self.titleField.textColor = [UIColor grayColor];
//        self.textView.textColor = [UIColor grayColor];
    self.textView.userInteractionEnabled = NO;
    [self.textView resignFirstResponder];
    self.buttonAnonymous.enabled = NO;
    self.buttonImage.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
    [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    self.groupPicker.enabled = NO;
    @weakify(self)
    [Forum createTopicInGroup:group.identifier
                    withTitle:title content:content andImages:self.textView.usedImages
                  anonymously:self.buttonAnonymous.selected
                     callback:^(NSDictionary *result, NSError *error) {
                         @strongify(self)
                         GLLog(@"create topic result: %@, error: %@", result, error);
                         self.groupPicker.enabled = YES;
                         BOOL failed = NO;
                         NSString *message = @"Failed to post the topic";
                         NSInteger errCode = [result integerForKey:@"rc"];
                         NSString *errMsg = [result stringForKey:@"msg"];
                         if (error) {
                             failed = YES;
                         } else {
                             if (errCode > 0) {
                                 failed = YES;
                                 if (errMsg) {
                                     message = errMsg;
                                 }
                             } else {
                                 if ([result isKindOfClass:[NSDictionary class] forKey:@"result"]) {
                                     failed = NO;
                                     NSDictionary * topicResult = [result objectForKey:@"result"];
                                    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your topic is successfully posted!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                                     
                                     ForumTopic * topic = [[ForumTopic alloc] initWithDictionary:topicResult];
                                     //                        ForumCategory * category = self.category;
                                     [self.view endEditing:YES];
                                     [self dismissViewControllerAnimated:NO completion:^(){
                                         ForumCategory *category = [Forum categoryFromGroup:group];
                                         [topic publish:EVENT_FORUM_ADD_TOPIC_SUCCESS data:
                                          @{@"topic": topic, @"category": category}];
                                     }];
                                 } else {
                                     failed = YES;
                                 }
                             }
                         }
                         
                         if (failed) {
                             self.navigationItem.rightBarButtonItem = self.postButtonItem;
                             self.titleField.enabled = YES;
                             self.titleField.textColor = [UIColor blackColor];
                             self.textView.userInteractionEnabled = YES;
                             self.buttonAnonymous.enabled = YES;
                             self.buttonImage.enabled = YES;
                             self.navigationItem.leftBarButtonItem.enabled = YES;
                            [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                             //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                         }
                     }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.textViewPlaceholder.hidden = (self.textView.fullText.length > 0);
    [self checkTextViewCaretOverflow:textView];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.textView becomeFirstResponder];
    return NO;
}

#pragma mark - EmmaTextViewDelegate

- (IBAction)insertImage:(id)sender {
    [self.textView saveCursorPosition];
    [[GLImagePicker sharedInstance] showInController:self withTitle:@"Choose photo to insert" destructiveButtonTitle:nil allowsEditing:NO];
}

- (void)imagePicker:(GLImagePicker *)imagePicker didPickedImage:(UIImage *)image
{
    if (image.size.width > 640.0) {
        image = [image resizedImage:CGSizeMake(640.0, image.size.height / image.size.width * 640.0) interpolationQuality:kCGInterpolationMedium];
    }
    [self.textView insertImage:image];
}

- (void)imagePickerDidCancel:(GLImagePicker *)imagePicker
{
    [self.textView recallCursorPosition];
}

- (void)GLTextView:(GLTextView *)textView didChangeToHeight:(CGFloat)height withCursorPosition:(CGFloat)cursorPos
{
    GLLog(@"Hi");
}

- (void)GLTextViewDidBeginEditing:(GLTextView *)textView
{
    self.textViewPlaceholder.hidden = YES;
}

- (void)GLTextViewDidChange:(GLTextView *)textView
{
}

- (void)GLTextViewDidEndEditing:(GLTextView *)textView
{
    [self hidePlaceholderIfNeeded];
}

- (void)GLTextViewDidFinishLoading:(GLTextView *)textView
{
    GLLog(@"Hi");
}

- (void)hidePlaceholderIfNeeded
{
    self.textViewPlaceholder.hidden = ![self.textView isEmpty];
}

- (void)groupPicker:(ForumGroupPickerViewController *)picker didPickGroup:(ForumGroup *)group
{
    if (group) {
        [self createTopicInGroup:group];
    }
}

@end

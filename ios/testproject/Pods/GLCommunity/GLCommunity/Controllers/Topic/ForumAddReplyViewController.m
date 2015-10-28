//
//  ForumAddReplyViewController.m
//  emma
//
//  Created by Allen Hsu on 11/25/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLImagePicker.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import "ForumAddReplyViewController.h"
#import "Forum.h"

#define TAG_ACTIONSHEET_DISCARD     1001
#define BUTTON_TITLE_CANCEL         @"Cancel"
#define BUTTON_TITLE_DISCARD        @"Discard"

@interface ForumAddReplyViewController () <GLImagePickerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet GLTextView *textView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadingButtonItem;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (weak, nonatomic) IBOutlet UIButton *buttonImage;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;

@end

@implementation ForumAddReplyViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"addReply"];
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
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    self.loadingButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingView];
    
    self.titleLabel.text = [NSString stringWithFormat:@"Re: %@", self.topic.title ?: @""];
    
    self.textView.delegate = self;
    self.textView.focusOnLoad = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_ADD_REPLY eventData:@{@"topic_id": @(self.topic.identifier), @"group_id": @(self.topic.groupId)}];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)closeSelf:(id)sender {
    
    [self.view endEditing:YES];
    
    NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (content.length > 0) {
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
    [self changeTextViewFrameWithKeyboardHeight:0 animated:YES];
}

- (void)changeTextViewFrameWithKeyboardHeight:(CGFloat)kbHeight animated:(BOOL)animated
{
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

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    self.textViewPlaceholder.hidden = (self.textView.fullText.length > 0);
    [self checkTextViewCaretOverflow:textView];
}

- (IBAction)createReply:(id)sender {
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    if (self.topic.identifier > 0) {
        NSString *content = [self.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *plainContent = [[content stringByStrippingHtmlTags] trim];
        NSString *errMsg = nil;
        if (plainContent.length < FORUM_MIN_REPLY_LENGTH) {
            errMsg = @"Sorry, the content is too short";
        } else if (plainContent.length > FORUM_MAX_REPLY_LENGTH) {
            errMsg = @"Sorry, the content is too long";
        }
        
        if (errMsg != nil) {
            [[GLDropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
            return;
        }
        
        self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
//        self.textView.editable = NO;
//        self.textView.textColor = [UIColor grayColor];
        self.textView.userInteractionEnabled = NO;
        self.buttonImage.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
        [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        [Forum createReplyToTopic:self.topic.identifier withContent:content andImages:self.textView.usedImages anonymously:NO callback:^(NSDictionary *result, NSError *error) {
            GLLog(@"create reply result: %@, error: %@", result, error);
            
            BOOL failed = NO;
            NSString *message = @"Failed to post the comment";
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
                        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your comment is successfully posted!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                        [self publish:EVENT_FORUM_ADD_REPLY_SUCCESS data:self.topic];
                        [self dismissSelf:nil];
                    } else {
                        failed = YES;
                    }
                }
            }
            
            if (failed) {
                self.navigationItem.rightBarButtonItem = self.postButtonItem;
                //                self.textView.editable = YES;
                //                self.textView.textColor = [UIColor blackColor];
                self.textView.userInteractionEnabled = YES;
                self.buttonImage.enabled = YES;
                self.navigationItem.leftBarButtonItem.enabled = YES;
                [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                [self publish:EVENT_FORUM_ADD_REPLY_FAILURE data:self.topic];
            }
        }];
    }
}

#pragma mark - EmmaTextViewDelegate

- (IBAction)insertImage:(id)sender {
    [self.textView saveCursorPosition];
    [[GLImagePicker sharedInstance] showInController:self withTitle:@"Chose photo to insert" destructiveButtonTitle:nil allowsEditing:NO];
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

@end

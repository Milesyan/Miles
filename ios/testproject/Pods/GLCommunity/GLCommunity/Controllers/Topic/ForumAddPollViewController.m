//
//  ForumAddPollViewController.m
//  emma
//
//  Created by Jirong Wang on 5/12/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLTextView.h>
#import <GLFoundation/GLImagePicker.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/UIView+FindAndResignFirstResponder.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/GLNetworkLoadingView.h>

#import "ForumAddPollViewController.h"
#import "Forum.h"
#import "ForumPollOptions.h"
#import "ForumGroupPickerViewController.h"

#define ADD_POLL_TITLE_CELL_IDENTIFIER    @"PollTitleCell"
#define ADD_POLL_OPTION_CELL_IDENTIFIER   @"PollOptionCell"
#define ADD_POLL_DESC_CELL_IDENTIFIER     @"PollDescCell"

#define OPTION_COUNT_MIN 2
#define OPTION_COUNT_MAX 5

#define TAG_ACTIONSHEET_DISCARD     1001
#define BUTTON_TITLE_CANCEL         @"Cancel"
#define BUTTON_TITLE_DISCARD        @"Discard"

#pragma mark - Class for option table cell
@interface ForumAddPollOptionCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *optionText;
@property (weak, nonatomic) IBOutlet UIButton *addOptionButton;
@property (nonatomic) ForumPollOptionData * model;
@property (nonatomic) BOOL hasAddButton;
@property (nonatomic) BOOL isAddButton;
- (IBAction)addButtonClicked:(id)sender;

@end

@implementation ForumAddPollOptionCell

- (void)setModel:(ForumPollOptionData *)model isLast:(BOOL)isLast {
    _model = model;
    NSString * placeHolder = [NSString stringWithFormat:@"Answer %d%@", _model.displayOptionIndex + 1, (_model.displayOptionIndex>=OPTION_COUNT_MIN) ? @" (optional)" : @""];
    [self.optionText setPlaceholder:placeHolder];
    self.optionText.text = _model.option;
    self.optionText.delegate = self;
    
    if (_model.displayOptionIndex < OPTION_COUNT_MIN) {
        self.hasAddButton = NO;
    } else {
        self.hasAddButton = YES;
        if ((isLast) && (_model.displayOptionIndex != OPTION_COUNT_MAX-1)) {
            self.isAddButton = YES;
            [self.addOptionButton setImage:[UIImage imageNamed:@"gl-community-poll-answer-add"] forState:UIControlStateNormal];
        } else {
            self.isAddButton = NO;
            [self.addOptionButton setImage:[UIImage imageNamed:@"gl-community-poll-answer-delete"] forState:UIControlStateNormal];
        }
    }
    self.addOptionButton.hidden = !self.hasAddButton;
}

- (IBAction)addButtonClicked:(id)sender {
    if (self.isAddButton) {
        [self publish:EVENT_FORUM_POLL_ADD_OPTION];
    } else {
        [self publish:EVENT_FORUM_POLL_REMOVE_OPTION data:@(self.model.displayOptionIndex)];
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    self.model.option = textField.text;
    return YES;
}

@end

#pragma mark - Class for title cell
@interface ForumAddPollTitleCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *titleField;

@end
@implementation ForumAddPollTitleCell

- (void)setup {
    self.titleField.delegate = self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return NO;
}

@end

#pragma mark - Class for description cell
@interface ForumAddPollDescCell : UITableViewCell <GLTextViewDelegate, UIScrollViewDelegate>
{
    BOOL _dragging;
}
@property (weak, nonatomic) IBOutlet GLTextView *textView;
@property (weak, nonatomic) IBOutlet UILabel *textViewPlaceholder;

@end

@implementation ForumAddPollDescCell

- (void)setup {
    self.textView.delegate = self;
    self.textView.webView.scrollView.delegate = self;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (scrollView == self.textView.webView.scrollView)
    {
        _dragging = YES;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == self.textView.webView.scrollView)
    {
        _dragging = NO;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.textView.webView.scrollView)
    {
        if (scrollView.contentOffset.y < -50 && _dragging)
        {
            [self endEditing:YES];
        }
    }
}


#pragma mark - EmmaTextViewDelegate
- (void)GLTextView:(GLTextView *)textView didChangeToHeight:(CGFloat)height withCursorPosition:(CGFloat)cursorPos {
}

- (void)GLTextViewDidBeginEditing:(GLTextView *)textView {
    self.textViewPlaceholder.hidden = YES;
}

- (void)GLTextViewDidChange:(GLTextView *)textView {
}

- (void)GLTextViewDidEndEditing:(GLTextView *)textView {
    [self hidePlaceholderIfNeeded];
}

- (void)GLTextViewDidFinishLoading:(GLTextView *)textView {
}

- (void)hidePlaceholderIfNeeded {
    self.textViewPlaceholder.hidden = ![self.textView isEmpty];
}


@end

#pragma mark - Class for the page view controller
@interface ForumAddPollViewController () <UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, GLImagePickerDelegate, ForumGroupPickerDelegate>

@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *buttonAnonymous;
@property (weak, nonatomic) IBOutlet UIButton *buttonImage;
@property (nonatomic) IBOutlet UITableView * tableView;

@property (nonatomic) ForumAddPollTitleCell * titleCell;
@property (nonatomic) ForumAddPollDescCell * descCell;

@property (nonatomic) NSMutableArray * options;
@property (assign, nonatomic) BOOL notFirstTime;
@property (weak, nonatomic) ForumGroupPickerViewController *groupPicker;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;

- (IBAction)closeSelf:(id)sender;
- (IBAction)toggleAnonymous:(id)sender;
- (IBAction)insertImage:(id)sender;
- (IBAction)postPollClicked:(id)sender;

@end

@implementation ForumAddPollViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"addPoll"];
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
    self.options = [[NSMutableArray alloc] init];
    for (int i=0; i<OPTION_COUNT_MIN+1; i++) {
        [self addNumberOfOptions];
    }

    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateDisabled];
    [self.buttonAnonymous setTitleColor:[self.buttonAnonymous titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    
    [self subscribe:EVENT_FORUM_POLL_ADD_OPTION selector:@selector(forumPollAddOption:)];
    [self subscribe:EVENT_FORUM_POLL_REMOVE_OPTION selector:@selector(forumPollRemoveOption:)];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupModel {
    if (self.topic && [NSString isEmptyString:self.titleCell.titleField.text]) {
        self.buttonAnonymous.selected = self.topic.isAnonymous;
        self.options = [self.topic.pollOptions.options mutableCopy];
        [self addNumberOfOptions];
    }
}

- (void)internalInitializeTitleView {
    if (self.topic) {
        self.navigationItem.title = @"Update Poll";
    } else if (self.group) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 30)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 18)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [GLTheme semiBoldFont:18.0];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = @"Create poll";
        [titleView addSubview:titleLabel];
        UILabel *categoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 18, 172, 12)];
        categoryLabel.textAlignment = NSTextAlignmentCenter;
        categoryLabel.font = [GLTheme lightFont:12.0];
        categoryLabel.textColor = [UIColor blackColor];
        categoryLabel.backgroundColor = [UIColor clearColor];
        categoryLabel.text = catstr(@"In: ", self.group.name, nil);
        [titleView addSubview:categoryLabel];
        [self.navigationItem setTitleView:titleView];
    } else {
        self.navigationItem.titleView = nil;
    }
}

- (void)addNumberOfOptions {
    if (self.options.count >= OPTION_COUNT_MAX) return;
    ForumPollOptionData * data = [[ForumPollOptionData alloc] init];
    data.option = @"";
    data.displayOptionIndex = self.options.count;
    [self.options addObject:data];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [Forum log:PAGE_IMP_FORUM_ADD_POLL eventData:@{@"group_id": @(self.group.identifier)}];
    
    if (self.topic) {
        [self.postButtonItem setTitle:@"Update"];
    } else if (self.group) {
        [self.postButtonItem setTitle:@"Post"];
    } else {
        [self.postButtonItem setTitle:@"Next"];
    }
    
    [self internalInitializeTitleView];
    [self setupModel];

}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

#pragma mark - IBAction
- (IBAction)closeSelf:(id)sender {
    
    [self.view endEditing:YES];
    
    if (self.topic) {
        NSString *title = [self.titleCell.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *content = [self.descCell.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        BOOL titleChanged = ![self.topic.title isEqual:title];
        BOOL contentChanged = ![self.topic.content isEqualToString:content];
        BOOL anonymousChanged = self.topic.isAnonymous != self.buttonAnonymous.selected;
        
        if (titleChanged || contentChanged || anonymousChanged || ![self.topic.pollOptions.options isEqualToArray:self.options]) {
            UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Are you sure you want to discard your edit?"];
            @weakify(self)
            [actionSheet bk_setDestructiveButtonWithTitle:@"Discard" handler:^{
                @strongify(self)
                [self dismissSelf];
            }];
            [actionSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
                GLLog(@"Continue editing...");
            }];
            [actionSheet showInView:self.view];
        } else {
            [self dismissSelf];
        }

    } else {
        NSString *title = [self.titleCell.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (title.length > 0) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Are you sure you want to discard your poll?" delegate:self cancelButtonTitle:BUTTON_TITLE_CANCEL destructiveButtonTitle:BUTTON_TITLE_DISCARD otherButtonTitles:nil];
            actionSheet.tag = TAG_ACTIONSHEET_DISCARD;
            [actionSheet showInView:self.view];
        } else {
            [self dismissSelf];
        }
    }
}

- (void)dismissSelf {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleAnonymous:(id)sender {
    self.buttonAnonymous.selected = !self.buttonAnonymous.selected;
}

- (IBAction)insertImage:(id)sender {
    [self.descCell.textView saveCursorPosition];
    [[GLImagePicker sharedInstance] showInController:self withTitle:@"Choose photo to insert" destructiveButtonTitle:nil allowsEditing:NO];
}

- (void)imagePicker:(GLImagePicker *)imagePicker didPickedImage:(UIImage *)image
{
    if (image.size.width > 640.0) {
        image = [image resizedImage:CGSizeMake(640.0, image.size.height / image.size.width * 640.0) interpolationQuality:kCGInterpolationMedium];
    }
    [self.descCell.textView insertImage:image];
}

- (void)imagePickerDidCancel:(GLImagePicker *)imagePicker
{
    [self.descCell.textView recallCursorPosition];
}

- (void)forumPollAddOption:(Event *)event {
    if (self.options.count >= OPTION_COUNT_MAX) return;
    else {
        [self addNumberOfOptions];
        [self.tableView reloadData];
    }
}
- (void)forumPollRemoveOption:(Event *)event {
    int removedIndex = [(NSNumber *)event.data intValue];
    if ((removedIndex < OPTION_COUNT_MIN) || (self.options.count <= OPTION_COUNT_MIN + 1) || (removedIndex >= self.options.count))
        return;
    // set the reset of option's index forwarded
    for (int i = removedIndex+1; i < self.options.count; i++) {
        ForumPollOptionData * data = [self.options objectAtIndex:i];
        data.displayOptionIndex = i - 1;
    }
    // remove the latest one
    [self.options removeObjectAtIndex:removedIndex];
    [self.tableView reloadData];
}

- (IBAction)postPollClicked:(id)sender {
    [self.tableView findAndResignFirstResponder];
    [self createPoll];
}

#pragma mark - Action sheet delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == TAG_ACTIONSHEET_DISCARD) {
        NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:BUTTON_TITLE_DISCARD]) {
            [self dismissSelf];
        } else if ([buttonTitle isEqualToString:BUTTON_TITLE_CANCEL]) {
            // Cancelled, do nothing
        }
    }
}

#pragma mark - UITableView delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // title and description
    return 2 + self.options.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        // title
        return 44;
    } else if (indexPath.row < self.options.count + 1) {
        // options
        return 44;
    } else {
        // desc
        if (SCREEN_HEIGHT >  480.0) {
            return 200.0;
        } else {
            return 112.0;
        }
    }
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        if (!self.titleCell) {
            self.titleCell = (ForumAddPollTitleCell *)[tableView dequeueReusableCellWithIdentifier:ADD_POLL_TITLE_CELL_IDENTIFIER];
            [self.titleCell setup];
        }
        if (self.topic && self.topic.title) {
            self.titleCell.titleField.text = self.topic.title;
        }
        return self.titleCell;
    } else if (indexPath.row < self.options.count + 1) {
        ForumAddPollOptionCell * cell = (ForumAddPollOptionCell *)[tableView dequeueReusableCellWithIdentifier:ADD_POLL_OPTION_CELL_IDENTIFIER];
        ForumPollOptionData * data = (ForumPollOptionData *)[self.options objectAtIndex:indexPath.row - 1];
        [cell setModel:data isLast:(indexPath.row == self.options.count)];
        return cell;
    } else {
        if (!self.descCell) {
            self.descCell = (ForumAddPollDescCell *)[tableView dequeueReusableCellWithIdentifier:ADD_POLL_DESC_CELL_IDENTIFIER];
            [self.descCell setup];

        }
        return self.descCell;
    }
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.row == 0) && (!self.notFirstTime)) {
        [self.titleCell.titleField becomeFirstResponder];
        self.notFirstTime = YES;
    }
    
    if (cell == self.descCell && self.topic &&[NSString isNotEmptyString:self.topic.content]  && [NSString isEmptyString: [self.descCell.textView fullText]]) {
        [self.descCell.textView insertText:self.topic.content];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        //delay to wait webview loaded
                        [self.tableView reloadData];
                    });

    }
}

#pragma mark - Keyboard
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
    if (animated) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionTransitionNone animations:^{
            self.keyboardHeight.constant = kbHeight;
            [self.view layoutIfNeeded];
            if (kbHeight > 0)
                [self scrollToDescription];
        } completion:nil];
    } else {
        self.keyboardHeight.constant = kbHeight;
        [self.view layoutIfNeeded];
        if (kbHeight > 0)
            [self scrollToDescription];
    }
}

- (void)scrollToDescription {
    if (![self.descCell.textView findFirstResponder]) return;
    NSIndexPath * indexPath = [NSIndexPath indexPathForRow:(self.options.count+1) inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

#pragma mark - Create poll
- (void)createPoll {
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
        [self createPollInGroup:self.group];
    } else {
        self.groupPicker = [ForumGroupPickerViewController viewController];
        self.groupPicker.delegate = self;
        [self.navigationController pushViewController:self.groupPicker animated:YES from:self];
    }
}

- (BOOL)validateForm
{
    NSString *title = [self.titleCell.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.descCell.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *plainContent = [content stringByStrippingHtmlTags];
    NSString *errMsg = nil;
    if (title.length < FORUM_MIN_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too short";
    } else if (title.length > FORUM_MAX_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too long";
    } else if (plainContent.length > FORUM_MAX_CONTENT_LENGTH) {
        errMsg = @"Sorry, the content is too long";
    }
    NSMutableArray * availableOptions = [[NSMutableArray alloc] init];
    for (ForumPollOptionData * data in self.options) {
        if (![NSString isEmptyString:data.option]) {
            NSString * a = [data.option stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (a.length > FORUM_POLL_OPTION_MAX_LENGTH) {
                errMsg = @"Sorry, the answer is too long";
                break;
            }
            if (a.length == 0) {
                continue;
            }
            [availableOptions addObject:a];
        }
    }
    if ((errMsg == nil) && (availableOptions.count < OPTION_COUNT_MIN)) {
        errMsg = @"Sorry, you need at least 2 answers";
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
    
    NSString *title = [self.titleCell.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.descCell.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [GLNetworkLoadingView show];
    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
    [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    NSMutableArray * availableOptions = [[NSMutableArray alloc] init];
    for (ForumPollOptionData * data in self.options) {
        if (![NSString isEmptyString:data.option]) {
            NSString * a = [data.option stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (a.length == 0) {
                continue;
            }
            [availableOptions addObject:a];
        }
    }
    
    self.groupPicker.enabled = NO;
    @weakify(self)
    [Forum updatePoll:self.topic.identifier inGroup:self.topic.groupId
                   withTitle:title options:availableOptions content:content
                   andImages:self.descCell.textView.usedImages
                 anonymously:self.buttonAnonymous.selected
                    callback:^(NSDictionary *result, NSError *error) {
                        @strongify(self)
                        GLLog(@"update topic result: %@, error: %@", result, error);
                        self.groupPicker.enabled = YES;
                        BOOL failed = NO;
                        NSString *message = @"Failed to update the poll";
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
                                    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your poll is successfully updated!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                                    [GLNetworkLoadingView hide];
                                    
                                    [self.view endEditing:YES];
                                    [self dismissViewControllerAnimated:NO completion:^(){
                                        [self publish:EVENT_FORUM_TOPIC_UPDATED data:@(self.topic.identifier)];
                                    }];
                            }
                        }
                        
                        if (failed) {
                            [GLNetworkLoadingView hide];
                            [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                            //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                        }
                    }];
}

- (void)createPollInGroup:(ForumGroup *)group {
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
    
    NSString *title = [self.titleCell.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *content = [self.descCell.textView.fullText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [GLNetworkLoadingView show];
    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
    [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    NSMutableArray * availableOptions = [[NSMutableArray alloc] init];
    for (ForumPollOptionData * data in self.options) {
        if (![NSString isEmptyString:data.option]) {
            NSString * a = [data.option stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (a.length == 0) {
                continue;
            }
            [availableOptions addObject:a];
        }
    }
    
    self.groupPicker.enabled = NO;
    @weakify(self)
    [Forum createPollInGroup:group.identifier
                   withTitle:title options:availableOptions content:content
                   andImages:self.descCell.textView.usedImages
                 anonymously:self.buttonAnonymous.selected
                    callback:^(NSDictionary *result, NSError *error) {
                        @strongify(self)
                        GLLog(@"create topic result: %@, error: %@", result, error);
                        self.groupPicker.enabled = YES;
                        BOOL failed = NO;
                        NSString *message = @"Failed to post the poll";
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
                                    ForumTopic * topic = [[ForumTopic alloc] initWithDictionary:topicResult];
                                    //                        ForumCategory * category = self.category;
                                    
                                    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your poll is successfully posted!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                                    [GLNetworkLoadingView hide];
                                    
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
                            [GLNetworkLoadingView hide];
                            [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                            //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                        }
                    }];
}

- (void)groupPicker:(ForumGroupPickerViewController *)picker didPickGroup:(ForumGroup *)group
{
    if (group) {
        [self createPollInGroup:group];
    }
}

@end

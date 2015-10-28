//
//  ForumAddURLViewController.m
//  Pods
//
//  Created by Eric Xu on 4/22/15.
//
//

#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLTextView.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDropdownMessageController.h>

#import "ForumAddURLViewController.h"
#import "ForumGroupPickerViewController.h"
#import "TFHpple.h"



@interface ForumAddURLViewController () <UITextFieldDelegate, ForumGroupPickerDelegate, GLTextViewDelegate>
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (strong, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet UIButton *buttonAnonymous;
@property (strong, nonatomic) IBOutlet UIButton *buttonImage;

@property (strong, nonatomic) IBOutlet UIButton *pasteButton;

@property (strong, nonatomic) IBOutlet UIView *previewCard;
@property (strong, nonatomic) IBOutlet UIView *thumbContainer;
@property (strong, nonatomic) IBOutlet UIImageView *thumbImage;
@property (strong, nonatomic) IBOutlet UILabel *previewTitle;
@property (strong, nonatomic) IBOutlet UILabel *previewDesc;
@property (strong, nonatomic) IBOutlet UILabel *previewUrl;

@property (strong, nonatomic) IBOutlet UILabel *textViewPlaceholder;
@property (strong, nonatomic) IBOutlet UILabel *titleTextViewPlaceholder;

//@property (strong, nonatomic) IBOutlet UITextField *titleField;
@property (strong, nonatomic) IBOutlet UITextView *titleTextView;

@property (strong, nonatomic) IBOutlet UITextView *textView;


@property (strong, nonatomic) ForumGroupPickerViewController *groupPicker;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewTitleLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewAbstractLeft;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *previewURLLeft;

@property (strong, nonatomic) NSString *previewTitleStr;
@property (strong, nonatomic) NSString *previewDescStr;
@property (strong, nonatomic) NSString *previewThumbURL;

@property (strong, nonatomic) NSString *lastFetchedURL;

- (IBAction)closeSelf:(id)sender;
- (IBAction)toggleAnonymous:(id)sender;
- (IBAction)createURLTopic:(id)sender;

@end

@implementation ForumAddURLViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"addUrl"];
}
- (void)setPreviewTitle:(UILabel *)previewTitle {
    _previewTitle = previewTitle;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.textView.delegate = self;
    self.titleTextView.delegate = self;
 
    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];
    [self.buttonAnonymous setImage:[self.buttonAnonymous imageForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateDisabled];
    [self.buttonAnonymous setTitleColor:[self.buttonAnonymous titleColorForState:UIControlStateHighlighted] forState:UIControlStateSelected | UIControlStateHighlighted];

    self.previewDescStr = @"";
    self.previewTitleStr = @"";
    self.previewThumbURL = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)internalInitializeViews {
    if (self.topic) {
        self.navigationItem.title = @"Update URL";
    } else if (self.group) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 30)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 18)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [GLTheme semiBoldFont:18.0];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = @"Share URL";
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
    
    self.thumbContainer.layer.masksToBounds = YES;
//    self.thumbContainer.layer.cornerRadius = 4;

    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:self.previewCard.bounds];
    self.previewCard.layer.masksToBounds = NO;
    self.previewCard.layer.cornerRadius = 4;
    self.previewCard.layer.borderColor = [UIColorFromRGB(0xDEDEDE) CGColor];
    self.previewCard.layer.borderWidth = 1;
    self.previewCard.layer.shadowColor = [UIColorFromRGB(0xB0B0B0) CGColor];
    self.previewCard.layer.shadowRadius = 2;
    self.previewCard.layer.shadowOpacity = 0.5;
    self.previewCard.layer.shadowOffset = CGSizeMake(0, 2);
    self.previewCard.layer.shadowPath = shadowPath.CGPath;
   
    self.pasteButton.layer.cornerRadius = self.pasteButton.height/2;
    self.pasteButton.layer.borderWidth = 1;
    self.pasteButton.layer.borderColor = [UIColorFromRGB(0xDEDEDE) CGColor];
    
    self.pasteButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.pasteButton.titleLabel.numberOfLines = 2;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [Forum log:PAGE_IMP_FORUM_ADD_URL eventData:@{@"group_id": @(self.group.identifier)}];
    
    [self checkClipboard];
    [self updatePreviewCard];
//    self.previewCard.hidden = YES;
    
    if (self.topic) {
        [self.postButtonItem setTitle:@"Update"];
    } else if (self.group) {
        [self.postButtonItem setTitle:@"Post"];
    } else {
        [self.postButtonItem setTitle:@"Next"];
    }
    
    [self internalInitializeViews];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupModel];
   
    if ([NSString isEmptyString:self.textView.text]) {
        [self.textView becomeFirstResponder];
    } else {
        self.pasteButton.hidden = YES;
    }
}
- (void)setupModel {
    if (self.topic && [NSString isEmptyString:self.textView.text]) {
        self.titleTextView.text = self.topic.title;
        self.textView.text = self.topic.urlPath?: self.topic.content ;
        
        self.previewDescStr = self.topic.urlAbstract;
        self.previewTitleStr = self.topic.urlTitle;
        self.previewThumbURL = self.topic.thumbnail;
        
        self.textViewPlaceholder.hidden = self.textView.text.length > 0;
        self.titleTextViewPlaceholder.hidden = self.titleTextView.text.length > 0;
        
        [self updatePreviewCard];
    }
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
        NSString *title = [self.titleTextView.text trim];
        NSString *content = [self.textView.text trim];
        
        BOOL titleChanged = ![self.topic.title isEqual:title];
        BOOL contentChanged = ![content isEqualToString:self.topic.urlPath];
        
        if (titleChanged || contentChanged) {
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
        [self dismissSelf];
    }
}

- (void)dismissSelf {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)toggleAnonymous:(id)sender {
    self.buttonAnonymous.selected = !self.buttonAnonymous.selected;
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
            self.keyboardHeight.constant = kbHeight + 10;
            [self.view layoutIfNeeded];
        } completion:nil];
    } else {
        self.keyboardHeight.constant = kbHeight + 10;
        [self.view layoutIfNeeded];
    }
}


- (IBAction)createURLTopic:(id)sender {
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
        [self createURLInGroup:self.group];
    } else {
        self.groupPicker = [ForumGroupPickerViewController viewController];
        self.groupPicker.delegate = self;
        [self.navigationController pushViewController:self.groupPicker animated:YES from:self];
    }
 
}

- (BOOL)validateForm {
    NSString *title = [self.titleTextView.text trim];
    NSString *errMsg = nil;

    if ([NSString isEmptyString:title]) {
        errMsg = @"Title is required";
    } else
    if (title.length < FORUM_MIN_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too short";
    } else if (title.length > FORUM_MAX_TITLE_LENGTH) {
        errMsg = @"Sorry, the title is too long";
    }
    if (errMsg != nil) {
        [[GLDropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
        return NO;
    }

    if ([NSString isEmptyString:[self.textView.text trim]]) {
        return NO;
    }
    if ([NSString isEmptyString:self.previewTitleStr]) {
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

    NSString *title = [self.titleTextView.text trim];
    NSString *content = [self.textView.text trim];
    
    BOOL titleChanged = ![self.topic.title isEqual:title];
    BOOL contentChanged = ![self.topic.urlPath isEqualToString:content];
    
    if (titleChanged || contentChanged) {
        [GLNetworkLoadingView show];
        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
        [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        self.titleTextView.userInteractionEnabled = NO;
        [self.titleTextView resignFirstResponder];
        self.textView.userInteractionEnabled = NO;
        [self.textView resignFirstResponder];
        self.navigationItem.leftBarButtonItem.enabled = NO;
        
        @weakify(self)
        [Forum updateURL:self.topic.identifier inGroup:self.topic.groupId withTitle:title url:content urlTitle:self.previewTitleStr urlAbstract:self.previewDescStr thumbnail:self.previewThumbURL callback:^(NSDictionary *result, NSError *error) {
            @strongify(self)
            [GLNetworkLoadingView hide];
            GLLog(@"create topic result: %@, error: %@", result, error);
            self.groupPicker.enabled = YES;
            BOOL failed = NO;
            NSString *message = @"Failed to post the topic";
            NSInteger errCode = [result integerForKey:@"rc"];
            NSString *errMsg = [result stringForKey:@"msg"];
            if (error) {
                failed = YES;
                GLLog(@" %@ %@ ", error.description, error.localizedDescription);
                message = error.localizedDescription;
            } else {
                if (errCode > 0) {
                    failed = YES;
                    if (errMsg) {
                        message = errMsg;
                    }
                } else {
                        failed = NO;
                        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Your topic is successfully posted!",nil) dismissAfter:4.0 styleName:GLStatusBarStyleSuccess];
                        
                        [self.view endEditing:YES];
                    [self dismissViewControllerAnimated:NO completion:^() {
                        [self publish:EVENT_FORUM_TOPIC_UPDATED data:@(self.topic.identifier)];
                    }];
                }
            }
            
            if (failed) {
                self.navigationItem.rightBarButtonItem = self.postButtonItem;
                self.titleTextView.userInteractionEnabled = YES;
                //            self.titleField.textColor = [UIColor blackColor];
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

- (void)createURLInGroup:(ForumGroup *)group {
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
    
    NSString *title = [self.titleTextView.text trim];
    NSString *content = [self.textView.text trim];

    [GLNetworkLoadingView show];
    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
    [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    self.titleTextView.userInteractionEnabled = NO;
    [self.titleTextView resignFirstResponder];
    self.textView.userInteractionEnabled = NO;
    [self.textView resignFirstResponder];
    self.navigationItem.leftBarButtonItem.enabled = NO;

    @weakify(self)
    [Forum createURLInGroup:group.identifier withTitle:title url:content urlTitle:self.previewTitleStr urlAbstract:self.previewDescStr thumbnail:self.previewThumbURL callback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        [GLNetworkLoadingView hide];
        GLLog(@"create topic result: %@, error: %@", result, error);
        self.groupPicker.enabled = YES;
        BOOL failed = NO;
        NSString *message = @"Failed to post the topic";
        NSInteger errCode = [result integerForKey:@"rc"];
        NSString *errMsg = [result stringForKey:@"msg"];
        if (error) {
            failed = YES;
            GLLog(@" %@ %@ ", error.description, error.localizedDescription);
            message = error.localizedDescription;
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
            self.titleTextView.userInteractionEnabled = YES;
//            self.titleField.textColor = [UIColor blackColor];
            self.textView.userInteractionEnabled = YES;
            self.buttonAnonymous.enabled = YES;
            self.buttonImage.enabled = YES;
            self.navigationItem.leftBarButtonItem.enabled = YES;
            [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
            //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
        }

    }];
    
}

- (void)groupPicker:(ForumGroupPickerViewController *)picker didPickGroup:(ForumGroup *)group
{
    if (group) {
        [self createURLInGroup:group];
    }
}


#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView == self.textView) {
    self.textViewPlaceholder.hidden = (self.textView.text.length > 0);
    } else {
        self.titleTextViewPlaceholder.hidden = self.titleTextView.text.length > 0;
    }
//    [self checkTextViewCaretOverflow:textView];
}

- (void)hidePlaceholderIfNeeded
{
    self.textViewPlaceholder.hidden = [self.textView.text length] > 0;
    self.titleTextViewPlaceholder.hidden = [self.titleTextView.text length] > 0;

}


//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    [textField resignFirstResponder];
//    if (!self.textView.text || [self.textView.text isEqual:@""]) {
//        [self.textView becomeFirstResponder];
//    }
//    return NO;
//}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
   
    if([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
   
    if (textView == self.textView) {
        self.previewCard.hidden = YES;
        self.pasteButton.hidden = YES;
        self.lastFetchedURL = nil;
    }
    
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView == self.titleTextView) {
        return;
    }
    if ([NSString isNotEmptyString:textView.text]) {
        [self fetchURLContent];
    } else {
        self.previewTitleStr = @"";
        self.previewDescStr = @"";
        self.previewThumbURL = @"";
        
        [self checkClipboard];
    }
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

- (NSString *)urlForString:(NSString *)str {
    NSString *zurl = [self.textView.text trim];
    
    if (![zurl hasPrefix:@"http://"] && ![zurl hasPrefix:@"https://"]) {
        zurl = [@"http://" stringByAppendingString:zurl];
    }
    return zurl;
}

- (IBAction)tapped:(id)sender
{
    [self.textView resignFirstResponder];
    [self.textView resignFirstResponder];
   
    NSString *zurl = [self urlForString:self.textView.text];
    if (![self.lastFetchedURL isEqual:zurl]) {
        return;
    }
    
    if ([self.previewThumbURL isEqual:@""]) {
        return;
    }

    UIActionSheet *as = [UIActionSheet bk_actionSheetWithTitle:nil];
    [as bk_addButtonWithTitle:@"Remove thumbnail" handler:^{
        self.previewThumbURL = @"";
        [self updatePreviewCard];
    }];
    [as bk_setCancelButtonWithTitle:@"Cancel" handler:^{
        //
    }];
    
    [as showInView:self.view];
}

- (void)fetchURLContent {
    NSString *zurl = [self urlForString:self.textView.text];
   
    if([self.lastFetchedURL isEqual:zurl]) {
        return;
    }
    
    [GLNetworkLoadingView showWithoutAutoClose];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        //Try to fetch with open graph first:
        NSData  * data      = [NSData dataWithContentsOfURL:[NSURL URLWithString:zurl]];
        
        TFHpple * doc       = [[TFHpple alloc] initWithHTMLData:data];
        TFHppleElement *image  = [[doc searchWithXPathQuery:@"//meta[@property='og:image']"] firstObject];
        NSLog(@"ELEMENT: %@", image.attributes[@"content"]);
        NSString *ogImage = image.attributes[@"content"];
        NSString *ogImageUrl = nil;
        if ([NSString isNotEmptyString:ogImage]) {
            NSURL *u = [NSURL URLWithString:zurl];
//            NSLog(@"%@", u.scheme);
//            NSLog(@"%@", u.host);
//            NSLog(@"%@", u.port);
            
            if ([ogImage hasPrefix:@"http"]) {
                ogImageUrl = ogImage;
            } else {
                ogImageUrl = [[NSURL URLWithString:ogImage relativeToURL:u] absoluteString];
            }
        }
        //    NSLog(@"%@", ogImageUrl);
        TFHppleElement *title  = [[doc searchWithXPathQuery:@"//meta[@property='og:title']"] firstObject];
        NSString *ogTitle = title.attributes[@"content"];
        if ([NSString isEmptyString:ogTitle]) {
            ogTitle = nil;
        }
        NSLog(@"ELEMENT: %@", title.attributes[@"content"]);
        TFHppleElement *description  = [[doc searchWithXPathQuery:@"//meta[@property='og:description']"] firstObject];
        NSString *ogDesc = description.attributes[@"content"];
        if ([NSString isEmptyString:ogDesc]) {
            ogDesc = nil;
        }
        NSLog(@"ELEMENT: %@", description.attributes[@"content"]);
        
        if (ogImageUrl && ogTitle && ogDesc) {
            [GLNetworkLoadingView hide];
            self.previewTitleStr = ogTitle;
            self.previewDescStr = ogDesc;
            self.previewThumbURL = ogImageUrl;
            
            [self updatePreviewCard];
            
            [Forum log:FORUM_ADD_URL_LINK_VALIDATED eventData:@{
                                                                @"url": zurl,
                                                                @"valid": @(YES)}];
            
        } else {
            
            @weakify(self)
            [[Forum sharedInstance].delegate fetchURLContent:zurl callback:^(NSDictionary *result, NSError *error) {
                @strongify(self)
                [GLNetworkLoadingView hide];
                NSLog(@"result: %@ error:%@", result, error);
                if (!error) {
                    self.previewTitleStr = ogTitle?:(result[@"title"]?: @"");
                    self.previewDescStr = ogDesc?:(result[@"excerpt"]?: @"");
                    self.previewThumbURL = result[@"lead_image_url"]?: @"";
                    
                    if ([self.previewThumbURL isKindOfClass:[NSNull class]]) {
                        self.previewThumbURL = @"";
                    }
                    
                    self.lastFetchedURL = zurl;
                    
                } else {
                    self.previewTitleStr = @"";
                    self.previewDescStr = @"";
                    self.previewThumbURL = @"";
                }
                
                if ([NSString isEmptyString:self.previewTitleStr]) {
                    [[GLDropdownMessageController sharedInstance] postMessage:@"The given link does not work." duration:3.0 inView:self.view];
                }
                
                [self updatePreviewCard];
                
                [Forum log:FORUM_ADD_URL_LINK_VALIDATED eventData:@{
                                                                    @"url": zurl,
                                                                    @"valid": @(![NSString isEmptyString:self.previewTitleStr])}];
            }];
        }
    });

}

- (void)updatePreviewCard {
    
   
    BOOL shouldHideCard = [NSString isEmptyString:self.previewTitleStr];
    
    self.previewCard.hidden = shouldHideCard;
    
    GLLog(@"#### UPDATING CARD :%@ %@", shouldHideCard?@"HIDE": @"SHOW", self);
    if (shouldHideCard) {
        return;
    }
    
    self.previewTitle.text = self.previewTitleStr;
    self.previewDesc.text = self.previewDescStr;
    self.previewUrl.text = self.textView.text;
    [self setThumbImageVisibility:NO];
    
    if  ([NSString isNotEmptyString:self.previewThumbURL]) {
        @weakify(self)
        [[SDWebImageManager sharedManager] downloadImageWithURL:[NSURL URLWithString:self.previewThumbURL] options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
            @strongify(self)
            if (image) {
                self.thumbImage.image = image;
                [self setThumbImageVisibility:YES];
            }
        }];
    }
    
}

- (void)setThumbImageVisibility:(BOOL)visible {
    self.thumbImage.hidden = !visible;
    
    CGFloat l = visible?(6+56+10): 10;
    self.previewAbstractLeft.constant = l;
    self.previewTitleLeft.constant = l;
    self.previewURLLeft.constant = l;
}

- (void)checkClipboard {
    
    NSString *url = [self getClipboardURL];

    if (url) {
        self.pasteButton.hidden = NO;
        
        NSMutableDictionary* sAttribute = [@{
                                             NSFontAttributeName : [GLTheme semiBoldFont:13.0],
                                             NSForegroundColorAttributeName : [UIColor darkGrayColor],
                                             } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.minimumLineHeight = 14;
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
        
        NSMutableAttributedString *as = [[[NSAttributedString alloc] initWithString:@"Paste link from clipboard:\n"
                                                                         attributes:sAttribute] mutableCopy];
        NSMutableDictionary *lAttribute = [@{
                                             NSFontAttributeName : [GLTheme lightFont:13.0],
                                             NSForegroundColorAttributeName : [UIColor lightGrayColor],
                                             } mutableCopy];
        [lAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
        [as appendAttributedString:[[NSAttributedString alloc] initWithString:url
                                                                   attributes:lAttribute
                                    ]];
        [self.pasteButton setAttributedTitle:as forState:UIControlStateNormal];
        
        [Forum log:FORUM_PASTE_LINK_BUTTON_SHOW_UP eventData: @{@"url": url}];

    } else {
        self.pasteButton.hidden = YES;
    }
}

- (NSString *)getClipboardURL {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];

    if (pasteboard.URL) {
        return pasteboard.URL.absoluteString;
    } else if (pasteboard.strings) {
        for (NSString *s in pasteboard.strings) {
            if (s && ([s hasPrefix:@"http://"] || [s hasPrefix:@"https://"])) {
                return s;
            }
        }
    }
    
    return nil;
}

- (IBAction)pasteButtonClicked:(id)sender {
    NSString *url = [self getClipboardURL];
    self.textView.text = url;
    self.textViewPlaceholder.hidden = YES;
    self.pasteButton.hidden = YES;
    
    [self.titleTextView becomeFirstResponder];
    [self fetchURLContent];
    
    [Forum log:BTN_CLK_FORUM_PASTE_LINK_FROM_CLIPBOARD eventData:@{@"url": url}];
}

@end

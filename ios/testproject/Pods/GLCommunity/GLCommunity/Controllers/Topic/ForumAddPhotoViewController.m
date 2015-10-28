//
//  ForumAddPhotoViewController.m
//  emma
//
//  Created by Allen Hsu on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <BlocksKit/BlocksKit+UIKit.h>
#import <JDStatusBarNotification/JDStatusBarNotification.h>
#import <SDWebImage/SDWebImageManager.h>

#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/GLCameraViewController.h>


#import "ForumAddPhotoViewController.h"
#import "ForumGroupPickerViewController.h"
#import "Forum.h"

@interface ForumAddPhotoViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, ForumGroupPickerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextView *captionTextView;
@property (weak, nonatomic) IBOutlet UILabel *captionPlaceholder;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *postButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *loadingButtonItem;
@property (weak, nonatomic) IBOutlet UISwitch *warningSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *anonymousSwitch;
@property (weak, nonatomic) ForumGroupPickerViewController *groupPicker;

@property (nonatomic, strong) UITapGestureRecognizer *tapRec;

@end

@implementation ForumAddPhotoViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"addPhoto"];
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
    self.imageView.image = self.image;
    
    UIActivityIndicatorView *loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [loadingView startAnimating];
    self.loadingButtonItem = [[UIBarButtonItem alloc] initWithCustomView:loadingView];
    
    self.tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTapped:)];
    [self.imageView addGestureRecognizer:self.tapRec];
    [self.imageView setUserInteractionEnabled:YES];
    
    
}

- (void)internalInitializeTitleView {
    if (self.topic) {
        self.navigationItem.title = @"Update Photo";
    } else if (self.group) {
        UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 172, 30)];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 172, 18)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [GLTheme semiBoldFont:18.0];
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = @"Add photo";
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.captionTextView.userInteractionEnabled) {
        [self.captionTextView becomeFirstResponder];
    }
    
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


- (void)setupModel {
    if (self.topic && [NSString isEmptyString:self.captionTextView.text]) {
        self.captionTextView.text = self.topic.title;
        self.captionPlaceholder.hidden = self.topic.title.length > 0;
        self.anonymousSwitch.on = self.topic.isAnonymous;
        self.warningSwitch.on = self.topic.hasImproperContent;

        UIImage *image = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:self.topic.image];
        if (image) {
            self.imageView.image = image;
        } else {
           NSURL *imageURL = [NSURL URLWithString:self.topic.image];
            @weakify(self)
            [[SDWebImageManager sharedManager] downloadImageWithURL:imageURL options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                if (!error && finished && image) {
                    @strongify(self)
                    self.imageView.image = image;
                }
            }];
        }

    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)closeSelf:(id)sender {
    
    [self.view endEditing:YES];
    
    if (self.topic) {
        NSString *title = [self.captionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        BOOL titleChanged = ![self.topic.title isEqual:title];
        BOOL anonymousChanged = self.topic.isAnonymous != self.anonymousSwitch.on;
        BOOL warningChanged = self.topic.hasImproperContent != self.warningSwitch.on;
        
        if (titleChanged || warningChanged || anonymousChanged || self.image) {
            UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Are you sure you want to discard your edit?"];
            @weakify(self)
            [actionSheet bk_setDestructiveButtonWithTitle:@"Discard" handler:^{
                @strongify(self)
                [self dismissSelf:nil];
            }];
            [actionSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
                GLLog(@"Continue editing...");
            }];
            [actionSheet showInView:self.view];
        } else {
            [self dismissSelf:nil];
        }
 
    } else {
        UIActionSheet *actionSheet = [UIActionSheet bk_actionSheetWithTitle:@"Are you sure you want to discard your topic?"];
        @weakify(self)
        [actionSheet bk_setDestructiveButtonWithTitle:@"Discard" handler:^{
            @strongify(self)
            [self dismissSelf:nil];
        }];
        [actionSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
            GLLog(@"Continue editing...");
        }];
        [actionSheet showInView:self.view];
    }
}

- (IBAction)dismissSelf:(id)sender {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)textViewDidChange:(UITextView *)textView
{
    self.captionPlaceholder.hidden = self.captionTextView.text.length > 0;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return NO;
    }
    NSUInteger newLength = textView.text.length + text.length - range.length;
    NSUInteger maxLength = 0;
    if (textView == self.captionTextView) {
        maxLength = FORUM_MAX_TITLE_LENGTH;
    }
    return (newLength > maxLength) ? NO : YES;
}

- (IBAction)postTopic:(id)sender {
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
        [self createPhotoInGroup:self.group];
    } else {
        self.groupPicker = [ForumGroupPickerViewController viewController];
        self.groupPicker.delegate = self;
        [self.navigationController pushViewController:self.groupPicker animated:YES from:self];
    }
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
    
    NSString *title = [self.captionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    BOOL titleChanged = ![self.topic.title isEqual:title];
    BOOL anonymousChanged = self.topic.isAnonymous != self.anonymousSwitch.on;
    BOOL warningChanged = self.topic.hasImproperContent != self.warningSwitch.on;
    
    if (titleChanged || warningChanged || anonymousChanged || self.image) {
        self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
        self.captionTextView.userInteractionEnabled = NO;
        [self.captionTextView resignFirstResponder];
        self.anonymousSwitch.enabled = NO;
        self.warningSwitch.enabled = NO;
        self.navigationItem.leftBarButtonItem.enabled = NO;
        [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
        [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
        
        @weakify(self)
        NSDictionary *img = @{};
        if (self.image) {
            img = @{@"file": self.image};
        }
        [Forum updatePhoto:self.topic.identifier
                   inGroup:self.topic.groupId
                        withTitle:title images:img anonymously:self.anonymousSwitch.on warning:self.warningSwitch.on callback:^(NSDictionary *result, NSError *error) {
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
                                            [self publish:EVENT_FORUM_TOPIC_UPDATED data:@(self.topic.identifier)];
                                        }];
                                }
                            }
                            
                            if (failed) {
                                self.navigationItem.rightBarButtonItem = self.postButtonItem;
                                self.captionTextView.userInteractionEnabled = YES;
                                self.anonymousSwitch.enabled = YES;
                                self.warningSwitch.enabled = YES;
                                self.navigationItem.leftBarButtonItem.enabled = YES;
                                [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                                //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                            }
                        }];
    }
}

- (BOOL)validateForm
{
    NSString *title = [self.captionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *errMsg = nil;
    if (title.length < FORUM_MIN_TITLE_LENGTH) {
        errMsg = @"Sorry, the caption is too short";
    } else if (title.length > FORUM_MAX_TITLE_LENGTH) {
        errMsg = @"Sorry, the caption is too long";
    }
    
    if (!self.topic && !self.image) {
        errMsg = @"No photo selected";
    }
    
    if (errMsg != nil) {
        [[GLDropdownMessageController sharedInstance] postMessage:errMsg duration:3 position:60 inView:self.view.window];
        return NO;
    }
    return YES;
}

- (void)createPhotoInGroup:(ForumGroup *)group
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
    
    NSString *title = [self.captionTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    self.navigationItem.rightBarButtonItem = self.loadingButtonItem;
    self.captionTextView.userInteractionEnabled = NO;
    [self.captionTextView resignFirstResponder];
    self.anonymousSwitch.enabled = NO;
    self.warningSwitch.enabled = NO;
    self.navigationItem.leftBarButtonItem.enabled = NO;
    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Sending...",nil)];
    [JDStatusBarNotification showActivityIndicator:YES indicatorStyle:UIActivityIndicatorViewStyleWhite];
    
    self.groupPicker.enabled = NO;
    @weakify(self)
    [Forum createPhotoInGroup:group.identifier
                    withTitle:title images:@{@"file": self.image} anonymously:self.anonymousSwitch.on warning:self.warningSwitch.on callback:^(NSDictionary *result, NSError *error) {
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
                            self.captionTextView.userInteractionEnabled = YES;
                            self.anonymousSwitch.enabled = YES;
                            self.warningSwitch.enabled = YES;
                            self.navigationItem.leftBarButtonItem.enabled = YES;
                            [JDStatusBarNotification showWithStatus:message dismissAfter:4.0 styleName:GLStatusBarStyleError];
                            //                [self publish:EVENT_FORUM_ADD_TOPIC_FAILURE data:self.category];
                        }
                    }];
}

- (void)groupPicker:(ForumGroupPickerViewController *)picker didPickGroup:(ForumGroup *)group
{
    if (group) {
        [self createPhotoInGroup:group];
    }
}

#pragma mark - Image Picker related
- (void)imageTapped:(UIGestureRecognizer *)sender
{
    GLLog(@"image tapped");
    GLCameraViewController *camera = [[GLCameraViewController alloc] initWithImagePickerDelegate:self];
    camera.allowsEditing = YES;
    [self presentViewController:camera animated:YES completion:nil];

    
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
//    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = nil;
    if (picker.allowsEditing) {
        image = info[UIImagePickerControllerEditedImage];
    }
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
        image = [image thumbnailImage:640 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationMedium];
    }
    if (image) {
        self.image = image;
        self.imageView.image = self.image;
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];

}


@end

//
//  ForumGroupRoomViewController.m
//  emma
//
//  Created by Jirong Wang on 8/22/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Masonry/Masonry.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLCameraViewController.h>
#import <GLFoundation/GLRotationImageView.h>
#import <GLFoundation/GLWebViewController.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/UIImage+Utils.h>
#import <GLFoundation/UIButton+Ext.h>

#import "ForumGroupRoomViewController.h"
#import "ForumTopicsViewController.h"
#import "ForumAddTopicViewController.h"
#import "ForumAddPollViewController.h"
#import "ForumAddPhotoViewController.h"
#import "ForumAddURLViewController.h"

#define SPIN_IMG_TAG 99

@interface ForumGroupRoomViewController () <UIImagePickerControllerDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *createBarView;
@property (weak, nonatomic) IBOutlet UIView *createTopicButtonView;
@property (weak, nonatomic) IBOutlet UIView *createPollButtonView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *originalRefreshBarButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshImageButton;
@property (nonatomic) IBOutlet UIView * topicsView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *createBarHeight;

@property (assign, nonatomic) UIStatusBarStyle statusBarStyle;

@property (nonatomic) ForumTopicsViewController * topicsViewController;

@property (weak, nonatomic) IBOutlet UIButton *btnPoll;
@property (weak, nonatomic) IBOutlet UIButton *btnPost;
@property (weak, nonatomic) IBOutlet UIButton *btnPhoto;
@property (weak, nonatomic) IBOutlet UIButton *btnURL;

- (IBAction)backButtonClicked:(id)sender;
- (IBAction)refreshButtonClicked:(id)sender;

@end

@implementation ForumGroupRoomViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"groupRoom"];
}

- (BOOL)shouldShowCreateView
{
    switch (self.group.type) {
        case ForumGroupNormal:
            return YES;
            break;
        case ForumGroupHot:
            return YES;
            break;
        case ForumGroupNew:
            return YES;
            break;
        default:
            break;
    }
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupRefreshButton];
    
    id<ForumDelegate> delegate = [Forum sharedInstance].delegate;
    
    [self subscribe:EVENT_FORUM_TOPICS_START_LOAD selector:@selector(topicsStartLoading)];
    [self subscribe:EVENT_FORUM_TOPICS_STOP_LOAD selector:@selector(topicsStopLoading)];

    if ([self.navigationController.viewControllers firstObject] != self)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        self.navigationItem.leftBarButtonItem = self.navigationItem.rightBarButtonItem;
        self.navigationItem.rightBarButtonItem = nil;
    }
    [self createTopicsView];
    
    // create bar
    [self setCreateBar];
    
    self.createBarView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.createBarView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.createBarView.layer.shadowOpacity = 0.25;
    self.createBarView.layer.shadowRadius = 1.0;

}

- (void)createTopicsView {
    self.topicsViewController = [ForumTopicsViewController viewController];
    self.topicsViewController.scrollDelegate = self;
    self.topicsViewController.showGroupInfo = NO;
    self.topicsViewController.category = self.category;
    self.topicsViewController.group = self.group;
//    self.topicsViewController.type = self.group.isBookmark ? self.bookmarkType : ForumCategoryTypeNormal;
    [self.topicsViewController willMoveToParentViewController:self];
    [self addChildViewController:self.topicsViewController];
    [self.topicsViewController didMoveToParentViewController:self];
    [self.topicsView addSubview:self.topicsViewController.tableView];
    [self.topicsViewController.tableView mas_updateConstraints:^(MASConstraintMaker *maker)
    {
        maker.edges.equalTo(self.topicsView);
    }];
    self.navigationItem.title = self.group.name;
}

- (void)setCreateBar {
    if (![self shouldShowCreateView]) {
        self.createBarView.hidden = YES;
        self.createBarHeight.constant = 0.0;
        [self.view setNeedsLayout];
        return;
    } else {
        self.createBarView.hidden = NO;
        self.createBarHeight.constant = 44.0;
        [self.view setNeedsLayout];
    }
    
    [self setButtons];
}

- (void)setButtons {
    if (self.btnPoll && self.btnPost && self.btnPhoto) {
        UIColor *color = self.group.color;
        NSArray *btns = @[self.btnPoll, self.btnPost, self.btnPhoto, self.btnURL];

        for (UIButton *btn in btns) {
            NSInteger idx = [btns indexOfObject:btn];
            UIImage *icon = [btn currentImage];
            icon = [icon imageWithTintColor:color ?: btn.tintColor];
            [btn setImage:icon forState:UIControlStateNormal];
            
            [btn setTitleColor:color ?: btn.tintColor forState:UIControlStateNormal];
            
            [btn centerImageAndTitle:4];
        }
    }
}


- (void)setGroup:(ForumGroup *)group
{
    if (_group != group) {
        _group = group;
        [self setButtons];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.group.type == ForumGroupHot) {
        [Forum log:PAGE_IMP_FORUM_HOT_TOPICS];
    } else if (self.group.type == ForumGroupNew) {
        [Forum log:PAGE_IMP_FORUM_NEW_TOPICS];
    } else if (self.group.isBookmark) {
        [Forum log:PAGE_IMP_FORUM_BOOKMARKED];
    } else if (self.group.type == ForumGroupNormal) {
        [Forum log:PAGE_IMP_FORUM_GROUP_VIEW_TOPICS eventData:@{@"group_id": @(self.group.identifier)}];
    }
    [self subscribeEvents];
}

- (void)subscribeEvents {
    [self subscribe:EVENT_FORUM_CATEGORY_CHANGED selector:@selector(refresh)];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self unsubscribeAll];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarStyle;
}

- (void)setupNavigationBarAppearance {
    [self.topicsViewController setupNavigationBarAppearance];
    self.statusBarStyle = [self.topicsViewController preferredStatusBarStyle];
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - IBAction

- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self refresh];
}

- (IBAction)topicButtonClicked:(id)sender {
    [self createTopicForButton:COMPOSE_BUTTON_TOPIC];
}

- (IBAction)pollButtonClicked:(id)sender {
    [self createTopicForButton:COMPOSE_BUTTON_POLL];
}
- (IBAction)linkButtonClicked:(id)sender {
    [self createTopicForButton:COMPOSE_BUTTON_URL];
}

- (IBAction)photoButtonClicked:(id)sender {
    [self createTopicForButton:COMPOSE_BUTTON_PHOTO];
}

- (void)createTopicForButton:(NSString *)button {
    if ([button isEqualToString:COMPOSE_BUTTON_TOPIC]) {
        [Forum log:BTN_CLK_FORUM_CREATE_TOPIC eventData:@{@"group_id": @(self.group.identifier)}];
        [self presentAddTopicViewController];
    } else if ([button isEqualToString:COMPOSE_BUTTON_POLL]) {
        [Forum log:BTN_CLK_FORUM_CREATE_POLL eventData:@{@"group_id": @(self.group.identifier)}];
        [self presentAddPollViewController];
    } else if ([button isEqualToString:COMPOSE_BUTTON_PHOTO]) {
        [Forum log:BTN_CLK_FORUM_CREATE_PHOTO eventData:@{@"group_id": @(self.group.identifier)}];
        [self presentAddPhotoViewController];
    } else if ([button isEqualToString:COMPOSE_BUTTON_URL]) {
        [Forum log:BTN_CLK_FORUM_CREATE_URL eventData:@{@"group_id": @(self.group.identifier)}];
        [self presentAddUrlViewController];
    }
}

#pragma mark - refresh page
- (void)refresh {
    [self.topicsViewController refreshData:nil];
}

#pragma mark - refresh button
- (void)topicsStartLoading {
    [self._spinImage startSpinWithOneCycleDuration:1];
}

- (void)topicsStopLoading {
    [self._spinImage stopSpin];
}

- (GLRotationImageView *)_spinImage
{
    return (GLRotationImageView*)[self.refreshImageButton viewWithTag:SPIN_IMG_TAG];
}

- (void)setupRefreshButton {
    if (!IOS7_OR_ABOVE) return;
    UIImage * img = [UIImage imageNamed:@"gl-community-reload"];
    GLRotationImageView * imageView = [[GLRotationImageView alloc] initWithImage:img];
    imageView.tag = SPIN_IMG_TAG;
    [self.refreshImageButton addSubview:imageView];
    [self.refreshImageButton setTitle:@"" forState:UIControlStateNormal];
}

#pragma mark - present add topic / create poll
- (void)presentAddTopicViewController {
    ForumAddTopicViewController *addTopicViewController = [ForumAddTopicViewController viewController];
    if (self.group.type == ForumGroupNormal) {
        addTopicViewController.group = self.group;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addTopicViewController];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)presentAddPollViewController {
    ForumAddPollViewController *controller = [ForumAddPollViewController viewController];
    if (self.group.type == ForumGroupNormal) {
        controller.group = self.group;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)presentAddPhotoViewController {
    GLCameraViewController *camera = [[GLCameraViewController alloc] initWithImagePickerDelegate:self];
    camera.allowsEditing = YES;
    [self presentViewController:camera animated:YES completion:nil];
}

- (void)presentAddUrlViewController {
    ForumAddURLViewController *controller = [ForumAddURLViewController viewController];
    if (self.group.type == ForumGroupNormal) {
        controller.group = self.group;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];
    nav.navigationBar.translucent = NO;
    [self presentViewController:nav animated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
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
        ForumAddPhotoViewController *controller = [ForumAddPhotoViewController viewController];
        controller.image = image;
        if (self.group.type == ForumGroupNormal) {
            controller.group = self.group;
        }
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
        navController.navigationBar.translucent = NO;
        @weakify(self)
        [self dismissViewControllerAnimated:YES completion:^{
            @strongify(self)
            [self presentViewController:navController animated:YES completion:nil];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.scrollDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.scrollDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

@end

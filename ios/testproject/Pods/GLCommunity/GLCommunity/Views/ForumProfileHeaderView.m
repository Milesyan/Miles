//
//  ForumProfileHeaderView.m
//  Pods
//
//  Created by Peng Gu on 4/23/15.
//
//

#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLTheme.h>
#import <GLFoundation/GLNameFormatter.h>
#import <GLFoundation/UIImage+Blur.h>
#import <GLFoundation/GLGeneralPicker.h>
#import <GLFoundation/GLPillGradientButton.h>
#import <GLFoundation/GLPillButton.h>

#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import <MWPhotoBrowser/MWPhotoBrowser.h>
#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "GLDropdownMessageController.h"
#import "ForumProfileHeaderView.h"
#import "ForumInviteToGroupViewController.h"
#import "ForumEditProfileViewController.h"
#import "ForumFollowButton.h"
#import "Forum.h"



#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width


@interface ForumProfileHeaderView () <MWPhotoBrowserDelegate>

@property (nonatomic, strong) ForumUser *user;

// top bar
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *backgroundOverlay;
@property (weak, nonatomic) IBOutlet UIView *profileCycleView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteToGroupButton;
@property (weak, nonatomic) IBOutlet GLPillButton *followButton;
@property (weak, nonatomic) IBOutlet UIView *actionButtonContainer;

@property (weak, nonatomic) IBOutlet UIButton *groupsButton;
@property (weak, nonatomic) IBOutlet UIButton *followersButton;
@property (weak, nonatomic) IBOutlet UIButton *followingsButton;
@property (weak, nonatomic) IBOutlet UIView *socialButtonContainer;

// user info view
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *bioLabel;
@property (weak, nonatomic) IBOutlet UIView *locationView;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *badgeButton;
@property (weak, nonatomic) IBOutlet UIImageView *lockImageView;

@property (weak, nonatomic) IBOutlet UIView *segmentsControlContainerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *userInfoViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *locationViewTopConstraint;

@property (strong, nonatomic) UIImage *followButtonBackgroundImage;
@property (assign, nonatomic) BOOL isRequesting;

@end


@implementation ForumProfileHeaderView


#pragma configuration

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.badgeButton.hidden = YES;
    self.lockImageView.hidden = YES;
    self.locationView.hidden = YES;
    self.nameLabel.text = @"                        ";
    self.bioLabel.text = @"                         ";
    self.nameLabel.backgroundColor = [[UIColor alloc] initWithWhite:0.8 alpha:0.8];
    self.bioLabel.backgroundColor = [[UIColor alloc] initWithWhite:0.8 alpha:0.8];
    
    self.profileImageView.layer.masksToBounds = YES;
    self.profileImageView.layer.cornerRadius = self.profileImageView.width / 2;
    self.profileCycleView.layer.masksToBounds = YES;
    self.profileCycleView.layer.cornerRadius = self.profileCycleView.width / 2;
    
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(avatarImageViewTapped)];
    [self.profileImageView addGestureRecognizer:gr];
    [self.profileImageView setUserInteractionEnabled:YES];
    
    for (UIButton *button in @[self.editButton, self.inviteToGroupButton, self.followButton]) {
        button.backgroundColor = [UIColor whiteColor];
        button.layer.masksToBounds = NO;
        button.layer.cornerRadius = button.height / 2;
        button.layer.borderWidth = 0.5;
        button.layer.borderColor = [UIColorFromRGB(0xD5D6D7) CGColor];
        button.layer.shadowColor = [[UIColor blackColor] CGColor];
        button.layer.shadowRadius = .5;
        button.layer.shadowOpacity = 0.15;
        button.layer.shadowOffset = CGSizeMake(0, .5);
    }
    
    for (UIButton *button in @[self.groupsButton, self.followersButton, self.followingsButton]) {
        [[button titleLabel] setNumberOfLines:2];
        [[button titleLabel] setLineBreakMode:NSLineBreakByWordWrapping];
    }
    
    CGFloat padding = 0;
    self.segmentsControl = [[HMSegmentedControl alloc] initWithSectionTitles:@[@"Popular", @"All"]];
    self.segmentsControl.frame = CGRectMake(padding, 0, SCREEN_WIDTH - padding * 2, kProfileSegmentsControlHeight);
    self.segmentsControl.selectionStyle = HMSegmentedControlSelectionStyleFullWidthStripe;
    self.segmentsControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown;
    self.segmentsControl.selectionIndicatorColor = GLOW_COLOR_PURPLE;
    [self.segmentsControl setTitleFormatter:^NSAttributedString *(HMSegmentedControl *segmentedControl, NSString *title, NSUInteger index, BOOL selected) {
        NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
        attrs[NSForegroundColorAttributeName] = selected ? GLOW_COLOR_PURPLE : [UIColor lightGrayColor];
        attrs[NSFontAttributeName] = selected ? [GLTheme semiBoldFont:16] : [GLTheme defaultFont:16];
        return [[NSAttributedString alloc] initWithString:title attributes:attrs];
    }];
    
    self.segmentsControlContainerView.backgroundColor = [UIColor clearColor];
    [self.segmentsControlContainerView addSubview:self.segmentsControl];
}


#pragma mark - update data

- (void)configureWithUser:(ForumUser *)user
{
    self.user = user;
    
    [self reload];
    
    @weakify(self)
    [self subscribe:EVENT_PROFILE_IMAGE_UPDATE handler:^(Event *event) {
        @strongify(self)
        self.profileImageView.image = self.user.cachedProfileImage;
    }];
    
    [self subscribe:EVENT_BACKGROUND_IMAGE_CHANGED handler:^(Event *event) {
        @strongify(self)
        [self updateBackgroundImage:self.user.cachedBackgroundImage];
    }];
    
    [self subscribe:kFollowingCountChangedNotification obj:self.user handler:^(Event *event) {
        @strongify(self)
        [self loadSocialInfo];
    }];
    
    [self subscribe:kJoinedGroupsCountChangedNotification obj:self.user handler:^(Event *event) {
        @strongify(self)
        [self loadSocialInfo];
    }];
}


- (void)reload
{
    [self loadSegmentsControl];
    [self loadImages];
    [self loadUserInfo];
    [self loadSocialInfo];
    [self configureActionButtons];
}


- (void)loadSegmentsControl
{
    if (self.user.isMyself) {
        [self.segmentsControl setSectionTitles:@[@"Participated", @"Created", @"Bookmarked"]];
    }
    else {
        [self.segmentsControl setSectionTitles:@[@"Popular", @"All"]];
    }
}


- (void)configureActionButtons
{
    if ([self.user isMyself]) {
        self.editButton.hidden = NO;
        self.inviteToGroupButton.hidden = YES;
        self.followButton.hidden = YES;
        return;
    }
    
    self.editButton.hidden = YES;
    self.followButton.hidden = NO;
    BOOL hide = self.user.buttonText.length > 0 && self.user.buttonUrl.length > 0;
    self.inviteToGroupButton.hidden = hide;
    
    [self configureFollowButton];
}


- (void)configureFollowButton
{
    if ([[Forum currentForumUser] isFollowingUser:self.user.identifier]) {
        [self.followButton setSelected:YES];
    }
    else {
        [self.followButton setSelected:NO];
    }
}


- (void)loadUserInfo
{
    // User info
    if (self.user.badge.length > 0) {
        self.badgeButton.hidden = NO;
        NSString *badge = [NSString stringWithFormat:@"    %@     ", self.user.badge];
        [self.badgeButton setTitle:badge forState:UIControlStateNormal];
        
        UIImage *img = [self.badgeButton backgroundImageForState:UIControlStateNormal];
        UIEdgeInsets edge = UIEdgeInsetsMake(img.size.height / 2, img.size.width / 2, img.size.height / 2, img.size.width / 2);
        img = [img resizableImageWithCapInsets:edge];
        
        [self.badgeButton setBackgroundImage:img forState:UIControlStateNormal];
    }
    else {
        self.badgeButton.hidden = YES;
    }
    
    self.lockImageView.hidden = !self.user.hidePosts;
    
    // lables
    self.nameLabel.backgroundColor = [UIColor clearColor];
    self.nameLabel.text = self.user.firstName;
    
    CGFloat height = self.nameLabel.bottom;
    
    self.bioLabel.hidden = (self.user.bio.length == 0);
    if (!self.bioLabel.hidden) {
        self.bioLabel.backgroundColor = [UIColor clearColor];
        self.bioLabel.width = SCREEN_WIDTH - 38;
        self.bioLabel.text = self.user.bio;
        [self.bioLabel sizeToFit];
        [self layoutIfNeeded];
        height = self.bioLabel.bottom;
    }
    
    self.locationView.hidden = (self.user.location.length == 0);
    if (!self.locationView.hidden) {
        if (self.bioLabel.hidden) {
            self.locationViewTopConstraint.constant = - self.locationView.height;
        }
        else {
            self.locationViewTopConstraint.constant = 8;
        }
        
        [self.locationButton setTitle:self.user.location forState:UIControlStateNormal];
        height += 4 + self.locationView.height; // 4 is for top padding
    }
    
    height += 10;   // bottom padding
    self.height = height + kProfileSegmentsControlHeight + kProfileBackgroundImageHeight;
    
    self.userInfoViewHeightConstraint.constant = height;
    [self layoutIfNeeded];
}


- (void)loadSocialInfo
{
    static NSDictionary *attrs1, *attrs2;
    if (!attrs1 || !attrs2) {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setAlignment:NSTextAlignmentCenter];
        [style setLineBreakMode:NSLineBreakByWordWrapping];
        
        UIFont *font1 = [GLTheme semiBoldFont:15];
        UIFont *font2 = [GLTheme defaultFont:10];
        attrs1 = @{NSFontAttributeName:font1, NSParagraphStyleAttributeName:style};
        attrs2 = @{NSFontAttributeName:font2, NSParagraphStyleAttributeName:style};
    }
    
    NSString *followersString = self.user.followersCount == 1 ? @"FOLLOWER" : @"FOLLOWERS";
    NSAttributedString *followers = [[NSAttributedString alloc] initWithString:followersString attributes:attrs2];
    NSAttributedString *groups = [[NSAttributedString alloc] initWithString:@"GROUPS" attributes:attrs2];
    NSAttributedString *followings = [[NSAttributedString alloc] initWithString:@"FOLLOWING" attributes:attrs2];
    
    NSAttributedString * (^makeText)(NSUInteger, NSAttributedString *) = ^NSAttributedString * (NSUInteger number, NSAttributedString *typeText)
    {
        
        NSString *plainText = [NSString stringWithFormat:@"%ld\n", (long)number];
        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:plainText attributes:attrs1];
        [attrText appendAttributedString:typeText];

        return attrText;
    };
    
    [self.groupsButton setAttributedTitle:makeText(self.user.groupsCount, groups) forState:UIControlStateNormal];
    [self.followersButton setAttributedTitle:makeText(self.user.followersCount, followers) forState:UIControlStateNormal];
    [self.followingsButton setAttributedTitle:makeText(self.user.followingsCount, followings) forState:UIControlStateNormal];
}


- (void)loadImages
{
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    UIImage *defaultBackgroundImage = [Forum defaultBackgroundImage];
    
    // profile image
    if (self.user.cachedProfileImage) {
        self.profileImageView.image = self.user.cachedProfileImage;
    }
    else if (self.user.profileImage.length > 0) {
        @weakify(self)
        [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.user.profileImage]
                                 placeholderImage:defaultProfileImage
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
         {
             @strongify(self)
             if (image) {
                 self.user.cachedProfileImage = image;
                 self.profileImageView.image = image;
             }
             else {
                 self.profileImageView.image = defaultProfileImage;
             }
         }];
    }
    else {
        self.profileImageView.image = defaultProfileImage;
    }
    
    if (self.user.cachedBackgroundImage) {
        [self updateBackgroundImage:self.user.cachedBackgroundImage];
    }
    else if (self.user.backgroundImage.length > 0) {
        NSURL *url = [NSURL URLWithString:self.user.backgroundImage];
        UIImage *backgroundImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[url absoluteString]];
        if (backgroundImage) {
            [self updateBackgroundImage:backgroundImage];
        }
        else {
            @weakify(self)
            [[SDWebImageManager sharedManager] downloadImageWithURL:url options:0 progress:nil completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                @strongify(self)
                if (image) {
                    self.user.cachedBackgroundImage = image;
                    [self updateBackgroundImage:image];
                }
                else {
                    [self updateBackgroundImage:defaultBackgroundImage];
                }
            }];
        }
    }
    else {
        [self updateBackgroundImage:defaultBackgroundImage];
    }
}


- (void)updateBackgroundImage:(UIImage *)backgroundImage
{
    UIImage *blurredImage = [backgroundImage applyBlurWithRadius:3.0 tintColor:nil saturationDeltaFactor:1.0 maskImage:nil];
    self.backgroundImageView.image = blurredImage;
}


#pragma mark - scrolling
- (void)updateLayoutWithScrollingOffset:(CGFloat)offset
{
    CATransform3D backgroundTransform = CATransform3DIdentity;
    CGFloat alpha = 1;
    CGFloat backgroundAlpha = 0.15;

    if (offset < 0) {
        CGFloat scaleFactor = -(offset) / kProfileBackgroundImageHeight;
        
        backgroundTransform = CATransform3DTranslate(backgroundTransform, 0, offset/2, 0);
        backgroundTransform = CATransform3DScale(backgroundTransform, 1.0 + scaleFactor, 1.0 + scaleFactor, 0);
    }
    else {
        alpha = 1 - offset / (kProfileBackgroundImageHeight - kNavigationBarHeight);
        
        CGFloat backgroundOffset = offset - (kProfileBackgroundImageHeight - kNavigationBarHeight);
        if (backgroundOffset > 0) {
            backgroundTransform = CATransform3DTranslate(backgroundTransform, 0, backgroundOffset, 0);
        }
        
        if (offset > kProfileUsenameTransitionPoint) {
            backgroundAlpha = (offset - kProfileUsenameTransitionPoint) / 30;
            backgroundAlpha = fmin(0.6, fmax(0.15, backgroundAlpha));
        }
    }
    
    self.backgroundImageView.layer.transform = backgroundTransform;
    self.backgroundOverlay.layer.transform = backgroundTransform;
    self.backgroundOverlay.alpha = backgroundAlpha;
    
    self.profileCycleView.alpha = alpha;
    self.profileImageView.alpha = alpha;
    self.actionButtonContainer.alpha = alpha;
    self.socialButtonContainer.alpha = alpha;
}


#pragma mark - avatar image
- (void)avatarImageViewTapped
{
    MWPhotoBrowser *imageBrowser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    imageBrowser.displayActionButton = NO;
    imageBrowser.zoomPhotosToFill = YES;
    
    if ([self.delegate respondsToSelector:@selector(forumProfileHeaderView:needToPresentImageBrowser:)]) {
        [self.delegate forumProfileHeaderView:self needToPresentImageBrowser:imageBrowser];
    }
}


- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser
{
    return 1;
}


- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index
{
    return [MWPhoto photoWithImage:self.profileImageView.image];
}


#pragma mark - user actions
- (IBAction)inviteToGroupButtonClicked:(id)sender
{
    if (!self.user) {
        return;
    }
    
    [Forum log:BTN_CLK_FORUM_PROFILE_INVITE_TO_GROUP];
    
    NSArray *groups = [Forum sharedInstance].subscribedGroups;
    NSMutableArray *groupNames = [@[] mutableCopy];
    for (ForumGroup *group in groups) {
        [groupNames addObject:group.name];
    }
    
    @weakify(self)
    [GLGeneralPicker presentCancelableSimplePickerWithTitle:@"Choose a group"
                                                       rows:groupNames
                                                selectedRow:0
                                                  doneTitle:@"Invite"
                                                 showCancel:YES
                                              withAnimation:YES
                                             doneCompletion:^(NSInteger row, NSInteger comp)
    {
        if (row < groups.count) {
            @strongify(self)
            ForumGroup *group = groups[row];
            [ForumInviteToGroupViewController presentForUser:self.user
                                                     group:group];
        }
        [sender setSelected:NO];
        
    } cancelCompletion:^(NSInteger row, NSInteger comp) {
        [sender setSelected:NO];
    }];
}


- (IBAction)followButtonClicked:(id)sender
{
    if (self.isRequesting || !self.user) {
        return;
    }
    
    self.isRequesting = YES;
    
    ForumUser *currentUser = [Forum currentForumUser];
    
    @weakify(self)
    if (![currentUser isFollowingUser:self.user.identifier]) {
        [Forum log:FORUM_FOLLOW_USER eventData:@{@"tgt_user_id": @(self.user.identifier)}];
        [currentUser followUser:self.user completion:^(BOOL success, NSError *error) {
            @strongify(self)
            if (success) {
                [self loadSocialInfo];
                [self configureFollowButton];
                
                NSString *message = [NSString stringWithFormat:@"You're now following %@'s activities!", self.user.firstName];
                [[GLDropdownMessageController sharedInstance] postMessage:message
                                                                 duration:3
                                                                 position:64
                                                                   inView:[GLUtils keyWindow]];
            }
            else {
                [self.followButton setSelected:NO];
            }
            
            self.isRequesting = NO;
        }];
    }
    else {
        UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:nil];
        
        [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
            self.isRequesting = NO;
        }];
        
        [sheet bk_addButtonWithTitle:@"Unfollow" handler:^{
            @strongify(self)
            [Forum log:FORUM_UNFOLLOW_USER eventData:@{@"tgt_user_id": @(self.user.identifier)}];
 
            [currentUser unfollowUser:self.user completion:^(BOOL success, NSError *error) {
                if (success) {
                    @strongify(self)
                    
                    [self loadSocialInfo];
                    [self configureFollowButton];
                }
                
                self.isRequesting = NO;
            }];
        }];

        [sheet showInView:self];
    }
    
}


@end





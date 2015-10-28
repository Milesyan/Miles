//
//  MeHeaderView.m
//  emma
//
//  Created by Peng Gu on 10/9/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MeHeaderView.h"
#import "User.h"
#import "ImagePicker.h"
#import "InvitePartnerDialog.h"
#import "SDImageCache.h"
#import "SDWebImageManager.h"
#import "UIImage+blur.h"
#import "UIImage+Resize.h"
#import <GLCommunity/ForumEvents.h>

#define kMotionDiffHorizontal   20.0
#define kMotionDiffVertical     15.0

@interface MeHeaderView ()

@property (strong, nonatomic) IBOutlet UIImageView *rightProfileImage;
@property (strong, nonatomic) IBOutlet UIImageView *leftProfileImage;
@property (strong, nonatomic) IBOutlet UIImageView *leftOverlay;
@property (strong, nonatomic) IBOutlet UIImageView *rightOverlay;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIView *bgView;
@property (weak, nonatomic) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *bioButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *backgroundViewConstraintBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftImageViewConstraintCenterX;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bgViewConstraintBottom;

@end

@implementation MeHeaderView

+ (NSMutableDictionary *)bioAttribute
{
    static NSMutableDictionary *sAttribute = nil;
    if (!sAttribute) {
        sAttribute = [@{
                        NSFontAttributeName : [Utils defaultFont:16.0],
                        NSForegroundColorAttributeName : [UIColor whiteColor],
                        } mutableCopy];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 1;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [sAttribute setObject: paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    return sAttribute;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.model = [User currentUser];
    UIImage *profileImageMask = [UIImage imageNamed:@"profile-underlay-black"];
    
    CALayer *leftMask = [CALayer layer];
    leftMask.frame = self.leftProfileImage.bounds;
    leftMask.contents = (id)profileImageMask.CGImage;
    self.leftProfileImage.layer.mask = leftMask;
    
    CALayer *rightMask = [CALayer layer];
    rightMask.frame = self.rightProfileImage.bounds;
    rightMask.contents = (id)profileImageMask.CGImage;
    self.rightProfileImage.layer.mask = rightMask;
    
    [self subscribe:EVENT_PARTNER_INVITED selector:@selector(onPartnerInvited:)];
    [self subscribe:EVENT_PARTNER_REMOVED selector:@selector(onPartnerRemoved:)];
    [self subscribe:EVENT_PROFILE_IMAGE_UPDATE selector:@selector(onProfileImageUpdated:)];
    [self subscribe:EVENT_BACKGROUND_IMAGE_CHANGED selector:@selector(backgroundImageChanged:)];
    [self subscribe:EVENT_PURPOSE_CHANGED selector:@selector(backgroundImageChanged:)];
    
    self.width = SCREEN_WIDTH;
    self.backgroundMask.width = SCREEN_WIDTH;
    
    self.bgView.clipsToBounds = YES;
    
    self.bioButton.titleLabel.preferredMaxLayoutWidth = SCREEN_WIDTH - 2 * 55;
    self.bioButton.titleLabel.numberOfLines = 0;
    self.bioButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    UITapGestureRecognizer *tapOnHeader = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnHeader:)];
    [self addGestureRecognizer:tapOnHeader];
    
//    [self loadBackgroundImage];
    [self backgroundImageChanged:nil];
}

#pragma mark - ProfileCell
- (void)updateProfileCell {
    self.leftOverlay.image = [self genderOverlay:self.model];
    
    [self.model loadProfileImage:^(UIImage *profileImage, NSError *err) {
        if (profileImage) {
            self.leftProfileImage.image = profileImage;
        }
    }];
    
    User *partner = self.model.partner;
    if (partner) {
        [self.model.partner loadProfileImage:^(UIImage *profileImage, NSError *err) {
            self.rightOverlay.image = [self genderOverlay:self.model.partner];
            if (profileImage) {
                self.rightProfileImage.image = profileImage;
            } else {
                if (partner.status != USER_STATUS_TEMP) {
                    self.rightProfileImage.image = [UIImage imageNamed:@"profile-empty"];
                } else {
                    self.rightOverlay.image = [UIImage imageNamed:@"profile-overlay-clear"];
                }
            }
        }];
        self.rightProfileImage.userInteractionEnabled = YES;
    }
    else {
        self.rightOverlay.image = [UIImage imageNamed:@"profile-overlay-clear"];
        self.rightProfileImage.image = [UIImage imageNamed:@"profile-addpartner"];
        self.rightProfileImage.userInteractionEnabled = YES;
    }
    
    Settings *settings = self.model.settings;
    
    if ((settings.currentStatus == AppPurposesAvoidPregnant || settings.currentStatus == AppPurposesNormalTrack) &&
        !partner) {
        self.leftImageViewConstraintCenterX.constant = 0;
        self.rightProfileImage.hidden = YES;
        self.rightOverlay.hidden = YES;
    }
    else {
        self.leftImageViewConstraintCenterX.constant = 37;
        self.rightProfileImage.hidden = NO;
        self.rightOverlay.hidden = NO;
    }
    
    
    NSString *bio = settings.bio.length > 0 ? settings.bio : @"Add a short bio";
    [self.bioButton setTitle:bio forState:UIControlStateNormal];
//    [self.bioButton sizeToFit];
    
    [self updateLocationText];
    
    self.height = self.bioButton.titleLabel.intrinsicContentSize.height + 152;
//    if (self.superview && [self.superview respondsToSelector:@selector(setTableHeaderView:)]) {
//        // tell tableview to update the height of its header view
//        [(UITableView *)self.superview setTableHeaderView:self];
//    }
}

- (void)layoutSubviews
{
    // fix a weird layout bug which happens when select pregnant in current status page
    self.height = self.bioButton.titleLabel.intrinsicContentSize.height + 152;
    [super layoutSubviews];
}

- (IBAction)updateProfileImage:(id)sender {
    self.leftProfileImage.alpha = 0.5;
    [UIView animateWithDuration:0.2
                     animations:^{
                         self.leftProfileImage.alpha = 1;
                     }
                     completion:^(BOOL finished) {
                         if (self.viewController.view.window) {
                             self.tagWaitingImage = kTagProfileImage;
                             [[ImagePicker sharedInstance] showInController:self.viewController withTitle:@"Change profile photo"];
                         }
                     }];
}

- (IBAction)invitePartnerPressed:(id)sender {
    if (self.model.partner && self.model.partner.status == USER_STATUS_NORMAL) {
        return;
    }
    
    // log
    [Logging log:BTN_CLK_NAV_INV_PTN];
    
    self.rightProfileImage.alpha = 0.5;
    [UIView animateWithDuration:0.2 animations:^{
        self.rightProfileImage.alpha = 1;
    } completion:^(BOOL finished) {
        [InvitePartnerDialog openDialog];
    }];
}

- (void)onPartnerInvited:(Event *)evt {
    [self updateProfileCell];
}

- (void)onPartnerRemoved:(Event *)evt {
    [self updateProfileCell];
}

- (void)onProfileImageUpdated:(Event *)evt {
    [self updateProfileCell];
}

- (UIImage *)genderOverlay:(User *)user {
    if ([user.gender isEqual:MALE]) {
        return [UIImage imageNamed:@"profile-overlay-blue"];
    } else {
        return [UIImage imageNamed:@"profile-overlay-pink"];
    }
}

- (void)loadBackgroundImage
{
    if (self.model.settings.backgroundImageUrl.length > 0) {
        NSURL *url = [NSURL URLWithString:self.model.settings.backgroundImageUrl];
        UIImage *backgroundImage = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:[url absoluteString]];
        if (backgroundImage) {
            [self setBackgroundImage:backgroundImage];
        } else {
            __weak MeHeaderView *weakSelf = self;
            
            [[SDWebImageManager sharedManager] downloadImageWithURL:url
                                                            options:0
                                                           progress:nil
                                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL)
             {
                 if (!image)
                 {
                     GLLog(@"Failed to download background image");
                     [weakSelf setBackgroundImage:weakSelf.model.settings.backgroundImage];
                 }
                 else
                 {
                     [Utils performInMainQueueAfter:0 callback:^{
                         [weakSelf setBackgroundImage:image];
                     }];
                     
                 }
                 
             }];
        }
    } else {
        [self setBackgroundImage:self.model.settings.backgroundImage];
    }
}

- (void)setBackgroundImage:(UIImage *)image
{
    if (image.size.height >= 480 || image.size.width >= 360) {
        image = [image resizeToBackgroundImage];
    }
    UIImage *blurredImage = [image applyBlurWithRadius:1.0 tintColor:nil saturationDeltaFactor:1.0 maskImage:nil];
    self.backgroundView.image = blurredImage;
//    self.backgroundView.image = image;
}

- (void)updateBackgroundFrameWithOffset:(CGFloat)y
{
    if (y > 0) {
        self.bgViewConstraintBottom.constant = y;
        [self setClipsToBounds:YES];
    }
    else {
        self.bgViewConstraintBottom.constant = 0;
        [self setClipsToBounds:NO];
    }
}


- (void)tapOnHeader:(UITapGestureRecognizer *)gesture
{
    [self updateCoverPhoto];
}


- (void)updateCoverPhoto
{
    self.tagWaitingImage = kTagBackgroundImage;
    [[ImagePicker sharedInstance] showInController:self.viewController
                                         withTitle:@"Change background image"
                            destructiveButtonTitle:@"Restore default"
                                     allowsEditing:NO];
}


- (void)backgroundImageChanged:(Event *)event;
{
    [self setBackgroundImage:self.model.settings.backgroundImage];
}


#pragma mark - motion
- (void)addMotionEffect
{
    [self removeMotionEffect];
    
    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-kMotionDiffHorizontal);
    horizontalMotionEffect.maximumRelativeValue = @(kMotionDiffHorizontal);
    [self.backgroundView addMotionEffect:horizontalMotionEffect];
    
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-kMotionDiffVertical);
    verticalMotionEffect.maximumRelativeValue = @(kMotionDiffVertical);
    [self.backgroundView addMotionEffect:verticalMotionEffect];
}

- (void)removeMotionEffect
{
    for (UIMotionEffect *effect in self.backgroundView.motionEffects) {
        [self.backgroundView removeMotionEffect:effect];
    }
}

#pragma mark - update location text
- (void)updateLocationText {
    User * user = [User currentUser];
    Settings * settings = user.settings;
    BOOL hasLocation = settings.location.length > 0;
    
    NSString *loc = hasLocation ? settings.location : @"Add your location";
    [self.locationButton setTitle:loc forState:UIControlStateNormal];
    
    if ((!hasLocation) && (user.currentLocation != nil))  {
        // update location from currentLocation
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        //NSLog(@"AAAAAA jr debug, current Location = %@", user.currentLocation);
        
        @weakify(self);
        [geoCoder reverseGeocodeLocation:user.currentLocation
                       completionHandler:^(NSArray *placemarks, NSError *error) {
                           //NSLog(@"BBBBBBB jr debug, reverse geo: %@, %@", error, placemarks);
                           @strongify(self);
                           if (error || !placemarks) {
                               return;
                           }
                           CLPlacemark *placemark = placemarks.firstObject;
                           NSString *loc_2 = [NSString stringWithFormat:@"%@, %@", placemark.locality, placemark.country];
                           [self.locationButton setTitle:loc_2 forState:UIControlStateNormal];
                           user.currentLocationCity = loc_2;                           
                       }
         ];
    }
}

@end

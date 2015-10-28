//
//  ForumUserListCell.m
//  Pods
//
//  Created by Peng Gu on 5/28/15.
//
//


#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLTheme.h>
#import <GLFoundation/GLNameFormatter.h>
#import <GLFoundation/GLPillButton.h>
#import <BlocksKit/UIActionSheet+BlocksKit.h>
#import "GLDropdownMessageController.h"

#import <SDWebImage/SDImageCache.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ForumUserListCell.h"
#import "ForumUser.h"
#import "Forum.h"


@interface ForumUserListCell ()

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet GLPillButton *button;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *buttonWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *nameLabelBottomConstraint;

@property (nonatomic, strong) ForumUser *user;

@end


@implementation ForumUserListCell


- (void)awakeFromNib
{
    self.avatarImageView.clipsToBounds = YES;
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.height / 2;
    
    [self.button setTitle:@"Follow" forState:UIControlStateNormal];
    [self.button setTitle:@"Following" forState:UIControlStateHighlighted];
    [self.button setTitle:@"Following" forState:UIControlStateSelected];
    
    if (IOS8_OR_ABOVE) {
        self.layoutMargins = UIEdgeInsetsZero;
        self.preservesSuperviewLayoutMargins = NO;
    }
    
    self.selectionStyle = UITableViewCellSelectionStyleGray;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)configureWithUser:(ForumUser *)user
{
    self.user = user;
    
    [self loadAvatar:user];
    
//    self.nameLabel.text = [GLNameFormatter stringFromFirstName:user.firstName lastName:user.lastName];
    self.nameLabel.text = user.firstName;
    self.detailLabel.text = user.bio;
    
    ForumUser *currentUser = [Forum currentForumUser];
    if (currentUser.identifier == user.identifier) {
        self.button.hidden = YES;
        self.buttonWidthConstraint.constant = 5;
        return;
    }
    
    if (!user.bio || [NSString isEmptyString:user.bio]) {
        self.nameLabelBottomConstraint.constant = -9;
    }
    else {
        self.nameLabelBottomConstraint.constant = 8;
    }
    
    self.buttonWidthConstraint.constant = 95;
    self.button.hidden = NO;
    BOOL isFollowing = [currentUser isFollowingUser:user.identifier];
    [self.button setSelected:isFollowing];
}


- (void)loadAvatar:(ForumUser *)user
{
    UIImage *defaultProfileImage = [UIImage imageNamed:@"gl-community-profile-empty"];
    
    // profile image
    if (user.cachedProfileImage) {
        self.avatarImageView.image = user.cachedProfileImage;
    }
    else if (user.profileImage.length > 0) {
        @weakify(self)
        [self.avatarImageView sd_setImageWithURL:[NSURL URLWithString:user.profileImage]
                                 placeholderImage:defaultProfileImage
                                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL)
         {
             @strongify(self)
             if (image) {
                 self.avatarImageView.image = image;
                 user.cachedProfileImage = image;
             }
             else {
                 self.avatarImageView.image = defaultProfileImage;
             }
         }];
    }
    else {
        self.avatarImageView.image = defaultProfileImage;
    }
}


- (IBAction)followButtonClicked:(id)sender
{
    ForumUser *currentUser = [Forum currentForumUser];
    
    @weakify(self)
    if (![currentUser isFollowingUser:self.user.identifier]) {
        [Forum log:FORUM_FOLLOW_USER eventData:@{@"tgt_user_id": @(self.user.identifier)}];

        [currentUser followUser:self.user completion:^(BOOL success, NSError *error) {
            if (success) {
                NSString *message = [NSString stringWithFormat:@"You're now following %@'s activities!", self.user.firstName];
                [[GLDropdownMessageController sharedInstance] postMessage:message
                                                                 duration:3
                                                                 position:64
                                                                   inView:[GLUtils keyWindow]];
            }
            else {
                [self.button setSelected:NO animated:YES];
            }
        }];
    }
    else {
        UIActionSheet *sheet = [UIActionSheet bk_actionSheetWithTitle:nil];
        
        [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
           [self.button setSelected:YES animated:YES];
        }];
        
        [sheet bk_addButtonWithTitle:@"Unfollow" handler:^{
            @strongify(self)
            [Forum log:FORUM_UNFOLLOW_USER eventData:@{@"tgt_user_id": @(self.user.identifier)}];
 
            [currentUser unfollowUser:self.user completion:^(BOOL success, NSError *error) {
                @strongify(self)
                if (success) {
                    [self.button setSelected:NO animated:YES];
                }
                else {
                    [self.button setSelected:YES animated:YES];
                }
            }];
        }];
        
        [sheet showInView:self];
    }
}

@end





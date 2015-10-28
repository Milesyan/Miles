//
//  ForumProfileHeaderView.h
//  Pods
//
//  Created by Peng Gu on 4/23/15.
//
//

#import "HMSegmentedControl.h"

#define kProfileBackgroundImageHeight 110
#define kProfileSegmentsControlHeight 44
#define kNavigationBarHeight 64
#define kProfileUsenameTransitionPoint 92

@class ForumUser;
@class ForumProfileHeaderView;
@class MWPhotoBrowser;

@protocol ForumProfileHeaderViewDelegate <NSObject>

- (void)forumProfileHeaderView:(ForumProfileHeaderView *)cell needToPresentImageBrowser:(MWPhotoBrowser *)imageBrowser;

@end


@interface ForumProfileHeaderView : UIView

@property (strong, nonatomic) HMSegmentedControl *segmentsControl;
@property (weak, nonatomic) id<ForumProfileHeaderViewDelegate> delegate;

- (void)configureWithUser:(ForumUser *)user;
- (void)updateLayoutWithScrollingOffset:(CGFloat)offset;

@end

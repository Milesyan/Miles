//
//  ForumPromotionCell.h
//  Pods
//
//  Created by Eric Xu on 7/17/15.
//
//

#import <UIKit/UIKit.h>
#import "ForumTopicCell.h"
#import "ForumPromotionFeed.h"

@class ForumPromotionCell;


@protocol ForumPromotionCellDelegate <NSObject>

@optional
- (void)cellDidDismissed:(ForumPromotionCell *)cell;
- (void)cellGotClicked:(ForumPromotionCell *)cell;

@end



@interface ForumPromotionCell : UITableViewCell

@property (weak, nonatomic) id<ForumPromotionCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet ForumGroupButton *promotionButton;
@property (weak, nonatomic) IBOutlet UIWebView *contentWebView;
@property (weak, nonatomic) IBOutlet UIButton  *invisibleButton;

@property (strong, nonatomic) ForumPromotionFeed *feed;

- (IBAction)promotionButtonClicked:(id)sender;
- (IBAction)invisibleButtonClicked:(id)sender;

@end

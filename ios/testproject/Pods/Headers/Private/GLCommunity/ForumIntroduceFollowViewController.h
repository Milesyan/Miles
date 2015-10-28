//
//  ForumIntroduceFollowViewController.h
//  Pods
//
//  Created by Peng Gu on 6/2/15.
//
//

#import <UIKit/UIKit.h>
#import <GLFoundation/GLPillGradientButton.h>

typedef void(^CheckoutButtonAction)();

@interface ForumIntroduceFollowViewController : UIViewController

@property (nonatomic, weak) IBOutlet GLPillGradientButton *checkoutButton;
@property (nonatomic, copy) CheckoutButtonAction checkoutAction;

+ (BOOL)presentIfTheFirstTimeWithCheckoutAction:(CheckoutButtonAction)action;

@end

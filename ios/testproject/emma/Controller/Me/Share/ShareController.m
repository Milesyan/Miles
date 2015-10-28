//
//  ShareViewController.m
//  emma
//
//  Created by Peng Gu on 7/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ShareController.h"
#import "NetworkLoadingView.h"
#import "Share.h"
#import "User.h"
#import "NetworkLoadingView.h"

@interface ShareItem : NSObject <UIActivityItemSource>
@property (nonatomic, strong) NSDictionary* data;
@end
@implementation ShareItem
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}

- (NSString *)activityViewController:(UIActivityViewController *)activityViewController subjectForActivityType:(NSString *)activityType
{
    if (self.data[@"subject"]) {
        return self.data[@"subject"];
    } else {
        return nil;
    }
}

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if ([activityType isEqualToString:UIActivityTypeMail]) {
        return self.data[@"full_body"];
    } else if ([activityType isEqualToString:UIActivityTypeMessage]) {
        return self.data[@"sms_body"];
    } else if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
        return self.data[@"twitter_body"];
    } else {
        return self.data[@"body"];
    }
}
@end


@interface ShareController ()
@end
@implementation ShareController


+ (void)presentWithShareType:(ShareType)shareType
                                    shareItem:(id)item
                           fromViewController:(UIViewController *)presentingViewController
{
    return [ShareController presentWithShareType:shareType
                                           shareItem:item
                                  fromViewController:presentingViewController
                                          completion:NULL];
}


+ (void)presentWithShareType:(ShareType)shareType
                                    shareItem:(id)item
                           fromViewController:(UIViewController *)presentingViewController
                                   completion:(void (^)(BOOL))completion
{
    [NetworkLoadingView showWithDelay:20];
    [Share shareItem:item shareType:shareType completion:^(BOOL success, NSDictionary *data, NSError *error) {
        [NetworkLoadingView hide];
        if (success) {
            NSDictionary *eventData = @{@"share_type": [Share descriptionForShareType:shareType],
                                        @"item_id": [Share itemIDForItem:item shareType:shareType]};
            [Logging log:BTN_CLK_SHOW_SYSTEM_SHARE_SHEET eventData:eventData];
            [self presentShareSheetWithShareType:shareType shareItem:item data:data inViewController:presentingViewController completion:completion];
        }
    }];
}

+ (void)presentShareSheetWithShareType:(ShareType)shareType shareItem:(id)item data:(NSDictionary *)data inViewController:(UIViewController *)viewController completion:(void (^)(BOOL))completion
{
    ShareItem *shareItem = [ShareItem new];
    shareItem.data = data;
    UIImage *image = [Share imageForItem:item shareType:shareType];
    
    NSArray *items = image ? @[image, shareItem] : @[shareItem];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        NSDictionary *eventData = @{@"share_type": [Share descriptionForShareType:shareType],
                                    @"share_channel": activityType ? activityType : @"",
                                    @"item_id": [Share itemIDForItem:item shareType:shareType],
                                    @"success": completed ? @"YES" : @"NO"};

        [Logging log:BTN_CLK_SYSTEM_SHARE_SHEET_RESULT eventData:eventData];
        if (completed) {
            if (shareType == ShareTypeInsightShare || shareType == ShareTypeInsightShareThreeLikes) {
                Insight *insight = (Insight *)item;
                [[User currentUser] sharedInsight:insight];
            }
        }
        if (completion) {
            completion(completed);
        }
    }];
    [viewController presentViewController:activityViewController animated:YES completion:nil];
}

@end




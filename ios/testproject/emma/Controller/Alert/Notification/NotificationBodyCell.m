//
//  NotificationBodyCell.m
//  emma
//
//  Created by Ryan Ye on 3/5/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "NotificationBodyCell.h"
#import "PillGradientButton.h"
#import "GeniusMainViewController.h"
#import "GeniusChildViewController.h"
#import "Logging.h"
#import "Sendmail.h"
#import "Utils.h"
#import "Reminder.h"
#import "ForumTopicDetailViewController.h"
#import "ForumTopicsViewController.h"
#import "UIStoryboard+Emma.h"
#import "FulfillmentGoodsViewController.h"
#import "ForumCommentViewController.h"
#import "User.h"
#import "PushablePresenteeNavigationController.h"
#import "ForumMyGroupsViewController.h"
#import "Reminder.h"
#import "ForumProfileViewController.h"
#import "ForumSocialUsersViewController.h"

#define NOTIF_TEXT_WIDTH (SCREEN_WIDTH - 40.0f)

@interface NotificationBodyCell () {
    IBOutlet UIView *titleContainerView;
    IBOutlet UILabel *titleLabel;
    IBOutlet UIView *unreadMarker;
    IBOutlet UILabel *notifTextLabel;
    IBOutlet UILabel *timeAgoLabel;
    IBOutlet UILabel *middleDotLabel;
    IBOutlet UILabel *hideLabel;
    IBOutlet UIView *alarmInfoView;
    IBOutlet UILabel *alarmTimeLabel;
    IBOutlet UIView *bottomContainer;
    IBOutlet PillGradientButton *changeAlarmBtn;
    IBOutlet PillGradientButton *actionButton;
    IBOutlet UIView *dividerLine;
    UITapGestureRecognizer *tapGesture;
}

- (IBAction)clickChangeButton:(id)sender;
- (IBAction)clickActionButton:(id)sender;
- (void)updateView;
@end

@implementation NotificationBodyCell

- (void)awakeFromNib
{
    [actionButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    [changeAlarmBtn setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideNotification)];
    [hideLabel addGestureRecognizer:tapGesture];
    unreadMarker.layer.cornerRadius = unreadMarker.frame.size.height / 2;
}

- (void)setModel:(Notification *)notif {
    _model = notif;
    [self updateView];
}

- (void)transitionToFullView:(Event *)evt {
    [UIView animateWithDuration:0.3 animations:^{
        titleContainerView.frame = setRectX(titleContainerView.frame, 20);
        dividerLine.frame = CGRectMake(20, dividerLine.frame.origin.y,
            GG_FULL_CONTENT_W, 1);
        notifTextLabel.alpha = 1;
    }];
}

- (void)transitionToThumbView:(Event *)evt {
    [UIView animateWithDuration:0.3 animations:^{
        titleContainerView.frame = setRectX(titleContainerView.frame, 10);
        dividerLine.frame = CGRectMake(10, dividerLine.frame.origin.y,
            GENIUS_DOUBLE_BLOCK_TITLE_WIDTH, 1);
        notifTextLabel.alpha = 0;
    }];
}

- (void)didMoveToSuperview {
    if (self.superview && self.controller) {
        [self subscribe:TRANSITION_TO_FULL_VIEW obj:self.controller selector:@selector(transitionToFullView:)];
        [self subscribe:TRANSITION_TO_THUMB_VIEW obj:self.controller selector:@selector(transitionToThumbView:)];
    } else {
        [self unsubscribe:TRANSITION_TO_FULL_VIEW];
        [self unsubscribe:TRANSITION_TO_THUMB_VIEW];
    }
}

- (void)hideDividerLine {
    dividerLine.hidden = YES;
}

- (void)showDividerLine {
    dividerLine.hidden = NO;
}

- (void)updateView
{
    titleContainerView.width = NOTIF_TEXT_WIDTH;
    dividerLine.width = NOTIF_TEXT_WIDTH;
    unreadMarker.hidden = !self.model.unread;
    
    if (self.model.unread) {
        titleLabel.left = 15;
        titleLabel.width = titleContainerView.width - 15;
    }
    else {
        titleLabel.left = 0;
        titleLabel.width = titleContainerView.width;
    }
    
    titleLabel.text = self.model.title;
    [titleLabel sizeToFit];
    
    notifTextLabel.attributedText = [[self class] getAttributedText:self.model.text];
    notifTextLabel.frame = CGRectMake(notifTextLabel.left, titleLabel.height+20, NOTIF_TEXT_WIDTH, notifTextLabel.height);
    [notifTextLabel sizeToFit];
    CGFloat offsetY = notifTextLabel.bottom + 10;
    alarmInfoView.hidden = YES;
    alarmInfoView.frame = setRectY(alarmInfoView.frame, offsetY);
    
    CGRect actionButtonFrame = actionButton.frame;
    actionButtonFrame.origin.y = offsetY;
    actionButtonFrame.size.width = 100.0;
    actionButton.hidden = YES;
    [actionButton setImage:nil forState:UIControlStateNormal];
    
    if (self.model.button == EMMA_NOTIF_BUTTON_SET_ALARM) {
        [self updateAlarm];
        offsetY += (self.model.action == EMMA_USER_ACTION_ALARM_SET) ? 80 : 40;
//        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_SEND_SMS) {
        [actionButton setTitle:@"Send SMS" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CONTACT_US) {
        [actionButton setTitle:@"Contact us" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_IT_OUT) {
        [actionButton setTitle:@"Check it out" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_THEM_OUT) {
        [actionButton setTitle:@"Check them out" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 150.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_BUY_TESTKIT) {
        [actionButton setTitle:@"Yes, buy now!" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 150.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_RESPOND_NOW) {
        [actionButton setTitle:@"Respond now" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 120.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_COMMENT) {
        [actionButton setTitle:@"Check it out" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 120.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_REMINDER) {
        [actionButton setTitle:@"Update reminders" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 150.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_PROMO) {
        [actionButton setTitle:@"Check it out now!" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 150.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_FORUM_TAKE_A_LOOK) {
        [actionButton setTitle:@"Take a look" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_GLOW_FIRST) {
        [actionButton setTitle:@"Apply" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_DOWNLOAD) {
        [actionButton setTitle:@"Download" forState:UIControlStateNormal];
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_OUT_GROUP) {
        [actionButton setTitle:@"Check out the group!" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 160.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_OUT_PERIOD) {
        [actionButton setTitle:@"Go to period log" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 150.0;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_BIRTH_CONTROL_REFILL) {
        NSDictionary * actionContext = self.model.actionContext;
        NSString * source = [actionContext objectForKey:@"source"];
        if ([source isEqualToString:@"walgreens"]) {
            [actionButton setTitle:@"Refill to Walgreens" forState:UIControlStateNormal];
            [actionButton setImage:[UIImage imageNamed:@"walgreens-icon"] forState:UIControlStateNormal];
            [actionButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 3, 10)];
            actionButtonFrame.size.width = 185.0;
        } else {
            [actionButton setTitle:@"Refill by scan" forState:UIControlStateNormal];
            actionButtonFrame.size.width = 120.0;
        }
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_DAILY_LOG) {
        [actionButton setTitle:@"Take me to my log" forState:UIControlStateNormal];
        actionButtonFrame.size.width = 160;
        offsetY += 40;
        actionButton.hidden = NO;
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_FORUM_PROFILE) {
        NSNumber *userId = [self.model.actionContext objectForKey:@"user_id"];
        if (userId.unsignedLongLongValue == [Forum currentForumUser].identifier) {
            [actionButton setTitle:@"Take a look" forState:UIControlStateNormal];
        }
        else {
            [actionButton setTitle:@"Follow back" forState:UIControlStateNormal];
        }
        actionButtonFrame.size.width = 120;
        offsetY += 40;
        actionButton.hidden = NO;
    }
    
    actionButton.frame = actionButtonFrame;
    
    bottomContainer.frame = setRectY(bottomContainer.frame, offsetY);
    timeAgoLabel.text = [Utils agoStringForDate:self.model.timeCreated];
    [timeAgoLabel sizeToFit];
    if (self.model.type != EMMA_NOTIF_TYPE_WELCOME) {
        middleDotLabel.hidden = NO;
        hideLabel.hidden = NO;
        middleDotLabel.frame = setRectX(middleDotLabel.frame, timeAgoLabel.frame.size.width + timeAgoLabel.frame.origin.x + 4);
        middleDotLabel.frame = setRectY(middleDotLabel.frame, timeAgoLabel.frame.origin.y - 2);
        hideLabel.frame = setRectX(hideLabel.frame, middleDotLabel.frame.size.width + middleDotLabel.frame.origin.x + 6);
        hideLabel.frame = setRectY(hideLabel.frame, timeAgoLabel.frame.origin.y - 2);
    } else {
        middleDotLabel.hidden = YES;
        hideLabel.hidden = YES;
    }
}

- (void)updateAlarm{
    Reminder * reminderBBT = [Reminder getReminderByType:REMINDER_TYPE_SYS_BBT];
    if (reminderBBT.on) {
        // show reminder already set text
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"h:mm a";
        alarmTimeLabel.text = [NSString stringWithFormat:@"%@, everyday", [dateFormatter stringFromDate:[reminderBBT nextWhen]]];
        alarmInfoView.hidden = NO;
        actionButton.hidden = YES;
        self.model.action = EMMA_USER_ACTION_ALARM_SET;
    } else {
        // show a button
        [actionButton setTitle:@"Set alarm" forState:UIControlStateNormal];
        self.model.action = 0;
        alarmInfoView.hidden = YES;
        actionButton.hidden = NO;
    }
}

- (IBAction)clickActionButton:(id)sender {
    // loggings
    NSDictionary * buttonModelToType = @{
        @(EMMA_NOTIF_BUTTON_SET_ALARM):            NOTIFICATION_BUTTON_SET_ALARM,
        @(EMMA_NOTIF_BUTTON_SEND_SMS):             NOTIFICATION_BUTTON_SEND_SMS,
        @(EMMA_NOTIF_BUTTON_CONTACT_US):           NOTIFICATION_BUTTON_CONTACT_US,
        @(EMMA_NOTIF_BUTTON_CHECK_IT_OUT):         NOTIFICATION_BUTTON_GO_TOPIC,
        @(EMMA_NOTIF_BUTTON_CHECK_THEM_OUT):       NOTIFICATION_BUTTON_GO_TOPIC_LIST,
        @(EMMA_NOTIF_BUTTON_BUY_TESTKIT):          NOTIFICATION_BUTTON_BUY_TESTKIT,
        @(EMMA_NOTIF_BUTTON_RESPOND_NOW):          NOTIFICATION_BUTTON_GO_TOPIC_COMMENT,
        @(EMMA_NOTIF_BUTTON_CHECK_COMMENT):        NOTIFICATION_BUTTON_GO_TOPIC_COMMENT,
        @(EMMA_NOTIF_BUTTON_GO_REMINDER):          NOTIFICATION_BUTTON_GO_REMINDER,
        @(EMMA_NOTIF_BUTTON_GO_PROMO):             NOTIFICATION_BUTTON_GO_PROMO,
        @(EMMA_NOTIF_BUTTON_FORUM_TAKE_A_LOOK):    NOTIFICATION_BUTTON_GO_TOPIC,
        @(EMMA_NOTIF_BUTTON_GO_GLOW_FIRST):        NOTIFICATION_BUTTON_GO_GLOW_FIRST,
        @(EMMA_NOTIF_BUTTON_CHECK_OUT_GROUP):      NOTIFICATION_BUTTON_GO_FORUM_GROUP,
        @(EMMA_NOTIF_BUTTON_CHECK_OUT_PERIOD):     NOTIFICATION_BUTTON_GO_PERIOD,
        @(EMMA_NOTIF_BUTTON_BIRTH_CONTROL_REFILL): NOTIFICATION_BUTTON_REFILL_BY_SCAN,
        @(EMMA_NOTIF_BUTTON_DOWNLOAD):             NOTIFICATION_BUTTON_DOWNLOAD_URL,
        @(EMMA_NOTIF_BUTTON_GO_DAILY_LOG):         NOTIFICATION_BUTTON_GO_DAILY_LOG,
        @(EMMA_NOTIF_BUTTON_GO_FORUM_PROFILE):     NOTIFICATION_BUTTON_GO_FORUM_PROFILE
    };
    NSString * buttonType = [buttonModelToType objectForKey:@(self.model.button)];
    if (buttonType) {
        NSNumber * additionalData = nil;
        // Try to get topic_id
        NSDictionary *context = self.model.actionContext;
        if ([context isKindOfClass:[NSDictionary class]]) {
            NSNumber *topicId = [context objectForKey:@"topic_id"];
            if (topicId) {
                additionalData = topicId;
            }
        }
        if (!additionalData) {
            additionalData = @(0);
        }
        
        [Logging log:BTN_CLK_NOTIFICATION_BUTTON eventData:@{
            @"button_type":     buttonType,
            @"ntf_type":        @(self.model.type),
            @"additional_info": additionalData
        }];
    }
    
    if (self.model.button == EMMA_NOTIF_BUTTON_SET_ALARM) {
        [self goSetBBTReminder];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_SEND_SMS) {
        [self sendSMS];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CONTACT_US) {
        [self contactUs];
    } else if ((self.model.button == EMMA_NOTIF_BUTTON_CHECK_IT_OUT) || (self.model.button == EMMA_NOTIF_BUTTON_FORUM_TAKE_A_LOOK)){
        [self goTopic];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_THEM_OUT) {
        [self goCreatedTopicList];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_BUY_TESTKIT) {
        [self goToBuyTestkit];
    } else if ((self.model.button == EMMA_NOTIF_BUTTON_RESPOND_NOW) || (self.model.button == EMMA_NOTIF_BUTTON_CHECK_COMMENT)){
        [self goComments];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_REMINDER) {
        [self goReminder];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_PROMO) {
        [self goPromo];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_GLOW_FIRST) {
        [self goGlowFirst];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_OUT_GROUP) {
        [self gotoGroup];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_CHECK_OUT_PERIOD) {
        [self gotoPeriod];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_BIRTH_CONTROL_REFILL) {
        [self refillByScan];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_DOWNLOAD) {
        NSURL *url = [NSURL URLWithString:self.model.actionContext[@"url"]];
        [[UIApplication sharedApplication] openURL:url];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_DAILY_LOG) {
        [self publish:EVENT_NOTIF_GO_DAILY_LOG];
    } else if (self.model.button == EMMA_NOTIF_BUTTON_GO_FORUM_PROFILE) {
        [self goForumProfile];
    }
}

- (IBAction)clickChangeButton:(id)sender {
    [self goSetBBTReminder];
}

- (void)goSetBBTReminder {
    [self publish:EVENT_GO_SET_BBT_REMINDER];
}

- (void)contactUs {
    [[Sendmail sharedInstance] composeTo:@[FEEDBACK_RECEIVER] subject:@"Contribution stopped" body:@"" inViewController:self.controller];
}

- (void)sendSMS {
	MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
    messageController.messageComposeDelegate = self;
	if([MFMessageComposeViewController canSendText]) {
		[self.controller presentViewController:messageController animated:YES completion:nil];
	}
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [self.controller dismissViewControllerAnimated:YES completion:nil];
    
    int sendResult = 0;
    if (result == MessageComposeResultSent) {
        sendResult = 1;
    } else if (result == MessageComposeResultCancelled) {
        sendResult = 2;
    } else {
        sendResult = 3;
    }
    [Logging log:USER_NOTIFY_SMS_SENT eventData:@{@"send_result": @(sendResult)}];
}

#pragma mark - Action buttons responders
- (void)goForumProfile
{
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSNumber *userId = [context objectForKey:@"user_id"];
        NSDictionary *userInfo = [context objectForKey:@"user"];
        ForumUser *user = [[ForumUser alloc] initWithDictionary:userInfo];
        
        id vc = nil;
        if (user.isMyself) {
            vc = [[ForumSocialUsersViewController alloc] initWithUser:[Forum currentForumUser]
                                                       socialRelation:SocialRelationTypeFollowers];
            [vc setShowCloseButton:YES];
        }
        else {
            vc = [[ForumProfileViewController alloc] initWithUserID:[userId longLongValue]
                                                    placeholderUser:user];
        }
        
        UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.controller presentViewController:navigationViewController animated:YES completion:nil];
    }
}

- (void)goTopic
{
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSNumber *topicId = [context objectForKey:@"topic_id"];
        NSNumber *categoryId = [context objectForKey:@"category_id"];
        NSNumber *replyId = [context objectForKey:@"reply_id"];
        
        if ([topicId isKindOfClass:[NSNumber class]]) {
            ForumTopic *topic = [[ForumTopic alloc] init];
            topic.identifier = [topicId unsignedLongLongValue];
            if ([categoryId isKindOfClass:[NSNumber class]]) {
                topic.categoryId = [categoryId unsignedIntValue];
            }
            ForumTopicDetailViewController *topicViewController = [ForumTopicDetailViewController viewController];
            topicViewController.topic = topic;
            topicViewController.replyId = replyId.unsignedIntegerValue;
            topicViewController.source = IOS_TOPIC_VIEW_FROM_NOTIFICATION;
            EmmaNavigationController *topicNavController = [[EmmaNavigationController alloc] initWithRootViewController:topicViewController];
            [self.controller presentViewController:topicNavController animated:YES completion:nil];
        }
    }
}

- (void)gotoGroup
{
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSNumber *gid = context[@"group"];
        if ([gid unsignedLongLongValue] > 0) {
            ForumGroup *group = [[ForumGroup alloc] initWithDictionary:@{@"id": gid, @"name": @"Group", @"category_id":@0}];
            ForumTopicsViewController *vc = [ForumTopicsViewController pushableControllerBy:group];
            GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
            nav.navigationBar.translucent = NO;
            [self.controller presentViewController:nav animated:YES completion:^{
                [vc setupNavigationBarAppearance];
                [self.controller setNeedsStatusBarAppearanceUpdate];
            }];
        }
    }
}

- (void)goCreatedTopicList
{
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSString *whereToGo = [context objectForKey:@"goto"];
        if ([whereToGo isEqualToString:@"created"]) {
            ForumGroup *group = [ForumGroup createdGroup];
            ForumTopicsViewController *vc = [ForumTopicsViewController pushableControllerBy:group];
            GLNavigationController *nav = [[GLNavigationController alloc] initWithRootViewController:vc];
            nav.navigationBar.translucent = NO;
            [self.controller presentViewController:nav animated:YES completion:^{
                [vc setupNavigationBarAppearance];
                [self.controller setNeedsStatusBarAppearanceUpdate];
            }];
        }
    }
}

- (void)goComments
{
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        NSNumber *topicId = [context objectForKey:@"topic_id"];
        NSNumber *replyId = [context objectForKey:@"reply_id"];
        if ([topicId isKindOfClass:[NSNumber class]]) {
            ForumTopic *topic = [[ForumTopic alloc] init];
            topic.identifier = [topicId unsignedLongLongValue];
//            ForumTopicDetailViewController *topicViewController = (ForumTopicDetailViewController *)[UIStoryboard topicDetail];
//            topicViewController.topic = topic;
            
            ForumReply *reply = [[ForumReply alloc] init];
            reply.identifier = [replyId unsignedLongLongValue];
            if ([topicId isKindOfClass:[NSNumber class]]) {
                reply.topicId = [topicId unsignedLongLongValue];
            }
            
            ForumCommentViewController *commentViewController = [ForumCommentViewController viewController];
            commentViewController.reply = reply;
            commentViewController.topic = topic;
            
            EmmaNavigationController *topicNavController = [[EmmaNavigationController alloc] initWithRootViewController:commentViewController];
            [self.controller presentViewController:topicNavController animated:YES completion:nil];
        }
    }
}

- (void)goToBuyTestkit {
    NSDictionary *context = self.model.actionContext;
    if ([context isKindOfClass:[NSDictionary class]]) {
        FulfillmentGoodsViewController *viewController =
                (FulfillmentGoodsViewController *)
                [UIStoryboard buyTestkitGoodsInfo];
        viewController.goodsId = [context[@"goods_type"] integerValue];
        UINavigationController *navController = [[UINavigationController alloc]
                initWithRootViewController:viewController];
        [self.controller presentViewController:navController animated:YES
                completion:nil];
    }
}

- (void)goReminder {
    [self publish:EVENT_NOTIF_GO_REMINDER];
}

- (void)goPromo {
    [self publish:EVENT_NOTIF_GO_PROMO];
}

- (void)goGlowFirst {
    [self publish:EVENT_NOTIF_GO_GLOW_FIRST];
}

- (void)gotoPeriod {
    [self publish:EVENT_NOTIF_GO_PERIOD];
}

- (void)refillByScan {
    NSDictionary *context = self.model.actionContext;
    [self publish:EVENT_NOTIF_REFILL_BY_SCAN data:context];
}

#pragma mark - Gesture recognizer responders
- (void)hideNotification {
    [Logging log:BTN_CLK_GNS_NTF_HIDE eventData:@{@"notif_type": @(self.model.type)}];
    [self.model publish:EVENT_NOTIFICATION_HIDDEN];
}

#pragma mark - helper
- (NSString *)textWithoutFormat:(NSString *)text {
    return [text stringByReplacingOccurrencesOfString:@"**" withString:@""];
}

+ (NSAttributedString *)getAttributedText:(NSString*)text {
    return [Utils markdownToAttributedText:text fontSize:15.0 lineHeight:19.0 color:[UIColor blackColor]];
}

+ (CGFloat)textHeight:(Notification *)notif
{
    static NSMutableDictionary *textHeightCache = nil;
    if (!textHeightCache) {
        textHeightCache = [[NSMutableDictionary alloc] init];
    }
    NSNumber *height = [textHeightCache objectForKey:notif.text];
    if (!height) {
        CGFloat titleLabelWidth = notif.unread ? NOTIF_TEXT_WIDTH - 15 : NOTIF_TEXT_WIDTH;
        NSDictionary *attrs = @{NSFontAttributeName: [Utils boldFont:18]};
        NSAttributedString *attrTitle = [[NSAttributedString alloc] initWithString:notif.title
                                                                        attributes:attrs];
        CGFloat textHeight = [UILabel sizeForText:attrTitle
                                          inBound:CGSizeMake(titleLabelWidth, 10000.0)].height;
        
        textHeight += [UILabel sizeForText:[NotificationBodyCell getAttributedText:notif.text]
                                   inBound:CGSizeMake(NOTIF_TEXT_WIDTH, 10000.0f)].height;
        
        height = @(textHeight);
        [textHeightCache setObject:height forKey:notif.text];
    }
    return [height floatValue];
}

+ (CGFloat)rowHeight:(Notification*)notif
{
    CGFloat rowHeight = [self textHeight:notif] + 65;
    if (notif.button) {
        rowHeight += 40;
    }
    if (notif.type == EMMA_NOTIF_TYPE_1DAY_BEFORE_FB) {
        Reminder * reminderBBT = [Reminder getReminderByType:REMINDER_TYPE_SYS_BBT];;
        if (reminderBBT.on) { rowHeight += 40; }
    }
    return rowHeight;
}
@end





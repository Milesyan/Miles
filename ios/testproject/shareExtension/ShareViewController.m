//
//  ShareViewController.m
//  Share
//
//  Created by ltebean on 15/5/26.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import "ShareViewController.h"
#import "ConfigurationViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ForumAPI.h"
#import <libextobjc/EXTScope.h>
#import "KeyChainStore.h"

@interface ShareData : NSObject
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSURL *url;
@property (nonatomic, copy) NSString *title;
@end
@implementation ShareData
@end

typedef NS_ENUM(NSInteger, ConfigItem) {
    ConfigItemAnonymous = 0,
    ConfigItemGroup = 1,
    ConfigItemTMI = 2,
};

#define FORUM_MIN_TITLE_LENGTH 5
#define FORUM_MAX_TITLE_LENGTH 255

@interface ShareViewController ()<ConfigurationViewControllerDelegate>
@property (nonatomic, strong) SLComposeSheetConfigurationItem *groupConfigItem;
@property (nonatomic, strong) SLComposeSheetConfigurationItem *anonymousConfigItem;
@property (nonatomic, strong) SLComposeSheetConfigurationItem *tmiConfigItem;
@property (nonatomic, copy) NSString *userToken;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSDictionary *selectedGroup;
@property (nonatomic) BOOL anonymous;
@property (nonatomic) BOOL tmi;
@property (nonatomic) ConfigItem configItem;
@end

@implementation ShareViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.userToken = [KeyChainStore userToken];
    [ForumAPI sharedInstance].userToken = self.userToken;
    
    self.groupConfigItem = [SLComposeSheetConfigurationItem new];
    self.groupConfigItem.title = @"Group";
    self.groupConfigItem.valuePending = YES;
    @weakify(self)
    self.groupConfigItem.tapHandler = ^{
        @strongify(self)
        if (!self.groups) {
            return;
        }
        self.configItem = ConfigItemGroup;
        NSMutableArray *options = [NSMutableArray array];
        for (NSDictionary *group in self.groups) {
            [options addObject:group[@"name"]];
        }
        ConfigurationViewController *vc = [ConfigurationViewController new];
        vc.delegate = self;
        vc.options = options;
        vc.selectedOption = self.groupConfigItem.value;
        [self pushConfigurationViewController:vc];
    };
    
    self.anonymousConfigItem = [SLComposeSheetConfigurationItem new];
    self.anonymousConfigItem.title = @"Post as anonymous";
    self.anonymousConfigItem.value = @"No";
    self.anonymousConfigItem.tapHandler = ^{
        @strongify(self)
        self.configItem = ConfigItemAnonymous;
        ConfigurationViewController *vc = [ConfigurationViewController new];
        vc.options = @[@"No", @"Yes"];
        vc.delegate = self;
        vc.selectedOption = self.anonymousConfigItem.value;
        [self pushConfigurationViewController:vc];
    };
    
    self.tmiConfigItem = [SLComposeSheetConfigurationItem new];
    self.tmiConfigItem.title = @"TMI";
    self.tmiConfigItem.value = @"No";
    self.tmiConfigItem.tapHandler = ^{
        @strongify(self)
        self.configItem = ConfigItemTMI;
        ConfigurationViewController *vc = [ConfigurationViewController new];
        vc.options = @[@"No", @"Yes"];
        vc.delegate = self;
        vc.selectedOption = self.tmiConfigItem.value;
        [self pushConfigurationViewController:vc];
    };

    [[ForumAPI sharedInstance] fetchGroups:^(BOOL success, NSArray *groups) {
        if (success && groups) {
            self.groupConfigItem.valuePending = NO;
            self.groups = groups;
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.textView.text = @"";
}

- (BOOL)isContentValid {
    // Do validation of contentText and/or NSExtensionContext attachments here
    if (!self.userToken) {
        return NO;
    }
    if (!self.selectedGroup) {
        return NO;
    }
    NSString *title = [self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length < FORUM_MIN_TITLE_LENGTH) {
        return NO;
    } else if (title.length > FORUM_MAX_TITLE_LENGTH) {
        return NO;
    }
    return YES;
}

- (void)didSelectPost {
    // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
    // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
    
    [self shareData:^(ShareData *shareData) {
        NSInteger groupId = [self.selectedGroup[@"id"] integerValue];
        if (shareData.image) {
            [[ForumAPI sharedInstance] postImage:shareData.image title:shareData.title groupId:groupId anonymous:self.anonymous tmi:self.tmi];
        } else if (shareData.url) {
            [[ForumAPI sharedInstance] postURL:shareData.url title:shareData.title groupId:groupId anonymous:self.anonymous];
        }
        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
    }];
}

- (NSArray *)configurationItems {   
    // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
    if ([self hasImage]) {
        return @[self.tmiConfigItem, self.anonymousConfigItem, self.groupConfigItem];
    } else {
        return @[self.groupConfigItem];
    }
}

- (void)configurationViewController:(ConfigurationViewController *)viewController didSelectOptionAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    if (self.configItem == ConfigItemGroup) {
        self.groupConfigItem.value = viewController.options[row];
        self.selectedGroup = self.groups[row];
    }
    else if (self.configItem == ConfigItemAnonymous) {
        self.anonymousConfigItem.value = viewController.options[row];
        self.anonymous = row == 0 ? NO : YES;
    }
    else if (self.configItem == ConfigItemTMI) {
        self.tmiConfigItem.value = viewController.options[row];
        self.tmi = row == 0 ? NO : YES;
    }
    
    [self popConfigurationViewController];
}

- (void)shareData:(void(^)(ShareData *))completionHandler
{
    ShareData *shareData = [ShareData new];
    shareData.title = self.contentText;
    __block NSInteger count = 0;

    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                count++;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeImage options:nil completionHandler:^(UIImage *image, NSError *error) {
                    shareData.image = image;
                    count--;
                    if (count == 0) {
                        return completionHandler(shareData);
                    }
                }];
            }
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeURL]) {
                count++;
                [itemProvider loadItemForTypeIdentifier:(NSString *)kUTTypeURL options:nil completionHandler:^(NSURL *url, NSError *error) {
                    shareData.url = url;
                    count--;
                    if (count == 0) {
                        return completionHandler(shareData);
                    }
                }];
            }
        }
    }
    if (count == 0) {
        return completionHandler(shareData);
    }
}

- (BOOL)hasImage
{
    for (NSExtensionItem *item in self.extensionContext.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            if ([itemProvider hasItemConformingToTypeIdentifier:(NSString *)kUTTypeImage]) {
                return YES;
            }
        }
    }
    return NO;
}
@end
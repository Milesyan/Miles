//
//  GLAppGalleryTableViewController.m
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <StoreKit/SKStoreProductViewController.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "GLAppGalleryTableViewController.h"
#import "GLAppGalleryCell.h"

static NSString * const GLAppGalleryCellIdentifier = @"AppCell";

@interface GLAppGalleryTableViewController () <SKStoreProductViewControllerDelegate>

@end

@implementation GLAppGalleryTableViewController

+ (GLAppGalleryTableViewController *)viewControllerFromStoryboard {
    return [[UIStoryboard storyboardWithName:@"AppGallery" bundle:nil] instantiateViewControllerWithIdentifier:@"AppGalleryTable"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Logging log:PAGE_IMP_GLOW_APP_GALLERY];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.apps.count;
}

- (GLAppEntity *)appEntityAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.apps.count) {
        return self.apps[indexPath.row];
    }
    return nil;
}

- (void)configureCell:(GLAppGalleryCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    GLAppEntity *app = [self appEntityAtIndexPath:indexPath];
    NSString *action = nil;
    if (app.schema.length > 0 && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:app.schema]]) {
        action = NSLocalizedString(@"OPEN", nil);
    } else {
        action = NSLocalizedString(@"GET", nil);
    }
    [cell.actionButton setTitle:action forState:UIControlStateNormal];
    cell.actionButton.tag = indexPath.row;
    cell.titleLabel.text = app.name;
    cell.descriptionLabel.text = app.desc;
    cell.iconView.image = nil;
    if (app.icon) {
        cell.iconView.image = app.icon;
    } else if (app.iconURL) {
        NSURL *iconURL = [NSURL URLWithString:app.iconURL];
        [cell.iconView sd_setImageWithURL:iconURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
            if (image && !error) {
                app.icon = image;
            }
        }];
    } else {
        cell.iconView.image = nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    static GLAppGalleryCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:GLAppGalleryCellIdentifier];
    });
    sizingCell.width = tableView.width;
    [self configureCell:sizingCell atIndexPath:indexPath];
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    if (tableView.separatorStyle == UITableViewCellSeparatorStyleNone) {
        return size.height;
    } else {
        return size.height + 0.5;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    GLAppGalleryCell *cell = [tableView dequeueReusableCellWithIdentifier:GLAppGalleryCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self openOrGetAppAtIndexPath:indexPath];
}

- (void)openOrGetAppAtIndexPath:(NSIndexPath *)indexPath {
    GLAppEntity *app = [self appEntityAtIndexPath:indexPath];
    if (app.schema.length > 0) {
        NSURL *appSchema = [NSURL URLWithString:app.schema];
        if ([[UIApplication sharedApplication] canOpenURL:appSchema]) {
            [Logging log:BTN_CLK_APP_GALLERY_OPEN eventData:@{
                @"has_app": @(YES),
                @"app_id": @(app.appID)
            }];
            [[UIApplication sharedApplication] openURL:appSchema];
            return;
        }
    }
    if (app.appID > 0) {
        [Logging log:BTN_CLK_APP_GALLERY_OPEN eventData:@{
            @"has_app": @(NO),
            @"app_id": @(app.appID)
        }];
        SKStoreProductViewController *store = [[SKStoreProductViewController alloc] init];
        store.delegate = self;
        NSMutableDictionary *params = [@{
            SKStoreProductParameterITunesItemIdentifier: @(app.appID),
        } mutableCopy];
        if (&SKStoreProductParameterProviderToken) {
            params[SKStoreProductParameterProviderToken] = @"10642855";
        }
        if (&SKStoreProductParameterCampaignToken) {
            params[SKStoreProductParameterCampaignToken] = @"EMMA_IN_APP";
        }
        [self presentViewController:store animated:YES completion:nil];
        [store loadProductWithParameters:params completionBlock:^(BOOL result, NSError *error) {
            if (result) {
            } else {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }];
    }
}

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didClickActionButton:(id)sender {
    NSInteger index = [(UIButton *)sender tag];
    [self openOrGetAppAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
}

@end

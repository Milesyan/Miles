//
//  ConfigurationViewController.h
//  ShareTest
//
//  Created by ltebean on 15/5/26.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>

@class ConfigurationViewController;

@protocol ConfigurationViewControllerDelegate <NSObject>
-(void)configurationViewController:(ConfigurationViewController *)viewController didSelectOptionAtIndexPath:(NSIndexPath * )indexPath;
@end

@interface ConfigurationViewController : UITableViewController
@property (nonatomic, strong) NSArray *options;
@property (nonatomic, copy) NSString *selectedOption;
@property (nonatomic, weak) id<ConfigurationViewControllerDelegate> delegate;
@end

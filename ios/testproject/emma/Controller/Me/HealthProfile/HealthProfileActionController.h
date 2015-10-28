//
//  HealthProfileActionController.h
//  emma
//
//  Created by Peng Gu on 3/24/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


@class HealthProfileDataController;
@class HealthProfileItem;

@protocol HealthProfileActionControllerDelegate <NSObject>

- (void)actionControllerDidSaveUpdate;
- (void)actionControllerNeedsToPerformSegue:(NSString *)segueIdentifier;

@end


@interface HealthProfileActionController : NSObject

@property (nonatomic, weak) id<HealthProfileActionControllerDelegate> delegate;

- (instancetype)initWithTableView:(UITableView *)tableView
                   dataController:(HealthProfileDataController *)dataController;

- (void)performActionForItem:(HealthProfileItem *)item;

@end

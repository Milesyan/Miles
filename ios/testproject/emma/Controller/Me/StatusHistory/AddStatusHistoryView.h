//
//  AddStatusHistoryView.h
//  emma
//
//  Created by ltebean on 15/6/23.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserStatus.h"

@class AddStatusHistoryView;

@protocol AddStatusHistoryViewDelegate <NSObject>
- (void)addStatusHistoryViewDidCancel:(AddStatusHistoryView *)view;
- (void)addStatusHistoryView:(AddStatusHistoryView *)view didWantToAddStatusHistory:(UserStatus *)statusHistory;

@end

@interface AddStatusHistoryView : UIView
@property (nonatomic, weak) id<AddStatusHistoryViewDelegate> delegate;
- (void)setupToInitialLook;
@end

//
//  Share.h
//  emma
//
//  Created by Peng Gu on 8/18/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ShareType) {
    ShareTypeNone,
    ShareTypeAppReferral,
    ShareTypeAppShareMe,
    ShareTypeAppShareDailyTodo,
    ShareTypeAppShareSyncComplete,
    ShareTypeInsightShare,
    ShareTypeInsightShareThreeLikes,
    ShareTypeGroupShare,
    ShareTypeTopicShare,
    ShareTypeTopicShareAddingNew,
    ShareTypePollShare,
    ShareTypePollShareAddingNew,
    ShareTypePhotoShare,
    ShareTypePhotoShareAddingNew,
    ShareTypeQuizResult,
};

typedef void (^shareCallback)(BOOL success, NSDictionary *data, NSError *error);

@interface Share : NSObject

+ (void)shareItem:(id)item
        shareType:(ShareType)shareType
       completion:(shareCallback)completion;

+ (NSNumber *)itemIDForItem:(id)item shareType:(ShareType)shareType;
+ (UIImage *)imageForItem:(id)item shareType:(ShareType)shareType;
+ (NSString *)descriptionForShareType:(ShareType)shareType;

@end

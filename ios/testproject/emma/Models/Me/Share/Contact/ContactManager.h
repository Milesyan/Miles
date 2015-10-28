//
//  ContactManager.h
//  emma
//
//  Created by Peng Gu on 8/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, LoadContactsStatus) {
    LoadContactsStatusNotStartedYet,
    LoadContactsStatusAccessDenied,
    LoadContactsStatusFailed,
    LoadContactsStatusLoading,
    LoadContactsStatusLoaded
};

typedef void(^loadContactsCompletionBlock)(BOOL success, NSError *error);

@interface ContactManager : NSObject

@property (nonatomic, strong) NSArray *contacts;
@property (nonatomic, strong) NSDictionary *alphabetContacts;
@property (nonatomic, assign) LoadContactsStatus status;
@property (nonatomic, assign) BOOL combineEmailAndPhone;

- (void)asyncLoadContactsWithCompletion:(loadContactsCompletionBlock)completion;

@end

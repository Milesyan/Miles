//
//  EmailContact.h
//  emma
//
//  Created by Jirong Wang on 5/6/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, ContactSendStatus) {
    ContactSendStatusReadyToSend,
    ContactSendStatusSending,
    ContactSendStatusSent
};


typedef NS_ENUM(NSUInteger, ContactType) {
    ContactTypeNone,
    ContactTypeEmail,
    ContactTypePhone,
    ContactTypeEmailAndPhone,
};


@interface Contact : NSObject

@property (nonatomic) NSString * name;
@property (nonatomic) NSString * email;
@property (nonatomic, strong) NSString *phoneNumber;

@property (nonatomic, assign) ContactSendStatus sendStatus;
@property (nonatomic, assign) ContactType contactType;
@property (nonatomic, assign) BOOL glowUser;

+ (instancetype)contactWithName:(NSString *)name email:(NSString *)email phone:(NSString *)phone;
- (id)initWithEmail:(NSString *)email withName:(NSString *)name phoneNumber:(NSString *)phoneNumber;

@end

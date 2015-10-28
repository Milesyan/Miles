//
//  EmailContact.m
//  emma
//
//  Created by Jirong Wang on 5/6/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "Contact.h"

@implementation Contact


+ (instancetype)contactWithName:(NSString *)name email:(NSString *)email phone:(NSString *)phone
{
    return [[Contact alloc] initWithEmail:email withName:name phoneNumber:phone];
}


- (id)initWithEmail:(NSString *)email withName:(NSString *)name phoneNumber:(NSString *)phoneNumber
{
    self = [super init];
    if (self) {
        self.email = email;
        self.name = name;
        self.phoneNumber = phoneNumber;
        self.glowUser = NO;
        self.sendStatus = ContactSendStatusReadyToSend;
        
        if (email && !phoneNumber) {
            self.contactType = ContactTypeEmail;
        }
        else if (phoneNumber && !email) {
            self.contactType = ContactTypePhone;
        }
        else if (phoneNumber && email) {
            self.contactType = ContactTypeEmailAndPhone;
        }
    }

    return self;
}

@end

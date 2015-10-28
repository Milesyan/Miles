//
//  ContactManager.m
//  emma
//
//  Created by Peng Gu on 8/14/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ContactManager.h"
#import "Contact.h"
#import <AddressBook/AddressBook.h>
#import "NSString+Transliteration.h"

@interface ContactManager ()

@end


@implementation ContactManager


- (id)init
{
    self = [super init];
    if (self) {
        self.status = LoadContactsStatusNotStartedYet;
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) {
            self.status = LoadContactsStatusAccessDenied;
        }
    }
    return self;
}


- (NSDictionary *)alphabetContacts
{
    if (self.contacts && !_alphabetContacts) {
        
        NSCharacterSet *charSet = [NSCharacterSet uppercaseLetterCharacterSet];
        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
        
        for (Contact *each in self.contacts) {
            NSString *firstChar = [[each.name transliteratedFirstCharacter] uppercaseString];
            if (![charSet characterIsMember:[firstChar uppercaseFirstCharacter]]) {
                firstChar = @"#";
            }
        
            if ([mdict valueForKey:firstChar]) {
                [mdict[firstChar] addObject:each];
            }
            else {
                mdict[firstChar] = [NSMutableArray arrayWithObject:each];
            }
        }
        _alphabetContacts = mdict;
    }
    return _alphabetContacts;
}


- (void)asyncLoadContactsWithCompletion:(loadContactsCompletionBlock)completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
            [self loadContactsWithCompletion:completion];
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
            [self loadContactsWithCompletion:completion];
        }
        else {
            // user has previously denied access
            self.status = LoadContactsStatusAccessDenied;
            [self askAccess];
            completion(NO, nil);
        }
    });
}


- (void)askAccess
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Contacts Failed to Load"
                                                        message:@"Please go to Settings -> Privacy -> Contacts and allow Glow to access your contacts"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
        [alert show];
    });
}


- (void)loadContactsWithCompletion:(loadContactsCompletionBlock)completion
{
    CFErrorRef error = nil;
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);
    if (addressBook == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = LoadContactsStatusFailed;
            completion(NO, (__bridge NSError *)error);
        });
        return;
    }
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (error || !granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.status = LoadContactsStatusAccessDenied;
                completion(NO, (__bridge NSError *)error);
                [self askAccess];
            });
            return;
        }
        
        self.status = LoadContactsStatusLoading;
        
        NSArray *contacts = [self makeContactsFromAddressBook:addressBook];
        NSSortDescriptor *sortDesc = [NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                   ascending:YES
                                                                    selector:@selector(localizedCaseInsensitiveCompare:)];
        self.contacts = [contacts sortedArrayUsingDescriptors:@[sortDesc]];
        
        CFRelease(addressBook);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.status = LoadContactsStatusLoaded;
            completion(YES, nil);
        });
    });
}


- (NSArray *)makeContactsFromAddressBook:(ABAddressBookRef)addressBook
{
    NSMutableArray *contacts = [NSMutableArray array];
    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    for (int i=0;i < ABAddressBookGetPersonCount(addressBook);i++) {
        ABRecordRef personRef = CFArrayGetValueAtIndex(allPeople,i);
        NSArray *contactArray = [self makeContactFromPersonRef:personRef];
        if (contactArray) {
            [contacts addObjectsFromArray:contactArray];
        }
    }
    
    // CF copied values need to be released
    CFRelease(allPeople);
    
    return contacts;
}


- (NSArray *)makeContactFromPersonRef:(ABRecordRef)personRef
{
    NSString *phoneNumber, *email;
    
    ABMultiValueRef phonesRef = ABRecordCopyValue(personRef, kABPersonPhoneProperty);
    if (!phonesRef || ABMultiValueGetCount(phonesRef) == 0) {
        phoneNumber = nil;
    }
    else {
        phoneNumber = CFBridgingRelease(ABMultiValueCopyValueAtIndex(phonesRef, 0));
    }
    
    ABMultiValueRef emailsRef = ABRecordCopyValue(personRef, kABPersonEmailProperty);
    if (!emailsRef || ABMultiValueGetCount(emailsRef) == 0) {
        email = nil;
    }
    else {
        email = CFBridgingRelease(ABMultiValueCopyValueAtIndex(emailsRef, 0));
    }
    
    NSString *name = CFBridgingRelease(ABRecordCopyCompositeName(personRef));
    
    if (!phoneNumber && !email) {
        return nil;
    }
    
    NSMutableArray *toReturn = [NSMutableArray array];
    if (self.combineEmailAndPhone) {
        Contact *contact = [Contact contactWithName:name email:email phone:phoneNumber];
        contact.contactType = ContactTypeEmailAndPhone;
        [toReturn addObject:contact];
    }
    else {
        if (email) {
            Contact *contact = [Contact contactWithName:name email:email phone:nil];
            contact.contactType = ContactTypeEmail;
            [toReturn addObject:contact];
        }
        if (phoneNumber) {
            Contact *contact = [Contact contactWithName:name email:nil phone:phoneNumber];
            contact.contactType = ContactTypePhone;
            [toReturn addObject:contact];
        }
    }
    
    
    if (phonesRef) CFRelease(phonesRef);
    if (emailsRef) CFRelease(emailsRef);
    
    return toReturn;
}


@end

//
//  ContactManager+GlowUsers.m
//  emma
//
//  Created by Peng Gu on 8/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ContactManager+GlowUsers.h"
#import "User.h"
#import "Network.h"
#import "NSString+Transliteration.h"

@implementation ContactManager (GlowUsers)

- (void)checkGlowUsersWithCompletion:(loadContactsCompletionBlock)completion
{
    if (!self.contacts) {
        completion(NO, nil);
    }
    
    NSArray *emails = [self.contacts valueForKeyPath:@"email"];
    NSString *url = @"users/load_glow_user";
    NSDictionary *request = [[User currentUser] postRequest:@{@"emails": emails}];
    
    [[Network sharedNetwork] post:url data:request requireLogin:YES completionHandler:^(NSDictionary *result, NSError *err) {
        if (err) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, err);
            });
        }
        
        NSInteger rc = [[result objectForKey:@"rc"] integerValue];
        if (rc == RC_SUCCESS) {
            NSArray * glowEmails = [result objectForKey:@"glow_emails"];
            if (glowEmails.count > 0) {
                NSArray *glowContacts = [self getGlowContactsFromEmails:glowEmails];
                [self updateContactsWithGlowContacts:glowContacts];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES, nil);
            });
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(NO, nil);
            });
        }
    }];
}


- (NSArray *)getGlowContactsFromEmails:(NSArray *)glowEmails
{
    NSArray *emails = [self.contacts valueForKeyPath:@"email"];
    NSMutableArray *glowContacts = [NSMutableArray array];
    
    for (NSString *each in glowEmails) {
        NSUInteger index = [emails indexOfObject:each];
        [glowContacts addObject: self.contacts[index]];
    }
    
    return glowContacts;
}


- (void)updateContactsWithGlowContacts:(NSArray *)contacts
{
    NSMutableArray *glowContacts = [NSMutableArray array];
    NSMutableDictionary *temp = [self.alphabetContacts mutableCopy];
    
    NSCharacterSet *charSet = [NSCharacterSet uppercaseLetterCharacterSet];
    
    for (Contact *contact in contacts) {
        contact.glowUser = YES;
        
        NSString *key = [[contact.name transliteratedFirstCharacter] uppercaseString];
        if (![charSet characterIsMember:[key uppercaseFirstCharacter]]) {
            key = @"#";
        }
        
        NSMutableArray *contactArray = [temp objectForKey:key];
        
        [contactArray removeObject:contact];
        [glowContacts addObject:contact];
        
        if (contactArray.count == 0) {
            [temp removeObjectForKey:key];
        }
    }
    
    [temp setObject:glowContacts forKey:KEY_FOR_GLOW_USER];
    self.alphabetContacts = temp;
}


@end







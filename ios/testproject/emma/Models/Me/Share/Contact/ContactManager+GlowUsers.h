//
//  ContactManager+GlowUsers.h
//  emma
//
//  Created by Peng Gu on 8/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ContactManager.h"

#define KEY_FOR_GLOW_USER @"!"

@interface ContactManager (GlowUsers)

- (void)checkGlowUsersWithCompletion:(loadContactsCompletionBlock)completion;

@end

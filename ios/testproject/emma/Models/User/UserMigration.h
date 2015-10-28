//
//  UserMigration.h
//  emma
//
//  Created by Xin Zhao on 13-10-30.
//  Copyright (c) 2013年 Upward Labs. All rights reserved.
//

// TO BE DELETED

#import "User.h"
#import <Foundation/Foundation.h>

@interface UserMigration : NSObject

+(void)migrateFromAppVersion:(NSString *)old toVersion:(NSString *)new forUser:(User *)user;
    
@end

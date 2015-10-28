//
//  GLAppEntity.h
//  Lexie
//
//  Created by Allen Hsu on 6/5/15.
//  Copyright (c) 2015 Glow, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GLAppEntity : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *schema;
@property (nonatomic, copy) NSString *iconURL;
@property (nonatomic, assign) NSUInteger appID;

@property (nonatomic, strong) UIImage *icon;

@end

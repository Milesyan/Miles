//
//  ForumCategory.m
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ForumCategory.h"

@implementation ForumCategory

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            id obj;
            obj = [dict objectForKey:@"id"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _identifier = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"priority"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _priority = [obj unsignedIntValue];
            }
            obj = [dict objectForKey:@"private"];
            if ([obj isKindOfClass:[NSNumber class]]) {
                _private = [obj boolValue];
            }
            obj = [dict objectForKey:@"name"];
            if ([obj isKindOfClass:[NSString class]]) {
                _name = obj;
            }
            obj = [dict objectForKey:@"description"];
            if ([obj isKindOfClass:[NSString class]]) {
                _categoryDescription = obj;
            }
            obj = [dict objectForKey:@"icon"];
            if ([obj isKindOfClass:[NSString class]]) {
                _icon = obj;
            }
            obj = [dict objectForKey:@"background_color"];
            if ([obj isKindOfClass:[NSString class]]) {
                _backgroundColor = obj;
            }
            obj = [dict objectForKey:@"slug"];
            if ([obj isKindOfClass:[NSString class]]) {
                _slug = obj;
            }
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[ForumCategory class]]) {
        return self.identifier == ((ForumCategory *)object).identifier;
    } else {
        return [super isEqual:object];
    }
}

+ (ForumCategory *)bookmarkCategory
{
    ForumCategory *category = [[ForumCategory alloc] init];
    category.name = @"Bookmarked Topics";
    category.backgroundColor = @"#383838";
//    category.type = ForumCategoryTypeBookmarked;
    category.identifier = ForumCategoryIdBookmark;
    return category;
}

+ (ForumCategory *)defaultCategory
{
    ForumCategory *category = [[ForumCategory alloc] init];
    category.name = @"Category";
    category.backgroundColor = @"#6263d2";
//    category.type = ForumCategoryTypeNormal;
    category.identifier = 1002;
    return category;
}
@end

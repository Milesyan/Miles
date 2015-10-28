//
//  ForumCategory.h
//  emma
//
//  Created by Allen Hsu on 11/19/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

//typedef NS_ENUM(NSInteger, ForumCategoryType) {
//    ForumCategoryTypeNormal = 0,
//    ForumCategoryTypeParticipated,
//    ForumCategoryTypeBookmarked,
//    ForumCategoryTypeCreated,
//};

typedef NS_ENUM(NSInteger, ForumCategoryId) {
    ForumCategoryIdBookmark     = 1001,
};

@interface ForumCategory : NSObject

@property (assign, nonatomic) unsigned int identifier;
@property (assign, nonatomic) unsigned int priority;
@property (assign, nonatomic) BOOL private;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *categoryDescription;
@property (strong, nonatomic) NSString *icon;
@property (strong, nonatomic) NSString *backgroundColor;
@property (strong, nonatomic) NSString *slug;
@property (assign, nonatomic) unsigned int count;
//@property (assign, nonatomic) ForumCategoryType type;

- (id)initWithDictionary:(NSDictionary *)dict;

+ (ForumCategory *)bookmarkCategory;
+ (ForumCategory *)defaultCategory;

@end

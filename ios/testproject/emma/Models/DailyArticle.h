//
//  DailyArticle.h
//  emma
//
//  Created by ltebean on 15-2-27.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "BaseModel.h"
#import "User.h"


@interface DailyArticle : BaseModel
@property (nonatomic) uint64_t topicId;
@property (nonatomic, strong) NSString *date;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *introduction;
@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic) uint64_t articleId;
@property (nonatomic) uint64_t likes;
@property (nonatomic) uint64_t comments;

@property (nonatomic, strong) User *user;
+ (DailyArticle *)articleAtDate:(NSString *)date forUser:(User *)user;
+ (DailyArticle *)articleByTopicId:(uint64_t)topicId forUser:(User *)user;
+ (void)updateWithServerData:(NSArray *)serverData onDate:(NSString *)date forUser:(User *)user;
- (void)updateAttrsFromDictionary:(NSDictionary *)dict;
- (BOOL)hasThumbnail;
@end

//
//  ForumAPI.h
//  ShareTest
//
//  Created by ltebean on 15/5/29.
//  Copyright (c) 2015年 glow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ForumAPI : NSObject
@property (nonatomic, copy) NSString *userToken;
+ (instancetype)sharedInstance;
- (void)fetchGroups:(void(^)(BOOL, NSArray *))completionHandler;
- (void)postImage:(UIImage *)image title:(NSString *)title groupId:(NSInteger)groupId anonymous:(BOOL)anonymous tmi:(BOOL)tmi;
- (void)postURL:(NSURL *)url title:(NSString *)title groupId:(NSInteger)groupId anonymous:(BOOL)anonymous;
@end

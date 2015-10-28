//
//  ForumPromotionFeed.h
//  Pods
//
//  Created by Eric Xu on 7/18/15.
//
//

#import <Foundation/Foundation.h>

@interface ForumPromotionFeed : NSObject
@property (nonatomic, strong) NSDictionary *feedDict;

- (id)initWithDictionary:(NSDictionary *)dict;
- (NSObject *)getFeedProperty:(NSString *)propertyKey;
- (NSString *)htmlContent;
- (NSInteger)identifier;
@end

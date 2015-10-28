//
//  ForumPromotionFeed.m
//  Pods
//
//  Created by Eric Xu on 7/18/15.
//
//

#import "ForumPromotionFeed.h"


@interface ForumPromotionFeed()

@end

@implementation ForumPromotionFeed

- (id)initWithDictionary:(NSDictionary *)dict {
    if (!self) {
        self = [[ForumPromotionFeed alloc] init];
    }
    
    self.feedDict = [dict copy];
    
    return self;
}

- (NSObject *)getFeedProperty:(NSString *)propertyKey {
    if (self.feedDict) {
        return self.feedDict[propertyKey];
    }
    return nil;
}
- (NSString *)htmlContent {
    NSObject *content =[self getFeedProperty:@"content_html"];
    return content? [NSString stringWithFormat: @"%@", content] : @"";
}

- (NSInteger)identifier {
    NSObject *identifier =[self getFeedProperty:@"identifier"];
    return identifier? [(NSNumber *)identifier integerValue]: 0;
}

@end

//
//  AskRateDialog.h
//  emma
//
//  Created by Jirong Wang on 4/15/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AskRateDialog : NSObject<UIAlertViewDelegate>

+ (AskRateDialog *)getInstance;

- (void)goToRatePage;

@end

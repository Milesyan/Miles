//
//  FundGrantCell.h
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FundOngoingBaseCell.h"

@interface FundOngoingGrantCell : FundOngoingBaseCell

@property (strong, nonatomic) IBOutlet UILabel *mainLabel;
@property (strong, nonatomic) IBOutlet UILabel *secondaryLabel;

@end

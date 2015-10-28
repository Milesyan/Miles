//
//  EmailContactCell.h
//  emma
//
//  Created by Jirong Wang on 4/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@class ContactCell;

@protocol ContactCellDelegate <NSObject>

@optional
- (void)ContactCellDidClickButton:(ContactCell *)cell contact:(Contact *)contact;

@end


@interface ContactCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *logoView;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *subLabel;
@property (weak, nonatomic) IBOutlet UIView *separator;

@property (weak, nonatomic) id<ContactCellDelegate> delegate;
@property (strong, nonatomic) Contact * contact;

+ (NSString *)reuseIdentifier;


@end

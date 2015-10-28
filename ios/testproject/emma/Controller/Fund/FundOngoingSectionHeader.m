//
//  FundOngoingSectionHeader.m
//  emma
//
//  Created by Jirong Wang on 11/28/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundOngoingSectionHeader.h"

@interface FundOngoingSectionHeader()

@property (strong, nonatomic) IBOutlet UILabel *headerLabel;

@end

@implementation FundOngoingSectionHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setHeaderText:(NSString *)text width:(CGFloat)width {
    self.headerLabel.text = text;
    // self.headerLabel.frame = setRectWidth(self.headerLabel.frame, width);
    self.headerLabel.aWidth = width;
    // self.headerLabel.center = CGPointMake(160, 25);
    self.headerLabel.layer.cornerRadius = 15;
}



@end

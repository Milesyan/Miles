//
//  EmailContactCell.m
//  emma
//
//  Created by Jirong Wang on 4/11/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ContactCell.h"
#import "PillButton.h"
#import "Contact.h"
#import <QuartzCore/QuartzCore.h>

#define CONTACT_CELL_IDENTIFIER @"contactCellIdentifier"



@interface ContactCell()

@property (nonatomic, weak) IBOutlet UIButton *sendButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *mainLabelConstraintLeft;

- (IBAction)buttonClicked:(id)sender;

@end

@implementation ContactCell

+ (NSString *)reuseIdentifier
{
    return CONTACT_CELL_IDENTIFIER;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.mainLabel.text = @"";
    self.subLabel.text = @"";
    self.subLabel.hidden = YES;
    
    self.sendButton.layer.cornerRadius = CGRectGetHeight(self.sendButton.frame) / 2;
}


- (void)setContact:(Contact *)model
{
    _contact = model;
    [self redraw];
}


- (BOOL)hasSubLabel
{
    return [Utils isEmptyString:self.contact.name] ? NO : YES;
}


- (void)redraw
{
    NSString *contactToShow = self.contact.email ? self.contact.email : self.contact.phoneNumber;
    if ([self hasSubLabel]) {
        self.mainLabel.text = self.contact.name;
        self.subLabel.text = contactToShow;
        self.subLabel.hidden = NO;
    }
    else {
        self.mainLabel.text = contactToShow;
        self.subLabel.hidden = YES;
    }
    
    if (self.contact.glowUser) {
        self.logoView.hidden = NO;
        self.mainLabelConstraintLeft.constant = self.logoView.width;
    }
    else {
        self.logoView.hidden = YES;
        self.mainLabelConstraintLeft.constant = 0;
    }
    [self layoutIfNeeded];
    
    [self updateSendButton];
}


- (void)updateSendButton
{
    if (self.contact.sendStatus == ContactSendStatusReadyToSend) {
        [self.sendButton setTitle:@"Send" forState:UIControlStateNormal];
        self.sendButton.alpha = 1;
        self.sendButton.enabled = YES;
    }
    else if (self.contact.sendStatus == ContactSendStatusSending){
        [self.sendButton setTitle:@"Sending" forState:UIControlStateNormal];
        self.sendButton.alpha = 1;
        self.sendButton.enabled = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.contact.sendStatus == ContactSendStatusSending) {
                self.contact.sendStatus = ContactSendStatusSent;
                [self updateSendButton];
            }
        });
    }
    else if (self.contact.sendStatus == ContactSendStatusSent) {
        self.sendButton.alpha = 0.5;
        self.sendButton.enabled = NO;
        [self.sendButton setTitle:@"Sent" forState:UIControlStateDisabled];
    }
}


- (IBAction)buttonClicked:(id)sender
{
    if (self.contact.sendStatus == ContactSendStatusReadyToSend) {
        self.contact.sendStatus = ContactSendStatusSending;
        [self updateSendButton];
        [self publish:EVENT_CONTACT_CELL_CLICKED data:self.contact];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(ContactCellDidClickButton:contact:)]) {
            [self.delegate ContactCellDidClickButton:self contact:self.contact];
        }
    }
}
@end

//
//  ContactTableViewController.h
//  emma
//
//  Created by Peng Gu on 8/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define KEY_FOR_ADDED_CONTACT @"+"

@class Contact;
@class ContactManager;

@interface ContactViewController : NSObject

@property (nonatomic, strong) UITableView *tableView;

- (instancetype)initWithTableView:(UITableView *)tableView;
- (void)loadContacts;
- (void)addNewContact:(Contact *)contact;

@end

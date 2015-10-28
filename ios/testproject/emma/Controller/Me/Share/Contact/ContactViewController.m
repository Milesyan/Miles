//
//  ContactTableViewController.m
//  emma
//
//  Created by Peng Gu on 8/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "ContactViewController.h"
#import "ContactManager+GlowUsers.h"
#import "ContactCell.h"
#import "UIView+Helpers.h"

@interface ContactViewController () <ContactCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) UIActivityIndicatorView *spinnerView;
@property (strong, nonatomic) NSMutableDictionary *contacts;
@property (strong, nonatomic) NSMutableArray *sectionKeys;

@end


@implementation ContactViewController

@synthesize contacts = _contacts;

- (instancetype)initWithTableView:(UITableView *)tableView
{
    self = [super init];
    if (self) {
        self.tableView = tableView;
        
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        
        if ([self.tableView respondsToSelector:@selector(estimatedRowHeight)]) {
            self.tableView.estimatedRowHeight = 70;
        }
        self.tableView.sectionIndexColor = [UIColor grayColor];
        [self.tableView registerNib:[UINib nibWithNibName:@"ContactCell" bundle:nil]
             forCellReuseIdentifier:[ContactCell reuseIdentifier]];
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    return self;
}


#pragma mark - Contacts Methods
- (void)loadContacts
{
    ContactManager *manager = [[ContactManager alloc] init];
    
    __weak typeof(self)weakSelf = self;
    void (^resultsArrivedAction)() = ^() {
        NSMutableArray *newAdded = [self.contacts objectForKey:KEY_FOR_ADDED_CONTACT];
        weakSelf.contacts = [NSMutableDictionary dictionary];
        if (newAdded) {
            [weakSelf.contacts setObject:newAdded forKey:KEY_FOR_ADDED_CONTACT];
        }
        
        [weakSelf.contacts addEntriesFromDictionary:manager.alphabetContacts];
        self.sectionKeys = [[weakSelf.contacts.allKeys sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
        
        [weakSelf.tableView reloadData];
    };
    
    [self startLoadingAnimation];
    
    // Load local
    [manager asyncLoadContactsWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            GLLog(@"peng debug load contacts error: %@", error);
            [self stopLoadingAnimation];
            return;
        }
        
        resultsArrivedAction();
        [self stopLoadingAnimation];
        
        // Check Glow Users
        [manager checkGlowUsersWithCompletion:^(BOOL success, NSError *error) {
            if (success) {
                resultsArrivedAction();
            }
        }];
    }];
}


- (void)startLoadingAnimation
{
    if (!self.spinnerView) {
        self.spinnerView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinnerView.center = CGPointMake(self.tableView.center.x, 44);
        [self.tableView addSubview:self.spinnerView];
    }
    [self.spinnerView startAnimating];
}


- (void)stopLoadingAnimation
{
    [self.spinnerView stopAnimating];
    [self.spinnerView removeFromSuperview];
    self.spinnerView = nil;
}


- (void)addNewContact:(Contact *)contact
{
    if (!self.contacts) {
        self.contacts = [NSMutableDictionary dictionary];
        self.sectionKeys = [NSMutableArray array];
    }
    
    if (![self.contacts objectForKey:KEY_FOR_ADDED_CONTACT]) {
        [self.sectionKeys insertObject:KEY_FOR_ADDED_CONTACT atIndex:0];
        [self.contacts setObject:[NSMutableArray array] forKey:KEY_FOR_ADDED_CONTACT];
    }
    [self.contacts[KEY_FOR_ADDED_CONTACT] insertObject:contact atIndex:0];
    
    [self.tableView reloadData];
    [self.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}


- (NSMutableArray *)contactsInSection:(NSUInteger)section
{
    if (section >= self.sectionKeys.count) {
        return nil;
    }
    
    NSString *sectionKey = [self.sectionKeys objectAtIndex:section];
    return [self.contacts objectForKey:sectionKey];
}


- (Contact *)contactAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableArray *contacts = [self contactsInSection:indexPath.section];
    if (!contacts) {
        return nil;
    }
    return [contacts objectAtIndex:indexPath.row];
}


#pragma mark - TableView Delegate & DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sectionKeys.count;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    NSMutableArray *keys = [self.sectionKeys mutableCopy];
    
    NSUInteger index = [keys indexOfObject:KEY_FOR_GLOW_USER];
    if (index != NSNotFound) {
        [keys replaceObjectAtIndex:index withObject:@"☆"];  // ✶✳︎❤︎♡
    }
    
    return keys;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = [self.sectionKeys objectAtIndex:section];
    if ([title isEqualToString:KEY_FOR_ADDED_CONTACT]) {
        return @"Added";
    }
    else if ([title isEqualToString:KEY_FOR_GLOW_USER]) {
        return @"Glow users";
    }
    return title;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 22;
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
    return index;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self contactsInSection:section] count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [self contactAtIndexPath:indexPath];
    return contact.name ? 70 : 50;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell *cell = (ContactCell *)[tableView dequeueReusableCellWithIdentifier:[ContactCell reuseIdentifier]];
    cell.delegate = self;
    cell.contact = [self contactAtIndexPath:indexPath];
    
    BOOL isLastCell = indexPath.row + 1 == [self tableView:tableView numberOfRowsInSection:indexPath.section];
    cell.separator.hidden = isLastCell;
    return cell;
}



@end







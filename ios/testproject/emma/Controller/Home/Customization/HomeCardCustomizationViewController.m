//
//  HomeCardCustomizationViewController.m
//  emma
//
//  Created by ltebean on 15/5/18.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "HomeCardCustomizationViewController.h"
#import "HomeCardCustomizationCell.h"
#import "HomeCardCustomizationManager.h"
#import "User.h"

@interface HomeCardCustomizationViewController ()<UITableViewDataSource, UITableViewDelegate, HomeCardCustomizationCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSDictionary* cardConfig;
@property (nonatomic, strong) NSMutableDictionary* changes;
@property (nonatomic) BOOL orderChanged;
@property (nonatomic, strong) NSMutableArray *order;
@end

@implementation HomeCardCustomizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.changes = [NSMutableDictionary dictionary];
    
    self.cardConfig = @{
                        CARD_PARTNER_SUMMARY: @{
                                @"key": CARD_PARTNER_SUMMARY,
                                @"title": @"Partner's Daily Summary",
                                @"icon": @"home-card-partner"
                                },
                        CARD_IMPORTANT_TASK: @{
                                @"key": CARD_IMPORTANT_TASK,
                                @"title": @"Important Tasks",
                                @"icon": @"home-card-task"
                                },
                        CARD_DAILY_POLL: @{
                                @"key": CARD_DAILY_POLL,
                                @"title": @"Glow Community Poll",
                                @"icon": @"home-card-poll"
                                },
                        CARD_HEALTH_TIPS: @{
                                @"key": CARD_HEALTH_TIPS,
                                @"title": @"Health Tip",
                                @"icon": @"home-card-tip"
                                },
                        CARD_NOTES: @{
                                @"key": CARD_NOTES,
                                @"title": @"Notes",
                                @"icon": @"home-card-note"
                                }
                        };
}

- (BOOL)canEditImportantTask
{
    return [[User currentUser] isPrimary];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    [self.tableView setEditing:YES animated:NO];
    self.orderChanged = NO;
    NSArray *orderOfAllCards = [[HomeCardCustomizationManager sharedInstance] orderOfCards];
    self.order = [orderOfAllCards mutableCopy];
    [self.order removeObject:CARD_MEDICAL_LOG];
    [self.order removeObject:CARD_DAILY_LOG];
    [self.order removeObject:CARD_PARTNER_SUMMARY];
    [self.order removeObject:CARD_RATING];
    [self.order removeObject:CARD_RUBY_RECOMMENDATION];
    [self.order removeObject:CARD_CUSTOMIZATION];
    if (![self canEditImportantTask]) {
        [self.order removeObject:CARD_IMPORTANT_TASK];
    }
    [self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    [Logging log:PAGE_IMP_HOME_CARDS_CUSTOMIZATION];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.order.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HomeCardCustomizationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HomeCardCustomizationCell" forIndexPath:indexPath];
    cell.card = self.cardConfig[self.order[indexPath.row]];
    cell.delegate = self;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableview shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}


- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{

    NSString *cardToMove = [self.order objectAtIndex:sourceIndexPath.row];
    [self.order removeObjectAtIndex:sourceIndexPath.row];
    [self.order insertObject:cardToMove atIndex:destinationIndexPath.row];
    self.orderChanged = YES;
    [Logging log:BTN_CLK_HOME_CARDS_REORDER eventData:@{@"card_type": cardToMove, @"original_position": @(sourceIndexPath.row), @"new_position": @(destinationIndexPath.row)}];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (void)customizationCell:(HomeCardCustomizationCell *)cell didUpdateCardKey:(NSString *)key to:(BOOL)display
{
    self.changes[key] = @(display);
    [Logging log:BTN_CLK_HOME_CARDS_SWITCH eventData:@{@"card_type": key, @"on": display? @(1) : @(0)}];
}

- (IBAction)doneButtonPressed:(id)sender
{
    HomeCardCustomizationManager *manager = [HomeCardCustomizationManager sharedInstance];
    BOOL displayChanged = NO;
    if (self.changes.count != 0) {
        for (NSString *cardKey in self.changes.allKeys) {
            BOOL newValue = [self.changes[cardKey] boolValue];
            BOOL orinialValue = [manager needsDisplayCard:cardKey];
            if (orinialValue != newValue) {
                displayChanged = YES;
                break;
            }
        }
    }
    if (displayChanged) {
        for (NSString *cardKey in self.changes.allKeys) {
            BOOL newValue = [self.changes[cardKey] boolValue];
            [manager setNeedsDisplayCard:cardKey display:newValue];
        }
    }
    
    if (self.orderChanged) {
        NSMutableArray *order = [NSMutableArray array];
        [order addObject:CARD_MEDICAL_LOG];
        [order addObject:CARD_DAILY_LOG];
        [order addObject:CARD_PARTNER_SUMMARY];
        [order addObject:CARD_RATING];
        [order addObject:CARD_RUBY_RECOMMENDATION];
        if (![self canEditImportantTask]) {
            [order addObject:CARD_IMPORTANT_TASK];
        }
        [order addObjectsFromArray:self.order];
        [order addObject:CARD_CUSTOMIZATION];
        
        [[HomeCardCustomizationManager sharedInstance] setOrderOfCards:order];
    }
    
    if (displayChanged || self.orderChanged) {
        [self publish:EVENT_HOME_CARD_CUSTOMIZATION_UPDATED];
    }
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

@end

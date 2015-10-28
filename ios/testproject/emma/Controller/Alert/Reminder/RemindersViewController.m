//
//  RemindersViewController.m
//  emma
//
//  Created by Eric Xu on 7/22/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "RemindersViewController.h"
#import "ReminderDetailViewController.h"
#import "ReminderCell.h"
#import "User.h"
#import "GeniusMainViewController.h"
#import "ReminderHead.h"
#import "PillGradientButton.h"
#import "Logging.h"
#import "UIStoryboard+Emma.h"
#import "Appointment.h"
#import "HealthProfileData.h"
#import "UIView+Emma.h"

#define THUMB_CELL_W GENIUS_SINGLE_BLOCK_TITLE_WIDTH
#define CELL_IDENTIFIER_REMINDER  @"cell"
#define CELL_IDENTIFIER_HISTORY_EXPAND @"more"

@interface ReminderShowHistoryCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *cellView;
@property (weak, nonatomic) IBOutlet UILabel *cellLabel;
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;

@end

@implementation ReminderShowHistoryCell

- (void)awakeFromNib {
    self.cellImage.image = [Utils imageNamed:@"reminder-expand-arrow" withColor:[UIColor colorFromWebHexValue:@"0x4d55c4"]];
    self.cellView.centerX = SCREEN_WIDTH / 2.0;
};

- (void)showMore:(int)more {
    self.cellLabel.text = [NSString stringWithFormat:@"Show %d more", more];
    self.cellImage.transform = CGAffineTransformMakeScale(1, 1);
}

- (void)showHide {
    self.cellLabel.text = @"Show active";
    self.cellImage.transform = CGAffineTransformMakeScale(1, -1);
}

@end


@interface RemindersViewController () <UITableViewDataSource, UITableViewDelegate>
@property UILabel *noActiveReminders;
@property (weak, nonatomic) IBOutlet UIButton *addReminderButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSOrderedSet *reminders;
@property (nonatomic, strong) NSOrderedSet *appointmentHistory;
@property (nonatomic) BOOL showHistory;  // only valid in appointment view
@property (weak, nonatomic) IBOutlet UIButton *addButton;

@end

@implementation RemindersViewController

+ (id)getInstance {
    return [[UIStoryboard storyboardWithName:@"reminder" bundle:nil] instantiateInitialViewController];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
    self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 58, 0);

    NSInteger y = 72;
    _noActiveReminders = [[UILabel alloc] initWithFrame:CGRectMake(10, y, 130, 36)];
    _noActiveReminders.backgroundColor = [UIColor clearColor];
    _noActiveReminders.text = @"No reminders ";
    _noActiveReminders.font = [Utils defaultFont:14];
    _noActiveReminders.textColor = [UIColor whiteColor];
    [self subscribe:EVENT_REMINDERS_ORDER_UPDATED selector:@selector(onRemindersOrderUpdated:)];
    
    self.showHistory = NO;
    
    self.addReminderButton.layer.cornerRadius = self.addReminderButton.height / 2;
    self.addReminderButton.layer.borderColor = [UIColor colorFromWebHexValue:@"aeaeae"].CGColor;
    self.addReminderButton.layer.borderWidth = 1;
   
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadPage];
}

- (void)onRemindersOrderUpdated:(Event *)evt {
    Reminder *r = [Reminder getReminderByUUID:(NSString *)evt.data];
    NSInteger oldIdx = [self.reminders indexOfObject:r];
    NSOrderedSet * newSet = [self.user sortedValidReminders:[self inAppointment]];
    if ([newSet count] != self.reminders.count) {
        // sometimes the number of reminders is changed
        [self reloadPage];
        return;
    } else {
        self.reminders = newSet;
    }
    // r = [self.user getReminder:(NSString *)evt.data];
    NSInteger newIdx = [self.reminders indexOfObject:r];

    [self.tableView moveRowAtIndexPath:[NSIndexPath indexPathForRow:oldIdx inSection:0] toIndexPath:[NSIndexPath indexPathForRow:newIdx inSection:0]];
    /*
    NSInteger rows = [self.reminders count];
    for (NSInteger i = 0; i < rows; i++) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
        if (i > 0 && i % 2 == 1 && self.inFullView) {
            [cell setBackgroundColor:UIColorFromRGB(0x6872DF)];
        } else {
            [cell setBackgroundColor:[UIColor clearColor]];
        }
    }
     */

    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:newIdx inSection:0] atScrollPosition:UITableViewScrollPositionNone animated:YES];
    
    [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.3];
}

- (User *)user
{
    return [User currentUser];
}

- (void)reloadPage {
    self.reminders = [self.user sortedValidReminders:[self inAppointment]];
    //    GLLog(@"sortedReminders: %@", self.model);

    if (self.inAppointment) {
        self.appointmentHistory = [self.user sortedAppointmentHistory];
        [self.addButton setTitle:@"Add new appointment" forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
    
    // in some cases, reminders is changed out this page.
    // we should check if show _noActive view
    if (([[self.user activeReminders:[self inAppointment]] count]) && ([_noActiveReminders superview])){
        [_noActiveReminders removeFromSuperview];
    }
}

#pragma mark - IBOutlet
- (IBAction)addReminder:(id)sender {
    [Logging log:BTN_CLK_GNS_RMD_NEW];
    [self performSegueWithIdentifier:@"detail" sender:self from:self.parentViewController];
}

#pragma mark - open detail page
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ReminderDetailViewController *c = nil;
    if ([segue.destinationViewController isKindOfClass:[ReminderDetailViewController class]]) {
        c = segue.destinationViewController;
    } else if ([segue.destinationViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)segue.destinationViewController).topViewController isKindOfClass:[ReminderDetailViewController class]]){
        c =(ReminderDetailViewController *) ((UINavigationController *)segue.destinationViewController).topViewController;
    }
    if (c) {
        c.isAppointment = [self inAppointment];
        if ([[segue identifier] isEqualToString:@"detail"] && [sender isKindOfClass:[ReminderCell class]]) {
            c.model = [Reminder getReminderByUUID:[(ReminderCell *)sender reminderUUID]];
            [c setShowMed:NO];
        } else {
            [c setModel:nil];
        }
    }
}


- (BOOL)hasShowHistoryCell {
    if ([self inAppointment] && [self.appointmentHistory count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)isShowHistoryCell:(NSInteger)row {
    if (![self hasShowHistoryCell]) {
        return NO;
    }
    if (self.showHistory) {
        return row >= (self.reminders.count + self.appointmentHistory.count);
    } else {
        return row >= self.reminders.count;
    }
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger cnt = [self.reminders count];
    if ([self inAppointment]) {
        if (self.showHistory) {
            cnt += [self.appointmentHistory count];
        }
        if ([self hasShowHistoryCell]) {
            cnt += 1; // for show / hide history
        }
    }
    return cnt;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isShowHistoryCell:indexPath.row]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_HISTORY_EXPAND];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER_HISTORY_EXPAND];
        }
        ReminderShowHistoryCell * hCell = (ReminderShowHistoryCell *)cell;
        if ([self showHistory]) {
            [hCell showHide];
        } else {
            [hCell showMore:[self.appointmentHistory count]];
        }
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_REMINDER];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CELL_IDENTIFIER_REMINDER];
        }
        if ([cell isKindOfClass:[ReminderCell class]]) {
            ReminderCell *rCell = (ReminderCell *)cell;
            if (indexPath.row < self.reminders.count) {
                Reminder * rmd = [self.reminders objectAtIndex:(indexPath.row)];
                [rCell setReminderModel:rmd];
                rCell.userInteractionEnabled = YES;
            } else {
                Appointment * appt = [self.appointmentHistory objectAtIndex:(indexPath.row - self.reminders.count)];
                [rCell setAppointmentModel:appt];
                rCell.userInteractionEnabled = NO;
                [rCell setSelectionStyle:UITableViewCellSelectionStyleNone];
            }
            
            [rCell redrawFullView];
            
        }
        return cell;
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isShowHistoryCell:indexPath.row]) {
        // ReminderShowHistoryCell * cell = (ReminderShowHistoryCell *)[tableView cellForRowAtIndexPath:indexPath];
        self.showHistory = !self.showHistory;
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [tableView reloadData];
        if (!self.showHistory) {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        return;
    } else {
        if (indexPath.row >= [self.reminders count]) {
            return;
        }
        [self performSegueWithIdentifier:@"detail" sender:[self tableView:tableView cellForRowAtIndexPath:indexPath]];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self isShowHistoryCell:indexPath.row]) {
        return 100;
    }
    BOOL hasNote = NO;
    if (indexPath.row < self.reminders.count) {
        Reminder * rmd = [self.reminders objectAtIndex:(indexPath.row)];
        hasNote = [Utils isNotEmptyString:rmd.note];
    } else {
        Appointment * appt = [self.appointmentHistory objectAtIndex:(indexPath.row - self.reminders.count)];
        hasNote = [Utils isNotEmptyString:appt.note];
    }
    return [ReminderCell cellHeight:hasNote];
   
}



- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

@end

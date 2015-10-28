//
//  ReminderCell.m
//  emma
//
//  Created by Eric Xu on 8/4/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ReminderCell.h"
#import "Reminder.h"
#import "User.h"
#import "Logging.h"

@interface ReminderCell() {}

@property (weak, nonatomic) IBOutlet UIView *noteView;
@property (weak, nonatomic) IBOutlet UIImageView *indicatorImageView;
@property (weak, nonatomic) IBOutlet UILabel *noteLabel;

@property (strong, nonatomic) IBOutlet UILabel *reminderTitle;
@property (strong, nonatomic) IBOutlet UILabel *remindingTime;
@property (strong, nonatomic) IBOutlet UISwitch *reminderActive;
@property (weak, nonatomic) IBOutlet UIImageView *modifyIcon;
@property (weak, nonatomic) IBOutlet UIView *cellDivider;

@property (nonatomic) NSString * fullViewTime;
@property (nonatomic) NSString * thumbViewTime;
@property (nonatomic) NSString * reminderNote;

@end

@implementation ReminderCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    
    return self;
}

- (void)awakeFromNib {
    self.frame = setRectWidth(self.frame, SCREEN_WIDTH);
    self.reminderActive.frame = setRectX(self.reminderActive.frame, SCREEN_WIDTH - 70);
    [self.indicatorImageView setImage:[Utils image:self.indicatorImageView.image withColor:UIColorFromRGB(0xffffff)]];
    [self.modifyIcon setImage:[Utils image:self.modifyIcon.image withColor:UIColorFromRGB(0x4d55c4)]];
    self.reminderNote = nil;
};

- (User *)user {
    return [User currentUser];
}

- (IBAction)switched:(id)sender {
    UISwitch *swc = (UISwitch *)sender;
    BOOL on = swc.on;
    if (![Utils isEmptyString:self.reminderUUID]) {
        Reminder *r = [Reminder getReminderByUUID:self.reminderUUID];
        if (r) {
            [r toggleActive:on];
            [self.user save];
            [self publish:EVENT_REMINDERS_ORDER_UPDATED data:self.reminderUUID];
            /*
            [Logging log:BTN_CLK_GNS_RMD_UPDATED
               eventData:@{
                           @"active": @(on? 1: 0),
                           @"repeat": @(r.repeat),
                           @"when": @([[r nextWhen] timeIntervalSince1970]),
                           @"readable_id":[NSString stringWithFormat:@"RMD_%@_%@", r.title, r.uuid]}];
            */
        }
    }
}

- (void)setReminderModel:(Reminder *)model {
    if (model) {
        // TODO
        // model.note = @"this is the test reminder, //super.selected will remove clear background colors of uivew, stop calling it. //super.selected will remove clear background colors of uivew, stop calling it. ";
        
        _reminderUUID = model.uuid;
        _on = model.on;
        _reminderTitle.text = model.title;
        _reminderNote = model.note;
        _fullViewTime = [Utils reminderDateLabel:[model nextWhen]];
        _thumbViewTime = [Utils reminderDateSmallLabel:[model nextWhen]];
        _remindingTime.text = _fullViewTime;
        _noteLabel.text = _reminderNote;
        _reminderActive.hidden = NO;
        _reminderActive.on = model.on;
        _isHistory = NO;
    }
}

- (void)setAppointmentModel:(Appointment *)appointment {
    if (appointment) {
        _reminderUUID = @"";
        _on = NO;
        _reminderTitle.text = appointment.title;
        _reminderNote = appointment.note;
        _fullViewTime = [Utils reminderDateLabel:appointment.date];
        _thumbViewTime = [Utils reminderDateSmallLabel:appointment.date];
        _remindingTime.text = _fullViewTime;
        _noteLabel.text = _reminderNote;
        _reminderActive.hidden = YES;
        _reminderActive.on = NO;
        _isHistory = YES;
    }
}

- (void)redrawFullView {
    self.reminderTitle.font = [Utils semiBoldFont:19];
    self.reminderTitle.frame = CGRectMake(20, 15, SCREEN_WIDTH - 110, 27);
    self.remindingTime.font = [Utils defaultFont:15];
    self.remindingTime.frame = CGRectMake(20, 42, SCREEN_WIDTH - 110, 21);
    self.remindingTime.text = self.fullViewTime;
    self.userInteractionEnabled = YES;
    self.reminderTitle.alpha = 1;
    self.remindingTime.alpha = 1;
    if (self.isHistory) {
        self.modifyIcon.hidden = YES;
    } else {
        self.modifyIcon.hidden = NO;
        [self.remindingTime sizeToFit];
        self.modifyIcon.frame = CGRectMake(self.remindingTime.right + 10, 43, 13, 12);
    }
    self.cellDivider.hidden = NO;
    if ([Utils isEmptyString:self.reminderNote]) {
        self.noteView.hidden = YES;
        self.cellDivider.top = 79;
    } else {
        self.noteView.hidden = NO;
        self.noteView.frame = CGRectMake(20, 63, SCREEN_WIDTH - 40, 70);
        self.noteLabel.frame = CGRectMake(12, 15, SCREEN_WIDTH - 40 - 24, 50);
        self.cellDivider.top = 149;
    }
}

- (void)redrawThumbView:(CGFloat)thumbWidth {
    /*
     if ([[self.user activeReminders:[self inAppointment]] count] == 1 && indexPath.row == 0) {
     if (IS_IPHONE_4) {
     rCell.reminderTitle.frame = CGRectMake(10, 30, THUMB_CELL_W, 21);
     rCell.remindingTime.frame = CGRectMake(10, 10, THUMB_CELL_W, 27);
     } else {
     rCell.reminderTitle.frame = CGRectMake(10, 35, THUMB_CELL_W, 21);
     rCell.remindingTime.frame = CGRectMake(10, 15, THUMB_CELL_W, 27);
     }
     } else {
     rCell.reminderTitle.frame = CGRectMake(10, 20, THUMB_CELL_W, 21);
     rCell.remindingTime.frame = CGRectMake(10, 0, THUMB_CELL_W, 27);
     }
     */
    self.reminderTitle.font = [Utils defaultFont:12];
    self.remindingTime.font = [Utils boldFont:16];
    self.remindingTime.text = self.thumbViewTime;
    self.reminderTitle.frame = CGRectMake(10, 20, thumbWidth, 21);
    self.remindingTime.frame = CGRectMake(10, 0, thumbWidth, 27);
    self.userInteractionEnabled = NO;
    self.reminderTitle.alpha = self.on ? 1: 0;
    self.remindingTime.alpha = self.on ? 1: 0;
    self.modifyIcon.hidden = YES;
    self.noteView.hidden = YES;
    self.cellDivider.hidden = YES;
}

+ (CGFloat)cellHeight:(BOOL)hasNote {
    return hasNote ? 150 : 80;
}

@end

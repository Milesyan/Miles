//
//  MedicalLogBinaryCell.m
//  emma
//
//  Created by Peng Gu on 10/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//


#import "MedicalLogBinaryCell.h"
#import <GLFoundation/GLGeneralPicker.h>


@interface MedicalLogBinaryCell ()

@end


@implementation MedicalLogBinaryCell


- (IBAction)checkButtonClicked:(id)sender
{
    if (self.checkButtonAction) {
        PillButton *button = (PillButton *)sender;
        self.checkButtonAction(button.selected);
    }
}


- (IBAction)crossButtonClicked:(id)sender
{
    if (self.crossButtonAction) {
        PillButton *button = (PillButton *)sender;
        self.crossButtonAction(button.selected);
    }
}


- (void)configureCheckButton:(PillButton *)checkButton
                 crossButton:(PillButton *)crossButton
                    withItem:(MedicalLogItem *)item
{
    [checkButton setSelected:NO animated:NO];
    [crossButton setSelected:NO animated:NO];
    
    if (item.logValue.integerValue == BinaryValueTypeYes) {
        [checkButton setSelected:YES animated:NO];
    }
    else if (item.logValue.integerValue == BinaryValueTypeNo) {
        [crossButton setSelected:YES animated:NO];
    }
}


- (void)configurePickerButton:(PillButton *)button forItem:(MedicalLogItem *)item
{
    if (!button || !item) {
        return;
    }
    
//    [button setLabelText:item.valueDescription bold:YES];
    [button setSelected:item.logValue ? YES : NO];
}


- (void)refreshPickerButtonsForItem:(MedicalLogItem *)item
{
    
}


- (void)configureWithItem:(MedicalLogItem *)item atIndexPath:(NSIndexPath *)indexPath
{
    self.medicalLogItem = item;
    self.backgroundColor = indexPath.row % 2 ? UIColorFromRGB(0xF6F5EF) : UIColorFromRGB(0xFBFAF7);
    self.indexPath = indexPath;
    
    [self configureCheckButton:self.checkButton crossButton:self.crossButton withItem:item];
    
    __weak typeof(self)weakSelf = self;
    self.checkButtonAction = ^(BOOL selected) {
        BinaryValueType type = selected ? BinaryValueTypeYes : BinaryValueTypeNone;
        [weakSelf updateBinaryValue:type forItem:item needReloadCell:NO needUpdateHeight:YES];
        
        [weakSelf logButtonClickWithItem:item
                               clickType:selected ? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT
                                   value:type];
        
        [weakSelf.crossButton setSelected:NO animated:NO];
        [weakSelf refreshPickerButtonsForItem:item];
    };
    
    self.crossButtonAction = ^(BOOL selected) {
        BinaryValueType type = selected ? BinaryValueTypeNo : BinaryValueTypeNone;
        [weakSelf updateBinaryValue:type forItem:item needReloadCell:NO needUpdateHeight:YES];
        
        [weakSelf logButtonClickWithItem:item
                               clickType:selected ? CLICK_TYPE_NO_SELECT : CLICK_TYPE_NO_UNSELECT
                                   value:type];
        
        [weakSelf.checkButton setSelected:NO animated:NO];
        [weakSelf refreshPickerButtonsForItem:item];
    };
}


- (void)updateBinaryValue:(BinaryValueType)valueType
                  forItem:(MedicalLogItem *)item
           needReloadCell:(BOOL)reloadCell
         needUpdateHeight:(BOOL)needUpdateHeight
{
    
}


- (void)presentPickerForItem:(MedicalLogItem *)item
{
}


- (void)logButtonClickWithItem:(MedicalLogItem *)item clickType:(NSString *)clickType value:(NSInteger)value
{
    NSString *name = item.isMedicationItem ? kMedItemMedication : item.key;
    NSString *info = item.isMedicationItem ? item.name : @"";
    
    [self logButtonClickWithName:name
                       clickType:clickType
                           value:value
                       dailytime:(int64_t)[item.nsdate timeIntervalSince1970]
                  additionalInfo:info];
}


- (void)logButtonClickWithName:(NSString *)name
                     clickType:(NSString *)clickType
                         value:(NSInteger)value
                     dailytime:(NSInteger)timeInterval
                additionalInfo:(NSString *)info
{
    NSDictionary *data = @{
                           @"medical_log_name": name,
                           @"click_type": clickType,
                           @"select_value": @(value),
                           @"daily_time": @(timeInterval),
                           @"additional_info": info };
    [Logging log:BTN_CLK_MEDICAL_LOG_ITEM eventData:data];
}





@end






//
//  MedicalLogBinaryCell.h
//  emma
//
//  Created by Peng Gu on 10/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MedicalLogItem.h"
#import "PillButton.h"
#import "UILinkLabel.h"

@class MedicalLogBinaryCell;


@protocol MedicalLogBinaryCellDelegate <NSObject>

- (void)medicalLogBinaryCell:(MedicalLogBinaryCell *)cell
              didUpdateValue:(NSString *)value
                      forKey:(NSString *)key
              needReloadCell:(BOOL)needReload
            needUpdateHeight:(BOOL)needUpdateHeight;

@end


typedef void (^SelectButtonClickActionBlock)(BOOL selected);
typedef void (^PickButtonClickActionBlock)();


@interface MedicalLogBinaryCell : UITableViewCell
@property (nonatomic, strong) MedicalLogItem *medicalLogItem;
@property (weak, nonatomic) IBOutlet UILinkLabel *titleLabel;
@property (weak, nonatomic) IBOutlet PillButton *checkButton;
@property (weak, nonatomic) IBOutlet PillButton *crossButton;

@property (nonatomic, copy) SelectButtonClickActionBlock checkButtonAction;
@property (nonatomic, copy) SelectButtonClickActionBlock crossButtonAction;

@property (nonatomic, strong) NSIndexPath *indexPath;
@property (nonatomic, weak) id<MedicalLogBinaryCellDelegate> delegate;

- (void)configureWithItem:(MedicalLogItem *)item atIndexPath:(NSIndexPath *)indexPath;
- (void)configurePickerButton:(PillButton *)button forItem:(MedicalLogItem *)item;
- (void)configureCheckButton:(PillButton *)checkButton
                 crossButton:(PillButton *)crossButton
                    withItem:(MedicalLogItem *)item;

- (void)updateBinaryValue:(BinaryValueType)valueType
                  forItem:(MedicalLogItem *)item
           needReloadCell:(BOOL)reloadCell
         needUpdateHeight:(BOOL)needUpdateHeight;

- (void)presentPickerForItem:(MedicalLogItem *)item;

- (void)refreshPickerButtonsForItem:(MedicalLogItem *)item;

- (IBAction)checkButtonClicked:(id)sender;
- (IBAction)crossButtonClicked:(id)sender;

- (void)logButtonClickWithItem:(MedicalLogItem *)item
                     clickType:(NSString *)clickType
                         value:(NSInteger)value;

- (void)logButtonClickWithName:(NSString *)name
                     clickType:(NSString *)clickType
                         value:(NSInteger)value
                     dailytime:(NSInteger)timeInterval
                additionalInfo:(NSString *)info;

@end

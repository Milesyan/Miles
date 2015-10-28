//
//  MedicineViewController.h
//  emma
//
//  Created by Eric Xu on 12/30/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "MedManager.h"

#define USERDEFAULTS_NEW_MED @"newMed"

@protocol MedicineViewControllerDelegate <NSObject>

@optional
- (void)afterMedicineViewWillDisappear;
- (void)afterMedicineViewDidDisappear;
- (void)onConfirmDeleteMed:(NSString *)medName;
- (void)medicineViewControllerDidAddNewMedicationWithName:(NSString *)medName;
- (void)medicineViewControllerDidUpdateMedicationWithName:(NSString *)medName;

@end

@interface MedicineViewController : UITableViewController

@property (nonatomic, weak) id<MedicineViewControllerDelegate> delegate;
@property (nonatomic, assign) BOOL isFromMedicalLog;
@property (nonatomic, assign) BOOL isEditingMedication;

- (void)setMedicineNameFromSearch:(NSString *)medName;
- (void)setModel:(Medicine *)model;
@end

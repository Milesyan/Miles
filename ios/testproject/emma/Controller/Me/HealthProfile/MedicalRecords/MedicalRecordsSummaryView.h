//
//  MedicalRecordsView.h
//  emma
//
//  Created by ltebean on 15-2-2.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MedicalRecordsDataManager.h"

@class MedicalRecordsSummaryView;

@protocol MedicalRecordsSummaryViewDelegate<NSObject>
- (void)medicalRecordsSummaryView:(MedicalRecordsSummaryView *)summaryView didSelectType:(NSString *)type;
- (void)medicalRecordsSummaryViewNeedsConnectHumanAPI:(MedicalRecordsSummaryView *)summaryView;
@end

@interface MedicalRecordsSummaryView : UIView
@property (nonatomic,strong) NSDictionary* summaryData;
@property (nonatomic,weak) id<MedicalRecordsSummaryViewDelegate>delegate;
- (void)showFetchingDataCover;
- (void)startAnimatingFetchingDataLabel;
- (void)stopAnimatingFetchingDataLabel;
@end

//
//  MedicalRecordsView.m
//  emma
//
//  Created by ltebean on 15-2-2.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "MedicalRecordsSummaryView.h"
#import "MedicalRecordsSummaryCell.h"
#import "UIImage+blur.h"
#import "UIButton+BackgroundColor.h"

#define FETCHING_DATA_LABEL_ANIMATION_SEQUENCE @[@"Fetching your data",@"Fetching your data.",@"Fetching your data..",@"Fetching your data..."]

@interface MedicalRecordsSummaryView()<UITableViewDataSource,UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIView *connectCoverView;
@property (weak, nonatomic) IBOutlet UIView *fetchingDataCoverView;
@property (weak, nonatomic) IBOutlet UILabel *fetchingDataLabel;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic) NSInteger fetchingDataLabelAnimationFrame;
@property (nonatomic) BOOL disableAnimatingFetchingDataLabel;
@end

@implementation MedicalRecordsSummaryView

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [[NSBundle mainBundle] loadNibNamed:@"MedicalRecordsSummaryView" owner:self options:nil];
        self.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
        self.containerView.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        [self addSubview: self.containerView];
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
    [self.tableView registerNib:[UINib nibWithNibName:@"MedicalRecordsSummaryCell" bundle:nil] forCellReuseIdentifier:@"MedicalRecordsCell"];
    
    self.connectButton.layer.cornerRadius = self.connectButton.height / 2;
    self.connectButton.layer.masksToBounds = YES;
    
    [self.connectButton setBackgroundColor:[UIColor colorFromWebHexValue:@"3F47AE"] forState:UIControlStateHighlighted];
  
}

- (void)setSummaryData:(NSDictionary *)summaryData
{
    _summaryData = summaryData;
    self.fetchingDataCoverView.hidden = YES;
    if (!summaryData) {
        self.connectCoverView.hidden = NO;
    } else {
        [self.tableView reloadData];
        self.connectCoverView.hidden = YES;
    }
}

- (void)showFetchingDataCover
{
    self.fetchingDataCoverView.hidden = NO;
    self.fetchingDataCoverView.alpha = 0;
    self.connectCoverView.alpha = 1;
    [UIView animateWithDuration:0.2 animations:^{
        self.fetchingDataCoverView.alpha = 1;
        self.connectCoverView.alpha = 0;
    } completion:^(BOOL finished) {
        self.connectCoverView.hidden = YES;
        self.connectCoverView.alpha = 1;
        [self startAnimatingFetchingDataLabel];
    }];
}

- (void)startAnimatingFetchingDataLabel
{
    self.fetchingDataLabelAnimationFrame = 0;
    self.disableAnimatingFetchingDataLabel = NO;
    [self animatingFetchingDataLabel];
}

- (void)stopAnimatingFetchingDataLabel
{
    self.disableAnimatingFetchingDataLabel = YES;
}

- (void)animatingFetchingDataLabel
{
    if (self.disableAnimatingFetchingDataLabel) {
        return;
    }
    
    self.fetchingDataLabel.text = FETCHING_DATA_LABEL_ANIMATION_SEQUENCE[self.fetchingDataLabelAnimationFrame];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.fetchingDataLabelAnimationFrame ++;
        if (self.fetchingDataLabelAnimationFrame == FETCHING_DATA_LABEL_ANIMATION_SEQUENCE.count) {
            self.fetchingDataLabelAnimationFrame = 0;
        }
        [self animatingFetchingDataLabel];
    });
}

#pragma mark UITableViewDatasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MedicalRecordsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"Allergies";
        cell.detailTextLabel.text = [self textForMedicalRecordType:TYPE_ALLERGIES];
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"Immunizations";
        cell.detailTextLabel.text = [self textForMedicalRecordType:TYPE_IMMUNIZATIONS];
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Medications";
        cell.detailTextLabel.text = [self textForMedicalRecordType:TYPE_MEDICATIONS];
    }
    return cell;
}


#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self.delegate medicalRecordsSummaryView:self didSelectType:TYPE_ALLERGIES];
    } else if (indexPath.row == 1) {
        [self.delegate medicalRecordsSummaryView:self didSelectType:TYPE_IMMUNIZATIONS];
    } else if (indexPath.row == 2) {
        [self.delegate medicalRecordsSummaryView:self didSelectType:TYPE_MEDICATIONS];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark IBAction
- (IBAction)connectButtonPressed:(id)sender
{
    [self.delegate medicalRecordsSummaryViewNeedsConnectHumanAPI:self];
}

#pragma mark helper
- (NSString *)textForMedicalRecordType:(NSString *)type
{
    if (!self.summaryData) {
        return @" ";
    }
    NSNumber *data = self.summaryData[type];
    if (!data || [data isEqualToNumber:@0]) {
        return @"N/A";
    }
    return [data stringValue];
}
@end

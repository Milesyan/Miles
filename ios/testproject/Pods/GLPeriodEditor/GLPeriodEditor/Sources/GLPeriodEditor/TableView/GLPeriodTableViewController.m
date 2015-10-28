//
//  GLPeriodTableViewController.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-23.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLPeriodTableViewController.h"
#import "GLPeriodCell.h"
#import "GLPeriodEditorHeader.h"
#import <GLFoundation/GLMarkdownLabel.h>
#import <GLFoundation/GLTheme.h>
#import "GLDateUtils.h"
#import "GLPeriodEditorHeader.h"

static const CGFloat SECTION_HEADER_HEIGHT = 24;

@interface GLPeriodTableViewController () <UITableViewDataSource, UITableViewDelegate, GLPeriodCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *topLabel1;
@property (weak, nonatomic) IBOutlet GLMarkdownLabel *topLabel2;
@property (nonatomic, strong) NSMutableDictionary *sections;
@property (nonatomic, strong) NSArray *sortedYears;
@property (nonatomic) BOOL isAnimating;
@end

@implementation GLPeriodTableViewController

+ (instancetype)instance
{
    return [[UIStoryboard storyboardWithName:@"GLPeriodEditor" bundle:nil] instantiateViewControllerWithIdentifier:@"GLPeriodTableViewController"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tableTapped:)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self subscribe:EVENT_PERIOD_EDITOR_TABLEVIEW_NEEDS_RELOAD selector:@selector(reloadData)];
    [self reloadData];
}

- (void)tableTapped:(UITapGestureRecognizer *)tap
{
    [self publish:EVENT_PERIOD_EDITOR_TABLE_CELL_SHOULD_BACK_TO_NORMAL];
}

- (void)reloadData
{
    if (self.cycleDataList.count == 0) {
        return;
    }
    
    NSInteger totalCount = self.cycleDataList.count;
    CGFloat totalPeriodLength = 0;
    NSInteger validDataCount = 0;
    self.sections = [NSMutableDictionary dictionary];
    for (NSInteger i = totalCount - 1; i >= 0; i--) {
        GLCycleData *cycleData = self.cycleDataList[i];
        if (!cycleData.periodBeginDate || !cycleData.periodEndDate) {
            continue;
        }
        if (cycleData.showAsPrediction) {
            continue;
        }
        NSDateComponents *date = [[GLDateUtils calendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:cycleData.periodBeginDate];
        
        if (cycleData.isFuture) {
            static NSDateFormatter *dateFormatter;
            if (!dateFormatter)
            {
                dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.locale = [NSLocale currentLocale];
                dateFormatter.dateFormat = [NSDateFormatter dateFormatFromTemplate:@"MMMd" options:0 locale:dateFormatter.locale];
            }
            self.topLabel1.markdownText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Next period starts on: **%@**", @"GLPeriodEditorLocalizedString", nil) , [dateFormatter stringFromDate:cycleData.periodBeginDate]];
            break;
        }
        
        validDataCount ++;
        NSMutableArray *dataList = self.sections[@(date.year)];
        if (!dataList) {
            dataList = [NSMutableArray array];
            self.sections[@(date.year)] = dataList;
        }
        [dataList addObject:cycleData];
        
        totalPeriodLength += cycleData.periodLength;
        
        GLCycleData *nextCycleData = (i - 1 >= 0) ? self.cycleDataList[i - 1] : nil;
        if (nextCycleData && !nextCycleData.isFuture) {
            cycleData.cycleLength = [GLDateUtils daysBetween:cycleData.periodBeginDate and:nextCycleData.periodBeginDate];
        } else {
            cycleData.cycleLength = -1;
        }
    }
    
    // if no future data
    if (validDataCount == self.cycleDataList.count) {
        self.topLabel1.markdownText = NSLocalizedStringFromTable(@"Next period starts on: **-**", @"GLPeriodEditorLocalizedString", nil);
    }
    
    NSInteger averagePeriodLength = validDataCount == 0 ? 0 : round(totalPeriodLength / validDataCount);
    self.topLabel2.markdownText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Average period length: **%ld** days", @"GLPeriodEditorLocalizedString", nil), (long)averagePeriodLength];
    
    
    self.sortedYears = [self.sections.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj2 compare:obj1];
    }];
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSNumber *year = self.sortedYears[section];
    return [self.sections[year] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    GLPeriodCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    if (indexPath.row % 2 == 0) {
        cell.contentView.backgroundColor = [UIColor whiteColor];
    } else {
        cell.contentView.backgroundColor = UIColorFromRGB(0xf8f8f8);
    }
    cell.delegate = self;
    if (indexPath.row == 0 && indexPath.section == 0) {
        cell.allowDeletion = NO;
    } else {
        cell.allowDeletion = YES;
    }
    
    NSArray *cycles = self.sections[self.sortedYears[indexPath.section]];
    GLCycleData *cycleDate = cycles[cycles.count - indexPath.row - 1];
    cell.cycleData = cycleDate;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return SECTION_HEADER_HEIGHT;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, SECTION_HEADER_HEIGHT)];
    header.backgroundColor = UIColorFromRGB(0xf1f1f1);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, SECTION_HEADER_HEIGHT)];
    label.left = 15;
    label.font = [GLTheme defaultFont:14];
    NSNumber *year = self.sortedYears[section] ;
    label.text = [NSString stringWithFormat:@"%@", [year stringValue]];
    label.textColor = UIColorFromRGB(0x666666);
    
    [header addSubview:label];
    return header;
}

- (void)periodCell:(GLPeriodCell *)cell needsDeleteCycleData:(GLCycleData *)cycleData
{
    if (self.isAnimating) {
        return;
    }
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) {
        return;
    }
    
    // update model
    NSDateComponents *date = [[GLDateUtils calendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:cycleData.periodBeginDate];
    NSMutableArray *cycles = self.sections[@(date.year)];
    [cycles removeObject:cycleData];
    
    // row animation
    self.isAnimating = YES;
    self.mode = MODE_EDITING;
    [CATransaction begin];
    [CATransaction setCompletionBlock: ^{
        [self removeCycleData:cycleData];
        [self publish:EVENT_PERIOD_EDITOR_CALENDAR_VIEW_NEEDS_RELOAD];
        [self publish:EVENT_PERIOD_EDITOR_INDICATE_CAN_RELOAD_DATA];
        self.isAnimating = NO;
        self.mode = MODE_NORMAL;
    }];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    [CATransaction commit];
    
    [self sendLoggingEvent:BTN_CLK_LIST_VIEW_PERIOD_DEL data:cycleData];
}

- (void)periodCell:(GLPeriodCell *)cell didWantToDeleteTheLatestCycle:(GLCycleData *)cycleData
{
    [self.containerViewController didWantToDeleteTheLatestCycle];
}

@end

//
//  DailyLogCellTypeTest.m
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "DailyLogCellTypeTest.h"
#import "PillButton.h"
#import "Logging.h"
#import "TestkitBrandPicker.h"
#import "UserDailyData.h"


#define BRAND_WIDTH_DEFAULT 126
#define BRAND_X_DEFAULT 174
#define BRAND_WIDTH_LONG 166
#define BRAND_X_LONG 134
#define BRAND_Y 15
#define BRAND_HEIGHT 36

#define BUTTON_Y 100
#define BUTTON_HEIGHT 35


@interface DailyLogCellTypeTest() <UIActionSheetDelegate, TestkitBrandPickerDelegate>{
    NSArray *brands;
    NSArray *brandsSize;
    NSArray *buttonsImage;
    NSArray *buttonsTitle;
    NSArray *buttonsPosition;
    NSInteger brandIndexOther;
    NSInteger brandIndex;
    TestkitBrandPicker *brandPicker;
}

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *buttonWidthConstraint;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftButtonConstraintWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leftButtonConstraintCenter;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightButtonConstraintWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *rightButtonConstraintCenter;

@end

@implementation DailyLogCellTypeTest

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    GLLog(@"datakey:%@ brandButton:%@", self.dataKey, brandButton);
    if (button3) {
        exclusiveButtons = @[button1, button2, button3];
    } else {
        exclusiveButtons = @[button1, button2];
    }

    brandIndex = -1;
    [brandButton setLabelText:@"Pick brand" bold:YES];
}

- (void)setValue:(NSObject *)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];
    GLLog(@"self.dataKey: %@, self.value: %@", self.dataKey, value);

    NSInteger val = [(NSNumber *)value integerValue];

    if (val > 0){
        NSInteger testValue = val % BRAND_MASK;
        brandIndex = val/BRAND_MASK;

        if (brandIndex == 0 || brandIndex >=[brands count]) {
            brandIndex = brandIndexOther;
        } else {
            brandIndex -= 1;
        }
        [self updateBrand:brandIndex
                withValue:testValue];
        [brandButton setSelected:YES animated:NO];
    }
    
    GLLog(@"brandIndex: %d", brandIndex);
}

- (void)setDataKey:(NSString *)dataKey {
    [super setDataKey:dataKey];

    if ([self.dataKey isEqual:DL_CELL_KEY_OVTEST]) {
        brands = @[@"Clearblue Digital",
                   @"Clearblue Easy Read",
                   @"First Response Digital",
                   @"First Response Fertility",
                   @"Others"];
        brandsSize = @[@[@160, @140],//x, width
                       @[@145, @155],
                       @[@134, @166],
                       @[@134, @166],//134, 166
                       @[@174, @126]//174, 126
                       ];
        buttonsImage = @[
                        @[@"clearblue-peak", @"clearblue-low", @"clearblue-high"],
                        @[@"clearblue-high", @"clearblue-low"],
                        @[@"firstresponse-serge", @"firstresponse-noserge"],
                        @[@"firstresponse-pregnant", @"firstresponse-notpregnant"],
                        @[@"firstresponse-pregnant", @"firstresponse-notpregnant"]
                        ];
        buttonsTitle = @[
                         @[@"Peak  ", @"Low   ", @"High "],
                         @[@"LH surge ", @"No LH surge  "],
                         @[@"LH surge  ", @"No LH surge  "],
                         @[@"LH surge  ", @"No LH surge  "],
                         @[@"LH surge  ", @"No LH surge  "]
                         ];
        buttonsPosition = @[@[@[@210, @90], @[@20, @90], @[@115, @90]],
                            @[@[@165, @135], @[@20, @135]],
                            @[@[@165, @135], @[@20, @135]],
                            @[@[@165, @135], @[@20, @135]],
                            @[@[@165, @135], @[@20, @135]],
                            ];

        brandIndexOther = 4;
    } else if ([self.dataKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
        brands = @[@"Clearblue Digital",
                   @"Clearblue",
                   @"First Response Gold",
                   @"First Response",
                   @"Others"];
        brandsSize = @[@[@160, @140],//x, width
                       @[@174, @126],
                       @[@140, @160],
                       @[@174, @126],//134, 166
                       @[@174, @126]//174, 126
                       ];
        buttonsImage = @[
                         @[@"clearblue-pregnant", @"clearblue-notpregnant"],
                         @[@"clearblue-pregnant", @"clearblue-notpregnant"],
                         @[@"firstresponse-pregnant", @"firstresponse-notpregnant"],
                         @[@"firstresponse-pregnant", @"firstresponse-notpregnant"],
                         @[@"firstresponse-pregnant", @"firstresponse-notpregnant"]
                         ];
        buttonsTitle = @[
                         @[@"Pregnant   ", @"Not pregnant  "],
                         @[@"Pregnant   ", @"Not pregnant  "],
                         @[@"Yes   ", @"No   "],
                         @[@"Pregnant   ", @"Not pregnant  "],
                         @[@"Pregnant   ", @"Not pregnant  "]
                         ];
        buttonsPosition = @[@[@[@20, @135], @[@165, @135]],
                            @[@[@20, @135], @[@165, @135]],
                            @[@[@20, @135], @[@165, @135]],
                            @[@[@20, @135], @[@165, @135]],
                            @[@[@20, @135], @[@165, @135]]
                            ];
        brandIndexOther = 4;
    }
}

- (void)updateBrand:(NSInteger)brandIdx withValue:(NSInteger)val
{
    GLLog(@"updateBrand: %d val:%d", brandIdx, val);

    BOOL showButton3 = brandIdx == 0 && [buttonsImage[0] count] >= 3 && [buttonsPosition[0] count] >= 3;
    button3.hidden = !showButton3;
    
    //Change brandButton title
    NSString *brand = brands[brandIdx];
    [brandButton setLabelText:brand bold:YES];
    self.buttonWidthConstraint.constant = [brandsSize[brandIdx][1] integerValue];

    //Change button1/2/3 icon, title, frame, selection
    //icons
    NSArray *icons = (NSArray *)buttonsImage[brandIdx];
    [button1 setIconName:icons[0]];
    [button2 setIconName:icons[1]];
    if (button3 && !(button3.hidden) &&[icons count] >=3) {
        [button3 setIconName:icons[2]];
    }

    //titles
    NSArray *titles = (NSArray *)buttonsTitle[brandIdx];
    [button1 setLabelText:titles[0] bold:NO];
    [button2 setLabelText:titles[1] bold:NO];
    if (button3 && !(button3.hidden) &&[titles count] >=3) {
        [button3 setLabelText:titles[2] bold:NO];
    }
    
    //frames
    NSArray *frames = (NSArray *)buttonsPosition[brandIdx];
    self.leftButtonConstraintCenter.constant = 10;
    self.rightButtonConstraintCenter.constant = 10;
    self.leftButtonConstraintWidth.constant = 135;
    self.rightButtonConstraintWidth.constant = 135;
    
    if (button3 && !(button3.hidden) && [frames count] >= 3) {
        self.leftButtonConstraintCenter.constant = (IS_IPHONE_6_PLUS ? 80 : (IS_IPHONE_6 ? 70 : 60));
        self.rightButtonConstraintCenter.constant = (IS_IPHONE_6_PLUS ? 80 : (IS_IPHONE_6 ? 70 : 60));
        self.leftButtonConstraintWidth.constant = 90;
        self.rightButtonConstraintWidth.constant = 90;
    }

    //selection
    button1.selected = val == LOG_VAL_POSITIVE;
    button2.selected = val == LOG_VAL_NEGATIVE;
    if (button3 && !(button3.hidden)) {
        button3.selected = val == LOG_VAL_MEDIUM;
    }

    brandIndex = brandIdx;
}

- (IBAction)buttonTouched:(id) sender {
    PillButton *button = (PillButton *)sender;
    GLLog(@"button.font:%@", button.titleLabel.font);
    GLLog(@"button touched: ^%@", sender);
    
    for (PillButton *b in exclusiveButtons) {
        if (b != button && b.selected) {
            [b setSelected:NO animated:NO];
        }
    }

    // click type and click value for logging
    NSString * clickType = button.selected? CLICK_TYPE_YES_SELECT : CLICK_TYPE_YES_UNSELECT;
    NSInteger val = 0;
    for (UIButton *b in exclusiveButtons) {
        val = val + (b.selected? b.tag : 0);
    };
    
    if ([self.dataKey isEqual:DL_CELL_KEY_OVTEST]) {
        [self logButton:BTN_CLK_HOME_OV_TEST_TYPE
              clickType:clickType
              eventData:@{@"value": @(val)}];
    } else if([self.dataKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
        [self logButton:BTN_CLK_HOME_PREG_TEST_TYPE
              clickType:clickType
              eventData:@{@"value": @(val)}];
    }

    [self.delegate findAndResignFirstResponder];
    [self updateData];
}


- (IBAction)brandTouched:(id)sender
{
    if ([brands count] > 0) {
        brandPicker = [[TestkitBrandPicker alloc] init];
        brandPicker.delegate = self;
        [brandPicker presentWithBrands:brands selection:brandIndex];
        [self publish:EVENT_BRAND_PICKER_DID_SHOW data:self.dataKey];
    }
    
    [brandButton setSelected:YES animated:NO];
}

- (void)updateData {
    NSInteger i = 0;
    for (UIButton *b in exclusiveButtons) {
        i = i + (b.selected? b.tag : 0);
    }
    [self.delegate updateDailyData:self.dataKey withValue:@(i + BRAND_MASK * (brandIndex + 1))];
}

#pragma mark - TestkitBrandPickerDelegate
- (void)testkitBrandPicker:(TestkitBrandPicker *)picker didDismissWithBrandIndex:(NSInteger)brandIdx
{
    GLLog(@"testkitpicker dissmissed, with brandindex:%d", brandIdx);
    NSString *brand = brands[brandIdx];
    GLLog(@"idx:%d val:%@", brandIdx, brand);
    [brandButton setTitle:brand forState:UIControlStateNormal];

    [self updateBrand:brandIdx withValue:0];
    [self updateData];

    [brandButton setSelected:YES animated:NO];
    
    // brand index, 0 = start over, 1 ... 5 = brands
    if ([self.dataKey isEqual:DL_CELL_KEY_OVTEST]) {
        [self logButton:BTN_CLK_HOME_NEW_OV_TEST
              clickType:CLICK_TYPE_NONE
              eventData:@{@"brand_index": @(brandIdx+1)}];
    } else if([self.dataKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
        [self logButton:BTN_CLK_HOME_NEW_PREG_TEST
              clickType:CLICK_TYPE_NONE
              eventData:@{@"brand_index": @(brandIdx+1)}];
    }
    
    [self publish:EVENT_BRAND_PICKER_DID_HIDE];
}

- (void)testkitBrandPickerDidDismissWithCancelButton:(TestkitBrandPicker *)picker
{
    GLLog(@"testkitpicker dissmissed, cancel, nothing happens. %d", brandIndex);
    if (brandIndex == -1) {
        [brandButton setSelected:NO animated:YES];
    }

    [self publish:EVENT_BRAND_PICKER_DID_HIDE];
}

- (void)testkitBrandPickerDidDismissWithStartOverButton:(TestkitBrandPicker *)picker
{
    GLLog(@"testkitpicker dissmissed, startover");
    button1.selected = NO;
    button2.selected = NO;
    if (button3) {
        button3.selected = NO;
    }
    
    brandIndex = -1;
    [self updateData];
    
    [brandButton setSelected:NO animated:NO];
    [brandButton setLabelText:@"Pick brand" bold:YES];
    self.buttonWidthConstraint.constant = BRAND_WIDTH_DEFAULT;

    if ([self.dataKey isEqual:DL_CELL_KEY_OVTEST]) {
        [self logButton:BTN_CLK_HOME_NEW_OV_TEST
              clickType:CLICK_TYPE_NONE
              eventData:@{@"brand_index": @(0)}];
    } else if([self.dataKey isEqual:DL_CELL_KEY_PREGNANCYTEST]) {
        [self logButton:BTN_CLK_HOME_NEW_PREG_TEST
              clickType:CLICK_TYPE_NONE
              eventData:@{@"brand_index": @(0)}];
    }
    
    [self publish:EVENT_BRAND_PICKER_DID_HIDE];
}

- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)cellHeight {
    [super enterEditingVisibility:visible height:cellHeight];
    [brandButton setAlpha:0];
}

- (void)exitEditing {
    [super exitEditing];
    [brandButton setAlpha:1];
}
@end

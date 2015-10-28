//
//  DailyLogCellTypeDigital.m
//  emma
//
//  Created by Eric Xu on 2/20/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DailyLogCellTypeDigital.h"
#import "PillButton.h"
#import "DailyLogViewController.h"
#import "Logging.h"
#import "UserDailyData.h"
#import "InputAccessoryView.h"

#define BUTTON_WIDTH 36
#define BUTTON_PADDING 10
#define UNIT_LABEL_TAG 99

@interface DailyLogCellTypeDigital() <UIActionSheetDelegate, UITextFieldDelegate>
{
    float digitalCopy;
    BOOL digitalSelected;
    NSNumberFormatter *numberFormatter;
}

@property NSTimer *timer;

@property UITextField *hiddenTextField;
@property NSString *editCopy;

@property (nonatomic) float digital;
@property (nonatomic) float initialValue;
@property (nonatomic, strong) NSString *unit;
@property (nonatomic, strong) NSDictionary *units;
@property (nonatomic, strong) NSDictionary *range;
@property (nonatomic, strong) NSDictionary *initial;
@property (nonatomic, strong) NSDictionary *convertionFunction;
@property (nonatomic, strong) NSString *serverUnit;
@property (nonatomic) BOOL inAnimation;

@end


@implementation DailyLogCellTypeDigital


- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)setup {
    numberFormatter = [[NSNumberFormatter alloc] init];
    numberFormatter.minimumFractionDigits = 1;
    numberFormatter.maximumFractionDigits = 2;
    numberFormatter.roundingMode = NSNumberFormatterRoundHalfUp;
    numberFormatter.locale = [NSLocale currentLocale];
    
    self.hiddenTextField = [[UITextField alloc] initWithFrame:CGRectZero];
    [self.hiddenTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    [self.hiddenTextField setDelegate:self];
    [self addSubview:self.hiddenTextField];
    
    InputAccessoryView *view = (InputAccessoryView *)[[[NSBundle mainBundle] loadNibNamed:@"TextFieldInputAccessoryView" owner:self options:nil] objectAtIndex:0];
    self.hiddenTextField.inputAccessoryView = view;
    
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(textChanged:)
        name:UITextFieldTextDidChangeNotification
        object:self.hiddenTextField];
    
    @weakify(self)
    [self subscribe:EVENT_KEYBOARD_DISMISSED handler:^(Event *event){
        @strongify(self)
        id firstResponder = [event data];
        if (firstResponder && firstResponder == self.hiddenTextField) {
            [self commitInput];
        }
    }];
    
    [self subscribe:EVENT_KBINPUT_DONE handler:^(Event *event){
        @strongify(self)
        if (self && self.hiddenTextField.isFirstResponder) {
            [self.hiddenTextField resignFirstResponder];
            [self commitInput];
        }
    }];
    
    [self subscribe:EVENT_KBINPUT_UNIT_SWITCH handler:^(Event *event){
        @strongify(self)
        if (self && self.hiddenTextField.isFirstResponder) {
            NSInteger index = [(NSNumber *)event.data integerValue];
            NSString *unit = self.units.allValues[index];
            [self.unitButton setSelected:YES];
            _unit = unit;
            
            if (![unit isEqualToString:self.unitButton.titleLabel.text]) {
                //
                if (self.convertionFunction) {
                    float newDigital = [Utils convertTemperature:self.digital
                            toUnit:unit];
                    self.digital = newDigital;
                    
                    [self.unitButton setLabelText:unit bold:YES];
                    self.initialValue = [[_initial objectForKey:_unit] floatValue];
                    
                    [Utils setDefaultsForKey:([self.dataKey isEqualToString:DL_CELL_KEY_BBT]? kUnitForTemp: kUnitForWeight) withValue:unit];
                }
                
            }
        }
    }];
    
    [self subscribe:EVENT_KBINPUT_STARTOVER handler:^(Event *event){
        @strongify(self)
        if (self && self.hiddenTextField.isFirstResponder) {
            [self.hiddenTextField resignFirstResponder];
            [self resetInput];
        }
    }];
}

- (void)commitInput {
    self.digital = [[numberFormatter numberFromString:self.hiddenTextField.text] floatValue];
    BOOL valid = [self validateDigital];
    [self updateData];
    if (!valid) {
        [self showErrorRangeMessage];
    }
    
}

- (void)cancelInput {
    self.digital = digitalCopy;
    self.digitalButton.selected = digitalSelected;
}

- (void)resetInput {
    // clear the temperature first
    // self.digital = -100;
    [self clearExistData];
    // then, show the default value
    self.digital = self.initialValue;
    self.digitalButton.selected = NO;
}

- (NSDictionary *)digitalConfigTemplate {
    static NSDictionary *template;
    if (!template) {
        template = @{
                  DL_CELL_KEY_BBT: @{
                          @"unit": @"℉",
                          @"serverUnit": @"℃",
                          @"initial": @{
                                  @"℃":@"36.8",
                                  @"℉":@"98.2",
                                  },
                          @"range":@{
                                  @"℃":@[@35.0, @40.0],
                                  @"℉":@[@95.0, @104.0],
                                  },
                          @"units": @{
                                  @"Celsius":@"℃",
                                  @"Fahrenheit":@"℉"
                                  },
                          @"convertionFunction": @{
                                  @"℃": @"celciusFromFahrenheit",
                                  @"℉": @"fahrenheitFromCelcius",
                                  }
                          }
                  };
    }
    return template;
}

- (void)internalConfig{
    NSDictionary *data = self.digitalConfigTemplate[self.dataKey];
    [super configWithTemplate:data];

    [self setUnit:[data valueForKey:@"unit"]];
    [self setUnits:[data valueForKey:@"units"]];
    [self setServerUnit:[data valueForKey:@"serverUnit"]];
    [self setInitial:[data valueForKey:@"initial"]];
    [self setConvertionFunction:[data valueForKey:@"convertionFunction"]];
    self.initialValue = [[_initial objectForKey:_unit] floatValue];
    self.range = [data valueForKey:@"range"];
}

- (void)setValue:(NSObject*)value forDate:(NSDate *)date {
    [super setValue:value forDate:date];

    float val = [(NSNumber *)value floatValue];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *userSetUnit = [defaults objectForKey:([self.dataKey isEqualToString:DL_CELL_KEY_BBT]? kUnitForTemp: kUnitForWeight)];

    if (userSetUnit) {
        [self setUnit:userSetUnit];
        self.initialValue = [[_initial objectForKey:_unit] floatValue];
    }

    if (val > 0) {
        if (![self.serverUnit isEqualToString:self.unit]) {
            val = [Utils convertTemperature:val toUnit:self.unit];
        }
        
        NSArray *range = [self.range objectForKey:_unit];
        if (range && (val < [[range objectAtIndex:0] floatValue] || val > [[range objectAtIndex:1] floatValue])) {
            float newDigital = [Utils convertTemperature:val toUnit:self.unit];
            val = newDigital;
        }
    }
    self.digital = val > 0? val: self.initialValue;
    [self.digitalButton setSelected:val > 0];
}

#pragma clang diagnostic pop


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *changedString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray *arr = [changedString componentsSeparatedByString:numberFormatter.decimalSeparator];
    if ([arr count] > 2) {
        return NO;
    } else if ([arr count] == 2 && [arr[1] length] > 2) {
        return NO;
    }
    return YES;
}

- (void)textChanged:(NSNotification *)notif {
    GLLog(@"textChanged: %@", self.hiddenTextField.text);
    [self.digitalButton setLabelText:[NSString stringWithFormat:@"%@ %@", self.hiddenTextField.text, _unit] bold:YES];
    [self.digitalButton setSelected:YES];
}

- (void)touched {
    [self.delegate findAndResignFirstResponder];
    
    NSArray *keys = [self.units allKeys];
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Change Unit" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSString *k in keys) {
        [actionSheet addButtonWithTitle:k];
    }

    [actionSheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
//    [self.unitButton toggle:YES];
    
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        return;
    }
    NSString *unit = [self.units objectForKey:[actionSheet buttonTitleAtIndex:buttonIndex]];
    [self.unitButton setSelected:YES];
    _unit = unit;

    if (![unit isEqualToString:self.unitButton.titleLabel.text]) {
        //
        if (self.convertionFunction) {
            CGFloat newDigital = [Utils convertTemperature:self.digital toUnit:unit];
            self.digital = newDigital;

            [self.unitButton setLabelText:unit bold:YES];
            self.initialValue = [[_initial objectForKey:_unit] floatValue];
            
            [Utils setDefaultsForKey:([self.dataKey isEqualToString:DL_CELL_KEY_BBT]? kUnitForTemp: kUnitForWeight) withValue:unit];
        }
    }
}

#pragma clang diagnostic pop

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setUnit:(NSString *)unit {
    _unit = unit;
//    [self.unitButton setTitle:unit forState:UIControlStateNormal];
    [self.unitButton setLabelText:unit bold:YES];
}

- (void)setDigital:(float)val {
    [self.digitalButton setLabelText:[NSString stringWithFormat:@"%@ %@", [numberFormatter stringFromNumber:@(val)], _unit]  bold:YES];
    [self.hiddenTextField setText:[numberFormatter stringFromNumber:@(val)]];
    _digital = val;
}

- (BOOL)validateDigital {
    if (self.range) {
        NSString *unit = self.unitButton.titleLabel.text;
        NSArray *ranges = [self.range objectForKey:unit];
        if (ranges) {
            if (self.digital < [[ranges objectAtIndex:0] floatValue]) {
                self.digital = [[ranges objectAtIndex:0] floatValue];
                return NO;
            } else if (self.digital > [[ranges objectAtIndex:1] floatValue]) {
                self.digital = [[ranges objectAtIndex:1] floatValue];
                return NO;
            }
        }
    }
    return YES;
}

- (void)showErrorRangeMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"Glow only accepts BBT values within the range 95-104℉(35-40℃). Anything out of range is not considered medically feasible, so we recommend either purchasing a new thermometer or consulting a medical professional." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    [alert show];
}

- (IBAction)buttonTouched:(id) sender {
//    UIButton *button = (UIButton *)sender;
    [self logButton:BTN_CLK_HOME_TEMPERATURE clickType:CLICK_TYPE_INPUT eventData:nil];
    [self openTemperaturePanel];
}

- (void)openTemperaturePanel {
    digitalCopy = self.digital;
    digitalSelected = !self.digitalButton.selected;//it was toggled in PillButton already.
        
    if (!self.digitalButton.selected) {
        [self.digitalButton toggle:YES];
    }
    [self.hiddenTextField setClearsOnInsertion:YES];
    [self.hiddenTextField becomeFirstResponder];
    
    InputAccessoryView *view = (InputAccessoryView *)self.hiddenTextField.inputAccessoryView;
    [view.segControl removeAllSegments];
    [view.segControl insertSegmentWithTitle:self.units.allValues[0]  atIndex:0 animated:YES];
    [view.segControl insertSegmentWithTitle:self.units.allValues[1]  atIndex:1 animated:YES];
    
    NSInteger unitIndex = 1;//@"℉"
    if (_unit) {
        unitIndex = [self.units.allValues indexOfObject:_unit];
        if (unitIndex > 1) {
            unitIndex = 1;
        }
    }
    [view.segControl setSelectedSegmentIndex:unitIndex];

}

- (IBAction)unitButtonTouched:(id)sender {
    PillButton *btn = (PillButton *)sender;
    [self touched];
    if (!btn.selected) {
        [btn toggle:YES];
    }
}

- (void)updateData {
    GLLog(@"serveUnit: %@, unit:%@", self.serverUnit, self.unit);
    printBOOL([self.serverUnit isEqualToString:self.unit]);
    if ([self.serverUnit isEqualToString:self.unit]) {
        [self.delegate updateDailyData:self.dataKey withValue:@(self.digital)];
    } else {
        float newDigital = [Utils convertTemperature:self.digital
                toUnit:self.serverUnit];
        [self.delegate updateDailyData:self.dataKey withValue:@(newDigital)];
    }
}
- (void)clearExistData {
    [self.delegate updateDailyData:self.dataKey withValue:@(0)];
}

- (void)enterEditingVisibility:(BOOL)visible height:(CGFloat)cellHeight {
    [super enterEditingVisibility:visible height:cellHeight];
    [self.digitalButton setAlpha:0];
}

- (void)exitEditing {
    [super exitEditing];
    [self.digitalButton setAlpha:1];
}
@end

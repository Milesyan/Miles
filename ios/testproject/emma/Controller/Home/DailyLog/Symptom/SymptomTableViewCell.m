//
//  SymptomTableViewCell.m
//  emma
//
//  Created by Peng Gu on 7/23/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "SymptomTableViewCell.h"
#import "PillButton.h"
#import <QuartzCore/QuartzCore.h>
#import "IOS67CompatibleUIButton.h"

@interface SymptomTableViewCell ()

@property (nonatomic, weak) IBOutlet UIView *segmentContainerView;
@property (nonatomic, weak) IBOutlet UIButton *leftButton;
@property (nonatomic, weak) IBOutlet UIButton *rightButton;
@property (nonatomic, weak) IBOutlet UIButton *middleButton;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSArray *intensityButtons;

@property (nonatomic, weak) IBOutlet PillButton *checkButton;

@property (nonatomic, strong) NSArray *buttonColors;

@property (nonatomic, assign) SymptomIntensity symptomIntensity;

- (IBAction)buttonClicked:(id)sender;

@end


@implementation SymptomTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.segmentContainerView.layer.borderWidth = 2;
    self.segmentContainerView.layer.borderColor = [UIColorFromRGB(0x33c89c) CGColor];
    self.segmentContainerView.layer.cornerRadius = 16;
    
    CALayer *divider = [CALayer layer];
    divider.frame = CGRectMake(44, 0, 1, 34);
    divider.backgroundColor = [UIColor colorWithRed:51/255.0 green:200/255.0 blue:155/255.0 alpha:0.7].CGColor;
    [self.segmentContainerView.layer addSublayer:divider];
    
    divider = [CALayer layer];
    divider.frame = CGRectMake(89, 0, 1, 34);
    divider.backgroundColor = [UIColor colorWithRed:51/255.0 green:200/255.0 blue:155/255.0 alpha:0.7].CGColor;
    [self.segmentContainerView.layer addSublayer:divider];
    
    self.buttonColors = @[[UIColor colorWithRed:51/255.0 green:200/255.0 blue:155/255.0 alpha:0.1],
                          [UIColor colorWithRed:51/255.0 green:200/255.0 blue:155/255.0 alpha:0.3],
                          [UIColor colorWithRed:51/255.0 green:200/255.0 blue:155/255.0 alpha:0.5]];
}


- (void)configureWithSymptomName:(NSString *)name
                     symptomType:(SymptomType)symptomType
                       intensity:(SymptomIntensity)intensity
                        delegate:(id<SymptomTableViewCellDelegate>)delegate
{
    _symptomIntensity = intensity;
    self.symptomType = symptomType;
    self.symptomLabel.text = name;
    self.delegate = delegate;
    
    [self updateIntensity];
    
    if (symptomType == SymptomTypeEmotional) {
        self.segmentContainerView.hidden = YES;
        self.checkButton.hidden = NO;
    }
    else {
        self.segmentContainerView.hidden = NO;
        self.checkButton.hidden = YES;
    }
}


- (void)setSymptomIntensity:(SymptomIntensity)symptomIntensity
{
    if (_symptomIntensity == symptomIntensity) {
        _symptomIntensity = SymptomIntensityNone;
    }
    else {
        _symptomIntensity = symptomIntensity;
    }
    
    [self updateIntensity];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(SymptomTableViewCell:didChangeSymptomIntensity:)]) {
        [self.delegate SymptomTableViewCell:self didChangeSymptomIntensity:_symptomIntensity];
    }
}


- (void)buttonClicked:(id)sender
{
    self.symptomIntensity = [sender tag];
}


- (void)clearIntensity
{
    for (NSUInteger i=0; i<3; i++) {
        UIButton *button = [self.intensityButtons objectAtIndex:i];
        UIColor *color = [self.buttonColors objectAtIndex:i];
        
        button.backgroundColor = color;
        [button setImage:nil forState:UIControlStateNormal];
    }
}


- (void)updateIntensity
{
    if (self.symptomType == SymptomTypeEmotional) {
        self.checkButton.selected = self.symptomIntensity != SymptomIntensityNone;
        return;
    }
    
    [self clearIntensity];
    
    if (self.symptomIntensity == SymptomIntensityNone) {
        return;
    }
    
    UIButton *button;
    
    for (NSUInteger i=0; i<self.symptomIntensity; i++) {
        button = [self.intensityButtons objectAtIndex:i];
        button.backgroundColor = UIColorFromRGB(0x33c89c);
    }
    
    [button setImage:[UIImage imageNamed:@"symptom-check"] forState:UIControlStateNormal];
}


@end


//
//  MedicalLogSummary.m
//  emma
//
//  Created by Peng Gu on 10/30/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "MedicalLogSummaryView.h"
#import "UILinkLabel.h"
#import "UserMedicalLog.h"
#import "MedicalLogItem.h"
#import <GLFoundation/NSString+Markdown.h>
#import "User.h"

@implementation MedicalLogSummaryView


+ (instancetype)medicalLogSummaryView
{
    return [[self alloc] init];

    // loading from nib is too slow, init the view programmatically 
    
//    UINib *nib = [UINib nibWithNibName:@"MedicalLogSummaryView" bundle:[NSBundle mainBundle]];
//    MedicalLogSummaryView *view = [[nib instantiateWithOwner:nil options:nil] lastObject];
//
//    if (view) {
//        view.width = SCREEN_WIDTH;
//        [view layoutIfNeeded];
//        return view;
//    }
//    return nil;
}


- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 44)];
    if (self) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 25, 25)];
        _mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(38, 13, 262, 18)];
        _mainLabel.numberOfLines = 0;
        
        [self addSubview:_iconImageView];
        [self addSubview:_mainLabel];
        
        UIEdgeInsets padding = UIEdgeInsetsMake(13, 42, 13, 20);
        [_mainLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(padding);
        }];
        
        [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self).with.offset(9);
            make.left.equalTo(self).with.offset(12);
            make.width.equalTo(@(25));
            make.height.equalTo(@(25));
        }];
    }
    
    return self;
}


- (instancetype)initWithMedicalLog:(UserMedicalLog *)medicalLog
{
    MedicalLogSummaryView *view = [MedicalLogSummaryView medicalLogSummaryView];
    
    NSAttributedString *text = [self summaryForMedicalLog:medicalLog];
    
    if (text) {
        view.mainLabel.attributedText = text;
        view.iconImageView.image = [self iconForMedicalLogKey:medicalLog.dataKey];
        [view updateHeight];
        return view;
    }
    return nil;
}


- (instancetype)initWithMedicationLogs:(NSArray *)medicationLogs
{
    MedicalLogSummaryView *view = [MedicalLogSummaryView medicalLogSummaryView];
    
    NSMutableString *text;
    User *user = [User currentUser];
    if (user.isSecondary) {
        text = [[NSString stringWithFormat:@"%@ took ", user.partner.firstName] mutableCopy];
    } else {
        text = [@"I took " mutableCopy];
    }
    NSMutableArray *names = [NSMutableArray array];
    for (UserMedicalLog *log in medicationLogs) {
        NSString *name = [@"**" stringByAppendingString:[self shortNameForMedicationLog:log]];
        [names addObject:[name stringByAppendingString:@"**"]];
    }
    
    [names sortUsingSelector:@selector(localizedCompare:)];
    [text appendString:[names componentsJoinedByString:@", "]];
    NSRange lastSeparator = [text rangeOfString:@", " options:NSBackwardsSearch];
    if (lastSeparator.length > 0) {
        [text replaceCharactersInRange:lastSeparator withString:@" and "];
    }

    
    view.mainLabel.attributedText = [NSString markdownToAttributedText:text fontSize:18 color:[UIColor blackColor]];
    view.iconImageView.image = [self iconForMedicalLogKey:kMedItemMedication];
    [view updateHeight];
    
    return view;
}


- (void)updateHeight
{
    [self layoutIfNeeded];
    CGFloat lableHeight = self.mainLabel.height;
    [self.mainLabel sizeToFit];
    if (self.mainLabel.height > lableHeight) {
        self.height = self.height + self.mainLabel.height - lableHeight;
    }
}


- (NSString *)shortNameForMedicationLog:(UserMedicalLog *)medicationLog
{
    NSString *fullName = [medicationLog.dataKey substringFromIndex:kMedicationItemKeyPrefix.length];
    NSDictionary *mapping = @{
                              @"Clomiphene citrate (Clomid; Serophene)": @"Clomid",
                              @"Human menopausal gonadotropin or hMG (Repronex; Pergonal)": @"hMG",
                              @"Follicle-stimulating hormone or FSH (Gonal-F; Follistim)": @"FSH",
                              @"Gonadotropin-releasing hormone (Gn-RH)": @"Gn-RH",
                              @"Metformin (Glucophage)": @"Glucophage",
                              @"Bromocriptine (Parlodel)": @"Parlodel"};
    
    if (mapping[fullName]) {
        return mapping[fullName];
    }
    return fullName;
}


- (NSAttributedString *)summaryForMedicalLog:(UserMedicalLog *)medicalLog
{
    NSString *itemKey = medicalLog.dataKey;
    NSString *value = medicalLog.dataValue;
    NSString *plainText;
    
    if([itemKey isEqualToString:kMedItemBloodWork] && value.integerValue == BinaryValueTypeYes) {
        plainText = @"I had **bloodwork** done";
    }
    else if([itemKey isEqualToString:kMedItemUltrasound] && value.integerValue == BinaryValueTypeYes) {
        plainText = @"I had an **ultrasound** done";
    }
    else if([itemKey isEqualToString:kMedItemHCGTriggerShot] && value.integerValue == BinaryValueTypeYes) {
        plainText = @"An **hCG trigger shot** was administered";
    }
    else if([itemKey isEqualToString:kMedItemInsemination] && value.integerValue == BinaryValueTypeYes) {
        plainText = @"My **insemination** occurred";
    }
    else if ([itemKey isEqualToString:kMedItemEggRetrieval]) {
        plainText = @"I had **eggs** retrieved";
    }
    else if([itemKey isEqualToString:kMedItemEggRetrievalNumber]) {
        if (value.integerValue > 1) {
            plainText = [NSString stringWithFormat:@"I had **%ld eggs** retrieved", value.integerValue];
        }
        else if (value.integerValue == 1) {
            plainText = @"I had **1 egg** retrieved";
        }
        else {
            return nil;
        }
    }
    else if([itemKey isEqualToString:kMedItemEmbryosFrozenNumber]) {
        if (value.integerValue > 1) {
            plainText = [NSString stringWithFormat:@"I froze **%ld embryos**", value.integerValue];
        }
        else if (value.integerValue == 1) {
            plainText = @"I froze **1 embryo**";
        }
        else {
            return nil;
        }
    }
    else if ([itemKey isEqualToString:kMedItemEmbryosTransfer]) {
        plainText = @"I transferred **embryos**";
    }
    else if([itemKey isEqualToString:kMedItemEmbryosTransferNumber]) {
        if (value.integerValue > 1) {
            plainText = [NSString stringWithFormat:@"I transferred **%ld embryos**", value.integerValue];
        }
        else if (value.integerValue == 1) {
            plainText = @"I transferred **1 embryo**";
        }
        else {
            plainText = @"I transferred **embryos**";
        }
    }
    else {
        return nil;
    }
    
    User *user = [User currentUser];
    if (!user.isPrimaryOrSingleMom) {
        if ([plainText hasPrefix:@"I "]) {
            plainText = [plainText stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                               withString:user.partner.firstName];
        }
        else if ([plainText hasPrefix:@"My "]) {
            plainText = [plainText stringByReplacingCharactersInRange:NSMakeRange(0, 2)
                                               withString:[NSString stringWithFormat:@"%@’s", user.partner.firstName]];
        }
    }
    
    return [NSString markdownToAttributedText:plainText fontSize:18 color:[UIColor blackColor]];
}


- (UIImage *)iconForMedicalLogKey:(NSString *)key
{
    NSDictionary *mapping = @{
                              kMedItemBloodWork: @"home-logged-blood",
                              kMedItemUltrasound: @"home-logged-ultrasound",
                              kMedItemHCGTriggerShot: @"home-logged-trigger-shot",
                              kMedItemInsemination: @"home-logged-insemination",
                              kMedItemEggRetrieval: @"home-logged-egg-retrieval",
                              kMedItemEggRetrievalNumber: @"home-logged-egg-retrieval",
                              kMedItemEmbryosFrozenNumber: @"home-logged-embryo-frozen",
                              kMedItemEmbryosTransferNumber: @"home-logged-embryo-transfer",
                              kMedItemEmbryosTransfer: @"home-logged-embryo-transfer",
                              kMedItemMedication: @"home-logged-med",
                              };
    
    if (mapping[key]) {
        return [UIImage imageNamed:mapping[key]];
    }
    return nil;
}



@end









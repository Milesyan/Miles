//
//  TestkitBrandPicker.h
//  emma
//
//  Created by Eric Xu on 11/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import <UIKit/UIKit.h>

@class TestkitBrandPicker;
@protocol TestkitBrandPickerDelegate <NSObject>
- (void)testkitBrandPicker:(TestkitBrandPicker *)picker didDismissWithBrandIndex:(NSInteger)brandIndex;
- (void)testkitBrandPickerDidDismissWithStartOverButton:(TestkitBrandPicker *)picker ;
- (void)testkitBrandPickerDidDismissWithCancelButton:(TestkitBrandPicker *)picker ;
@end

@interface TestkitBrandPicker : UIViewController
@property (nonatomic, strong) NSArray* brands;
@property (nonatomic, weak) id<TestkitBrandPickerDelegate> delegate;

- (void)presentWithBrands:(NSArray *)arr selection:(NSInteger)selectedIndex;

@end

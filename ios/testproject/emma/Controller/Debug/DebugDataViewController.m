//
//  DebugDataViewController.m
//  emma
//
//  Created by ltebean on 15-5-8.
//  Copyright (c) 2015年 Upward Labs. All rights reserved.
//

#import "DebugDataViewController.h"
#import <GLFoundation/GLTheme.h>

@interface DebugDataViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation DebugDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.textView.attributedText = [[NSAttributedString alloc] initWithString:self.text attributes:[self textAttributes]];
}

- (NSDictionary *)textAttributes
{
    static NSDictionary *sAttribute = nil;
    if (!sAttribute) {
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineSpacing = 6;
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        sAttribute = @{
                        NSFontAttributeName : [GLTheme defaultFont:18.0],
                        NSForegroundColorAttributeName : [UIColor blackColor],
                        NSParagraphStyleAttributeName :paragraphStyle
                        };
    }
    return sAttribute;
}

@end

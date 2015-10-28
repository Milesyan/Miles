//
//  ExportReportDialog.m
//  emma
//
//  Created by Eric Xu on 7/24/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "ExportReportDialog.h"
#import "GLDialogViewController.h"
#import "PillGradientButton.h"
#import "User.h"
#import "Network.h"
#import "Logging.h"
#import "NetworkLoadingView.h"
#import <QuartzCore/QuartzCore.h>
#import "DropdownMessageController.h"
#import "StatusBarOverlay.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "DropdownMessageController.h"
#import "DailyLogCellTypeDigital.h"
#import <GLFoundation/NSString+Markdown.h>

@interface ExportReportDialog ()<UITextFieldDelegate>

@property (nonatomic, strong) User *user;
@property (nonatomic, strong) GLDialogViewController *dialog;
@property (strong, nonatomic) UITapGestureRecognizer *tapRec;
@property (strong, nonatomic) DropdownMessageController *msgController;

@property (weak, nonatomic) IBOutlet UILabel *tipText;

@property (strong, nonatomic) IBOutlet PillGradientButton *sendButton;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UIView *emailBg;
- (IBAction)sendButtonClicked:(id)sender;

@end

@implementation ExportReportDialog

- (id)initWithUser:(User *)user {
    self = [super initWithNibName:@"ExportReportDialog" bundle:nil];
    if (self) {
        self.user = user;
        self.tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:) ];
        [self.view addGestureRecognizer:self.tapRec];
        self.msgController = [DropdownMessageController sharedInstance];
    }
    
    return self;
}

- (void)tapped:(UIGestureRecognizer *)sender {
    [self.view findAndResignFirstResponder];
}

- (void)present
{
    [CrashReport leaveBreadcrumb:@"ExportReportDialog"]; 
    self.dialog = [GLDialogViewController sharedInstance];
    [self subscribeOnce:EVENT_DIALOG_CLOSE_BUTTON_CLICKED obj:self.dialog handler:^(Event *evt){
        //[Logging log:BTN_CLK_EXPORT_PDF_CLOSE];
    }];

    [self.dialog presentWithContentController:self];
    
    self.tipText.attributedText = [NSString addFont:[Utils lightFont:14.0] toAttributed:self.tipText.attributedText];
    
    NSDictionary * fontAttr = @{NSFontAttributeName:[Utils boldFont:14.0]};
    NSMutableAttributedString * s = [[NSMutableAttributedString alloc] initWithAttributedString:self.tipText.attributedText];
    [s addAttributes:fontAttr range:NSMakeRange(29, 3)];
    self.tipText.attributedText = s;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.email.text = self.user.email;
    
    [self.emailBg.layer setBorderColor:[UIColorFromRGB(0xdddddd) CGColor]];
    [self.emailBg.layer setBorderWidth:0.5];
    [self.emailBg.layer setCornerRadius:8];

    [self.sendButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    
}


- (void)sendReportRequest {
    [self.view findAndResignFirstResponder];
    [self.dialog close];
    [[StatusBarOverlay sharedInstance] postMessage:@"Sending data summary" duration:3];
    NSString *unit = [[NSUserDefaults standardUserDefaults] objectForKey:kUnitForTemp];
    GLLog(@"UNIT: %@", unit);
    //Simplify unit char
    if (!unit) {
        unit = @"";
    } else if ([unit isEqualToString:@"℃"]) {
        unit = @"C";
    } else if ([unit isEqualToString:@"℉"]) {
        unit = @"F";
    }
    [self.user exportReport:self.email.text withUnit:unit];
    
}

- (IBAction)sendButtonClicked:(id)sender {
    [Logging log:BTN_CLK_EXPORT_PDF_SUBMIT];
    BOOL isemail = [Utils isValidEmail:self.email.text];
//    [NSException raise:@"Data report exception" format:@"foobar"]; 
    if (isemail) {
        //call to send
        [self sendReportRequest];
    } else {
        [self.email becomeFirstResponder];
        [self.msgController postMessage:@"Please input a valid email." duration:3 position:60 inView:self.view.window];
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL isemail = [Utils isValidEmail:self.email.text];
    if (isemail) {
        [self sendReportRequest];
    } else {
        [self.email becomeFirstResponder];
        [self.msgController postMessage:@"Please input a valid email." duration:3 position:60 inView:self.view.window];
    }
    
    return YES;
}

@end

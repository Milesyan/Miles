//
//  FundEmployerApplyViewController.m
//  emma
//
//  Created by Jirong Wang on 12/3/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "FundEmployerApplyViewController.h"
#import "FontReplaceableBarButtonItem.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import "StatusBarOverlay.h"
#import "Errors.h"
#import "Logging.h"
#import "ImagePicker.h"
#import "UIImage+Resize.h"
#import "TabbarController.h"
#import "DropdownMessageController.h"
#import "EnterpriseApplyByPhotoDialog.h"
#import <GLFoundation/GLUtils.h>

@interface FundEmployerApplyViewController () <UITextFieldDelegate, ImagePickerDelegate> {
}

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UITextField *employerEmail;
@property (weak, nonatomic) IBOutlet UITextField *employerName;
@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *nextButton;

@property (weak, nonatomic) IBOutlet UIImageView *photoView;
@property (weak, nonatomic) IBOutlet UILabel *addPhotoText;
@property (weak, nonatomic) IBOutlet UIView *lastCellDividerLine;

@property (weak, nonatomic) IBOutlet UILabel *tipText;
- (IBAction)nextButtonPressed:(id)sender;
- (IBAction)backButtonPressed:(id)sender;

@property (nonatomic) NSString * EMAIL_PLACEHOLDER;
@property (nonatomic) NSString * NAME_PLACEHOLDER;

@property (nonatomic) DropdownMessageController *messageController;
@property (nonatomic) BOOL hasImage;

@end

@implementation FundEmployerApplyViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.bottomView.frame = setRectHeight(self.bottomView.frame, 94 + HEIGHT_MORE_THAN_IPHONE_4);
    
    self.employerEmail.delegate = self;
    self.employerName.delegate = self;
    self.EMAIL_PLACEHOLDER = self.employerEmail.placeholder;
    self.NAME_PLACEHOLDER = self.employerName.placeholder;
    self.hasImage = NO;
    self.photoView.layer.cornerRadius = 5.0;
    self.messageController = [DropdownMessageController sharedInstance];
    
    // if (IOS7_OR_ABOVE) {
    self.lastCellDividerLine.frame = CGRectMake(0, 0, SCREEN_WIDTH, 0.5);
    self.lastCellDividerLine.backgroundColor = UIColorFromRGB(0xc7c7cd);
    // } else {
    //    self.lastCellDividerLine.hidden = YES;
    // }
    
    // add font for the text
    NSDictionary * fontAttr = @{NSFontAttributeName:[Utils lightFont:15.0]};
    NSMutableAttributedString * s = [[NSMutableAttributedString alloc] initWithAttributedString:self.tipText.attributedText];
    [s addAttributes:fontAttr range:NSMakeRange(0, s.length)];
    self.tipText.attributedText = s;
    
    if (IS_IPHONE_4) {
        self.tipText.aBottom = 5;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self checkNextButtonEnable];
    [self subscribe:EVENT_FUND_ENTERPRISE_APPLY selector:@selector(onEnterpriseApply:)];
    [self subscribe:EVENT_FUND_ENTERPRISE_APPLY_BY_PHOTO selector:@selector(onEnterpriseApplyByPhoto:)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // logging
    [CrashReport leaveBreadcrumb:@"FundEmployerApplyViewController"];
    [Logging log:PAGE_IMP_FUND_ENTERPRISE_APPLY];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self unsubscribeAll];
}

#pragma mark - IBActions
- (IBAction)backButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_ENTERPRISE_APPLY_BACK];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

#pragma make - next button pressed
- (IBAction)nextButtonPressed:(id)sender {
    // logging
    [Logging log:BTN_CLK_FUND_ENTERPRISE_APPLY_NEXT];
    if (self.hasImage) {
        [self applyByPhoto];
    } else {
        [self applyByEmail];
    }

}

- (void)applyByEmail {
    if ((self.employerEmail.text.length==0) || (self.employerName.text.length==0)) {
        NSString *errMsg = self.employerEmail.text.length==0 ? @"valid email address" : @"valid name";
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:[NSString stringWithFormat:@"Please input a %@", errMsg]
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    NSDictionary * req = @{
                           @"working_email": self.employerEmail.text,
                           @"working_name": self.employerName.text
                           };
    [NetworkLoadingView show];
    self.nextButton.enabled = NO;
    
    if (self.employerName.editing) [self.employerName resignFirstResponder];
    if (self.employerEmail.editing) [self.employerEmail resignFirstResponder];
    
    [[GlowFirst sharedInstance] enterpriseApply:req];
}

- (void)applyByPhoto {
    [NetworkLoadingView show];
    self.nextButton.enabled = NO;
    [[GlowFirst sharedInstance] enterpriseApplyByPhoto:self.photoView.image];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {	
    NSInteger textLength1 = textField.text.length;
    NSInteger textLength2 = 0;
    if (textField == self.employerEmail) {
        textLength2 = self.employerName.text.length;
    } else {
        textLength2 = self.employerEmail.text.length;
    }
    
    if (!string.length) {
        // allow backspace
        textLength1--;
    } else {
        textLength1++;
    }
    
    self.nextButton.enabled = (textLength1>0 && textLength2>0);
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.placeholder = @"";
    self.photoView.image = nil;
    self.hasImage = NO;
    self.addPhotoText.aLeft = 15.0;
    
    [self checkNextButtonEnable];
    //textField.textAlignment = NSTextAlignmentLeft;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.employerEmail)
        textField.placeholder = self.EMAIL_PLACEHOLDER;
    else if (textField == self.employerName)
        textField.placeholder = self.NAME_PLACEHOLDER;
    //textField.textAlignment = NSTextAlignmentRight;
    [self checkNextButtonEnable];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Glow First enterprise apply callback
- (void)onEnterpriseApply:(Event *)event {
    [NetworkLoadingView hide];
    self.nextButton.enabled = YES;
    NSDictionary * response = (NSDictionary *)(event.data);

    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to apply Glow First." duration:4.0];
    } else if (rc == RC_SUCCESS) {
        // go to verify page
        [self performSegueWithIdentifier:@"goEmployerVerify" sender:self from:self];
    } else if (rc == RC_ENTERPRISE_COMPANY_NOT_FOUND) {
        // go to ask HR page
        [self performSegueWithIdentifier:@"goEmployerAskHR" sender:self from:self];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)onEnterpriseApplyByPhoto:(Event *)event {
    [NetworkLoadingView hide];
    self.nextButton.enabled = YES;
    NSDictionary * response = (NSDictionary *)(event.data);
    
    NSInteger rc = [[response objectForKey:@"rc"] integerValue];
    if (rc == RC_NETWORK_ERROR) {
        StatusBarOverlay *sbar = [StatusBarOverlay sharedInstance];
        [sbar postMessage:@"Failed to apply Glow First." duration:4.0];
    } else if (rc == RC_SUCCESS) {
        // go to under review enterprise page
        [[TabbarController getInstance:self] rePerformFundSegue];
        
        EnterpriseApplyByPhotoDialog *dialog = [[EnterpriseApplyByPhotoDialog alloc] init];
        [dialog present];
    } else {
        NSString *errMsg = [response objectForKey:@"msg"];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:(errMsg ? errMsg : [Errors errorMessage:rc])
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 0) {
        [self chooseImage];
    }
}

- (void)chooseImage {
    self.employerEmail.text = @"";
    self.employerName.text  = @"";
    [self checkNextButtonEnable];
    [[ImagePicker sharedInstance] showInController:self withTitle:@"Chose photo for paystub" destructiveButtonTitle:nil allowsEditing:NO];
}

- (void)didPickedImage:(UIImage *)image {
    self.photoView.image = image;
    self.addPhotoText.aLeft = 75.0;
    // self.addPhotoText.frame = setRectX(self.addPhotoText.frame, 60);
    self.hasImage = YES;
    
    [self.messageController postMessage:@"Click next to continue!" duration:4.0 position:70 inView:[GLUtils keyWindow]];
    [self checkNextButtonEnable];
    
    // logging
    [Logging log:BTN_CLK_FUND_ENTERPRISE_UPLOAD_PAYSTUB];
}

- (void)imagePickerDidCancle:(ImagePicker *)imagePicker {
    // deselect the table cell
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]].selected = NO;
}

- (void)checkNextButtonEnable {
    if ((self.employerEmail.text.length > 0) && (self.employerName.text.length > 0)) {
        self.nextButton.enabled = YES;
    } else if (self.hasImage) {
        self.nextButton.enabled = YES;
    } else {
        self.nextButton.enabled = NO;
    }
}

#pragma mark - UITableViewDelegate
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    UIView * view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 40)];
    UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, SCREEN_WIDTH-30, 40)];
    label.text = (section == 1) ? @"Verify by work email" : @"Or verify by paystub (manual process)";
    label.font = [Utils defaultFont: 17];
    label.backgroundColor = UIColorFromRGB(0xfbfaf7);
    view.backgroundColor = UIColorFromRGB(0xfbfaf7);
    [view addSubview:label];
    
    // add divider line
    UIView * l = [[UIView alloc] initWithFrame:CGRectMake(0, 39.5, SCREEN_WIDTH, 0.5)];
    l.backgroundColor = UIColorFromRGB(0xc7c7cd);
    [view addSubview:l];
    if (section==2) {
        UIView * l2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 0.5)];
        l2.backgroundColor = UIColorFromRGB(0xc7c7cd);
        [view addSubview:l2];
    }
    return view;
}

@end

//
//  WalgreensScannerViewController.m
//  emma
//
//  Created by ltebean on 14-12-26.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "WalgreensScannerViewController.h"
#import "EXTScope.h"
#import "ScannerFocusView.h"
#import "WalgreensWebViewController.h"
#import "WalgreensManager.h"
#import "NetworkLoadingView.h"
#import <AVFoundation/AVFoundation.h>
#import "User.h"
#import <ZXingObjC/ZXingObjC.h>
#import "WalgreensFlipTransition.h"
#import "WalgreensRxNumberInputViewController.h"

@interface WalgreensScannerViewController ()<UIAlertViewDelegate,ZXCaptureDelegate,UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet ScannerFocusView *scannerFocusView;
@property (weak, nonatomic) IBOutlet UIButton *enterRxNumberButton;
@property (nonatomic,copy) NSString *decodedText;
@property (nonatomic, strong) ZXCapture *capture;
@end

@implementation WalgreensScannerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.capture = [[ZXCapture alloc] init];
    self.capture.camera = self.capture.back;
    self.capture.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    self.capture.rotation = 90.0f;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.enterRxNumberButton.layer.cornerRadius = self.enterRxNumberButton.height/2;
    [self startScan];
}

- (void)viewDidAppear:(BOOL)animated
{
    [Logging log:PAGE_IMP_WALGREENS_SCANNER];
    self.navigationController.delegate = self;
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnteredBackground:)
                                                 name: UIApplicationDidEnterBackgroundNotification
                                               object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(handleEnterForeground:)
                                                 name: UIApplicationWillEnterForegroundNotification
                                               object: nil];
    [self.scannerFocusView setup];
    [self.scannerFocusView startAnimation];
    [self checkCameraPermission];
}


- (void)handleEnteredBackground:(NSNotification *)notification
{
    [self stopScan];
    [self.scannerFocusView stopAnimation];
}

- (void)handleEnterForeground:(NSNotification *)notification
{
    [self startScan];
    [self.scannerFocusView startAnimation];
}

- (void)startScan
{
    self.capture.layer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.capture.layer];
    self.capture.delegate = self;
    [self.view bringSubviewToFront:self.overlayView];
    self.decodedText = nil;
}

- (void)stopScan
{
    [self.capture stop];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopScan];
    [self.scannerFocusView stopAnimation];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.navigationController.delegate == self) {
        self.navigationController.delegate = nil;
    }
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    if (!result) return;
    [self performSelectorOnMainThread:@selector(didDecodeBarcodeToText:) withObject:result.text waitUntilDone:YES];
}

- (void)checkCameraPermission
{
    BOOL asked = [Utils getDefaultsForKey:USER_DEFAULTS_KEY_CAMERA_ASKED];
    if (!asked) {
        [Utils setDefaultsForKey:USER_DEFAULTS_KEY_CAMERA_ASKED withValue:@(YES)];
        return;
    }
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusAuthorized) {
        // do your logic
    } else if(authStatus == AVAuthorizationStatusDenied){
        // denied
        [self showGrantAccssDialog];
    } else if(authStatus == AVAuthorizationStatusRestricted){
        // restricted, normally won't happen
    } else if(authStatus == AVAuthorizationStatusNotDetermined){
        // not determined?!
        [self showGrantAccssDialog];
    } else {
        // impossible, unknown authorization status
    }
}

- (void)showGrantAccssDialog
{
    UIAlertView * alertView =[[UIAlertView alloc ] initWithTitle:@"Camera Access Denied"
                                                         message:@"You could allow Glow to access the camera in Settings"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles: nil];
    [alertView show];
}


- (void)didDecodeBarcodeToText:(NSString *)text
{
    // prevent being called mutilple times
    if(self.decodedText){
        return;
    }
    
    self.decodedText = text;
    
    BOOL valid = [WalgreensManager isValidRxNumber:text];
    if (!valid) {
        UIAlertView * alertView =[[UIAlertView alloc ] initWithTitle:@"Rx Number Incorrect"
                                                             message:@"Sorry, the barcode you scanned does not match any medications. Please enter the prescription number manually. \n\n*FL and AZ residents, please try to use the 'Enter manually' option."
                                                            delegate:self
                                                   cancelButtonTitle:@"Cancel"
                                                   otherButtonTitles:@"Enter manually",nil];
        [alertView show];
        
        return;
    }
    
    [NetworkLoadingView showWithoutAutoClose];
    [WalgreensManager getLandingURL:^(NSDictionary *response, NSError *err) {
        [NetworkLoadingView hide];
        if (err || response == nil) {
            [self showErrorWithTitle:@"Failed to load Walgreens page" message:nil];
            self.decodedText = nil;
        } else {
            [self performSegueWithIdentifier:@"openPage" sender:nil];
        }
    }];
}

- (void)showErrorWithTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView * alertView =[[UIAlertView alloc ] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
    [alertView show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        self.decodedText = nil;
    } else if (buttonIndex == 1) {
        [self performSegueWithIdentifier:@"inputRxNumber" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqual:@"openPage"]) {
        WalgreensWebViewController *vc = segue.destinationViewController;
        vc.request = [WalgreensManager getRefillRequest:self.decodedText];
    }
}

- (IBAction)cancel:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_SCAN_CANCEL];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)enterRxNumberClicked:(id)sender {
    [Logging log:BTN_CLK_WALGREENS_SCAN_ENTER_NUMBER];
}


- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if ([toVC isKindOfClass:[WalgreensRxNumberInputViewController class]]) {
        return [[WalgreensFlipTransition alloc] init];
    } else {
        return nil;
    }
}

@end


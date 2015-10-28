//
//  FundClaimTermsViewController.m
//  emma
//
//  Created by Jirong Wang on 6/19/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "FundClaimTermsViewController.h"
#import "User.h"
#import "NetworkLoadingView.h"
#import "GlowFirst.h"
#import "DropdownMessageController.h"
#import <GLFoundation/NSString+Markdown.h>
#import <GLFoundation/GLUtils.h>

@interface FundClaimTermsViewController ()<UITextFieldDelegate, UIWebViewDelegate>

@property (nonatomic) IBOutlet UITextField *firstName;
@property (nonatomic) IBOutlet UITextField *lastName;
@property (nonatomic) IBOutlet UITextField *taxId;
@property (nonatomic) IBOutlet UITextField *street;
@property (nonatomic) IBOutlet UITextField *city;
@property (nonatomic) IBOutlet UITextField *state;
@property (nonatomic) IBOutlet UITextField *zipCode;
@property (nonatomic) IBOutlet UITextField *phoneNumber;

@property (nonatomic) IBOutlet UIWebView *termsWebView;
@property (nonatomic) IBOutlet UIButton *agreeButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *webPageIndicator;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *seperateLines;

@property (nonatomic) BOOL webViewLoaded;
@property (nonatomic) CGFloat webViewHeight;

@property (weak, nonatomic) IBOutlet UILabel *fontAttributedText;
- (IBAction)agreeButtonClicked:(id)sender;

@end

@implementation FundClaimTermsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.agreeButton.layer.cornerRadius = 19;
    [self setAgreeButtonEnable:NO];
    [self prefill];
    
    self.fontAttributedText.attributedText = [NSString addFont:[Utils defaultFont:16.0] toAttributed:self.fontAttributedText.attributedText];
    
    self.termsWebView.scrollView.showsHorizontalScrollIndicator = NO;
    self.termsWebView.scrollView.showsVerticalScrollIndicator = NO;
    self.termsWebView.scrollView.scrollEnabled = NO;
    self.termsWebView.delegate = self;
    // self.webViewLoaded = NO;
    self.webViewHeight = 300;
    [self.webPageIndicator startAnimating];
    for (UIView * line in self.seperateLines) {
        line.frame = setRectHeight(line.frame, 0.5);
    }
    [self loadTosWebPage];
}

- (void)prefill {
    User * u = [User currentUser];
    self.firstName.text = u.firstName;
    self.lastName.text  = u.lastName;
    self.street.text    = u.settings.shippingStreet;
    self.city.text      = u.settings.shippingCity;
    self.state.text     = u.settings.shippingState;
    self.zipCode.text   = u.settings.shippingZip;
    self.phoneNumber.text = u.settings.phoneNumber;
    
    self.taxId.text     = u.settings.taxId;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self subscribe:EVENT_FUND_AGREE_CLAIM_TERM selector:@selector(agreeClaimTermCallback:)];
    // [self loadTosWebPage];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section==1) && (indexPath.row==0)) {
        return self.webViewHeight;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

/*
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section==1) && (indexPath.row==0)) {
        if (!self.webViewLoaded) {
            self.webViewLoaded = YES;
            [self loadTosWebPage];
        }
    }
}
*/
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((indexPath.section==1) && (indexPath.row==0)) {
        self.termsWebView.frame = CGRectMake(0, 0, SCREEN_HEIGHT, self.webViewHeight);
    }
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    BOOL shouldReturn = NO;
    if (textField == self.firstName) {
        [self.lastName becomeFirstResponder];
    } else if (textField == self.lastName) {
        [self.taxId becomeFirstResponder];
    } else if (textField == self.taxId) {
        if ([Utils isEmptyString:self.street.text]) {
            [self.street becomeFirstResponder];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:3] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else {
            shouldReturn = YES;
        }
    } else if (textField == self.street) {
        [self.city becomeFirstResponder];
    } else if (textField == self.city) {
        [self.state becomeFirstResponder];
    } else if (textField == self.state) {
        [self.zipCode becomeFirstResponder];
    } else if (textField == self.zipCode) {
        [self.phoneNumber becomeFirstResponder];
    } else if (textField == self.phoneNumber) {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.taxId) {
        // move taxId to the top of the page
        [UIView animateWithDuration:0.2 animations:^(void){} completion:^(BOOL finished) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }];
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.taxId) {
        NSInteger lengthOfString = string.length;
        NSString * old = textField.text;
        NSString * new = nil;
        
        if (!lengthOfString) {
            if ((old.length == 4) || (old.length == 7)) {
                new = [old substringToIndex:old.length-2];
            } else {
                new = [old substringToIndex:old.length-1];
            }
        } else if (lengthOfString > 1) {
            return NO;
        } else {
            if (old.length == 11) return NO;
            unichar character = [string characterAtIndex:0];
            if (character < 48) return NO; // 48 unichar for 0
            if (character > 57) return NO; // 57 unichar for 9
            // digital input check
            if ((old.length == 2) || (old.length == 5)) {
                new = [NSString stringWithFormat:@"%@%@-", old, string];
            } else {
                new = [NSString stringWithFormat:@"%@%@", old, string];
            }
        }
        // rebuild the string
        textField.text = new;
        return NO;
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateAgreeButton];
}

- (void)updateAgreeButton {
    BOOL done = YES;
    if (self.taxId.text.length != 11) {
        done = NO;
    } else {
        NSArray *tfArrays = @[self.firstName,
                              self.lastName,
                              self.street,
                              self.city,
                              self.state,
                              self.zipCode,
                              self.phoneNumber];
        for (UITextField *tf  in tfArrays) {
            if ([[Utils trim:tf.text] isEqualToString:@""]) {
                done = NO;
                break;
            }
        }
    }
    [self setAgreeButtonEnable:done];
}

- (void)setAgreeButtonEnable:(BOOL)enable {
    if (self.agreeButton.enabled == enable) return;
    self.agreeButton.enabled = enable;
    if (enable) {
        [self.agreeButton setBackgroundColor:UIColorFromRGBA(0x5a62d2ff)];
    } else {
        [self.agreeButton setBackgroundColor:UIColorFromRGBA(0x5a62d277)];
    }
}

#pragma mark - IBAction
- (IBAction)agreeButtonClicked:(id)sender {
    NSDictionary * info = @{
                            @"first_name": self.firstName.text,
                            @"last_name":  self.lastName.text,
                            @"tax_id":     self.taxId.text,
                            @"shipping_street":   self.street.text,
                            @"shipping_city":     self.city.text,
                            @"shipping_state":    self.state.text,
                            @"shipping_zip":      self.zipCode.text,
                            @"phone_number":      self.phoneNumber.text
                            };
    [NetworkLoadingView show];
    [[GlowFirst sharedInstance] agreeClaimTerms:info];
}

- (void)agreeClaimTermCallback:(Event *)event {
    [NetworkLoadingView hide];
    
    NSDictionary * result = (NSDictionary *)event.data;
    NSInteger rc = [[result objectForKey:@"rc"] integerValue];
    if (rc == RC_SUCCESS) {
        NSString * taxId = [result objectForKey:@"tax_id"];
        User * u = [User currentUser];
        u.settings.taxId = taxId;
        [u save];
        [self performSegueWithIdentifier:@"claimAfterTermsSegue" sender:self from:self];
    } else {
        [[DropdownMessageController sharedInstance] postMessage:@"Error! Sorry, please try again or contact us" duration:3 position:64 inView:[GLUtils keyWindow]];
    }
}

#pragma mark - webView request
- (void)loadTosWebPage {
    User * u = [User currentUser];
    NSString * url = [NSString stringWithFormat:@"%@&ut=%@", TERMS_OF_PAYMENT_URL, u.encryptedToken];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[Utils makeUrl:url]] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:86400];
    [self.termsWebView loadRequest:request];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.webPageIndicator stopAnimating];
    self.webPageIndicator.hidden = YES;
    self.webViewHeight = self.termsWebView.scrollView.contentSize.height;
    [self.tableView reloadData];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    // GLLog(@"jr debug, web page eror failed: %@", [error description]);
}


@end

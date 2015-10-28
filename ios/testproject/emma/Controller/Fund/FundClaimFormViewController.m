//
//  FundClaimViewController.m
//  emma
//
//  Created by Eric Xu on 5/8/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#define EVENT_REMOVE_ATTACHMENT @"event_remove_attachment"
#define EVENT_CLICK_ATTACHMENT @"event_click_attachment"


#import "FundClaimFormViewController.h"
#import "FundClaimViewController.h"
#import "UIView+FindAndResignFirstResponder.h"
#import "MWPhotoBrowser.h"
#import "FontReplaceableBarButtonItem.h"
#import "GlowFirst.h"
#import "NetworkLoadingView.h"
#import <GLFoundation/NSString+Markdown.h>

#define BILL_IMG_WIDTH 260

@interface GalleryItem : UIView {
}
@property UIImageView *imageView;
@property UIButton *closeButton;

- (void)setGalleryImage:(UIImage *)image;

@end

@implementation GalleryItem

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, frame.size.width - 20, frame.size.height - 10)];
        [self addSubview:self.imageView];
        self.imageView.clipsToBounds = YES;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.layer.cornerRadius = 5;
        self.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
        self.layer.shadowOffset = CGSizeMake(0, 0);
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 0.5;
        
        self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.closeButton addTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.closeButton setImage:[Utils imageNamed:@"cross" withColor:[UIColor darkGrayColor]] forState:UIControlStateNormal];
        self.closeButton.frame = CGRectMake(0, 0, 20, 20);
        self.closeButton.layer.borderWidth = 1;
        self.closeButton.layer.cornerRadius = 10;
        self.closeButton.layer.borderColor = [[UIColor darkGrayColor] CGColor];
        self.closeButton.layer.backgroundColor = [[UIColor whiteColor] CGColor];
        [self addSubview:self.closeButton];
        
        UITapGestureRecognizer *singleFingerTap =
        [[UITapGestureRecognizer alloc] initWithTarget:self
                                                action:@selector(handleSingleTap:)];
        [self addGestureRecognizer:singleFingerTap];
    }
    return self;
}


- (void)setGalleryImage:(UIImage *)image {
    self.imageView.image = image;
}

- (void)deleteButtonClicked:(id)sender {
    [self publish:EVENT_REMOVE_ATTACHMENT data:self.imageView.image];
}

- (void)handleSingleTap: (id)sender {
    [self publish:EVENT_CLICK_ATTACHMENT data:self.imageView.image];
}

@end

@interface ImageGallery : UIView <UIScrollViewDelegate> {
 }
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIPageControl *pageControl;

- (void)setGalleryImages:(NSArray *)arr;
- (IBAction)pageControllClicked:(id)sender;

@end

@implementation ImageGallery

- (void)awakeFromNib {
    self.scrollView.delegate = self;
    self.pageControl.pageIndicatorTintColor = UIColorFromRGBA(0x5A62D244);
    self.pageControl.currentPageIndicatorTintColor = UIColorFromRGB(0x5A62D2);
    self.frame = setRectWidth(self.frame, SCREEN_WIDTH);
    self.scrollView.centerX = SCREEN_WIDTH / 2.0;
    self.pageControl.centerX = SCREEN_WIDTH / 2.0;
}

- (void)setGalleryImages:(NSArray *)arr {
    [[self.scrollView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    NSInteger count = 0;
    for (UIImage *image in arr) {
        GalleryItem *item = [[GalleryItem alloc] initWithFrame:CGRectMake(0, 0, BILL_IMG_WIDTH, 120)];
        [item setGalleryImage:image];
        item.frame = setRectX(item.frame, count * BILL_IMG_WIDTH);
        
        [self.scrollView addSubview:item];
        count ++;
    }
    
    self.scrollView.contentSize = CGSizeMake(count * BILL_IMG_WIDTH, 120);
    self.pageControl.numberOfPages = count;
    self.pageControl.currentPage = (NSInteger)(self.scrollView.contentOffset.x / BILL_IMG_WIDTH);
}

- (IBAction)pageControllClicked:(id)sender {
    [self.scrollView scrollRectToVisible:CGRectMake(BILL_IMG_WIDTH * self.pageControl.currentPage, 0, BILL_IMG_WIDTH, 120) animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    self.pageControl.currentPage = (NSInteger)(scrollView.contentOffset.x / BILL_IMG_WIDTH);
}

@end


@interface FundClaimFormViewController () <UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, MWPhotoBrowserDelegate> {
    MWPhotoBrowser *browser;
}
@property (strong, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet FontReplaceableBarButtonItem *submitButton;
@property (strong, nonatomic) IBOutlet UITextField *officeName;
@property (strong, nonatomic) IBOutlet UITextField *tfFirstName;
@property (strong, nonatomic) IBOutlet UITextField *tfLastName;
@property (strong, nonatomic) IBOutlet UITextField *tfStreet;
@property (strong, nonatomic) IBOutlet UITextField *tfCity;
@property (strong, nonatomic) IBOutlet UITextField *tfState;
@property (strong, nonatomic) IBOutlet UITextField *tfPostalCode;
@property (strong, nonatomic) IBOutlet UITableViewCell *addAttachment;
@property (strong, nonatomic) IBOutlet UIView *attachmentsContainer;
@property (strong, nonatomic) IBOutlet UIView *noAttachements;
@property (strong, nonatomic) IBOutlet ImageGallery *attachmentsView;
@property (weak, nonatomic) IBOutlet UITextField *amout;

@property (strong, nonatomic) NSMutableArray *attachments;


@property (weak, nonatomic) IBOutlet UILabel *fontAttributedText;
- (IBAction)backButtonPressed:(id)sender;
- (IBAction)submitButtonPressed:(id)sender;
- (IBAction)textFieldValueChanged:(id)sender;

@end

@implementation FundClaimFormViewController

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
    self.submitButton.enabled = NO;

    [[NSBundle mainBundle] loadNibNamed:@"FundClaimViews" owner:self options:nil];

    self.attachments = [NSMutableArray array];
    self.attachmentsView.layer.cornerRadius = 5;
    self.attachmentsView.clipsToBounds = YES;
    
    self.fontAttributedText.attributedText = [NSString addFont:[Utils defaultFont:16.0] toAttributed:self.fontAttributedText.attributedText];
    
    [self subscribe:EVENT_REMOVE_ATTACHMENT selector:@selector(onRemoveAttachment:)];
    [self subscribe:EVENT_CLICK_ATTACHMENT selector:@selector(onClickAttachment:)];
    
    [self subscribe:EVENT_FUND_CLAIM_ERROR selector:@selector(fundClaimError:)];
    [self subscribe:EVENT_FUND_CLAIM_SUCCESS selector:@selector(fundClaimSuccess:)];
    
    browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = YES;

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self updateSubmitButtonState];
    [self showAttachments];
}

- (void)onClickAttachment:(Event *)evt {
    [browser setCurrentPhotoIndex:[self.attachments indexOfObject:evt.data]];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:browser];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)onRemoveAttachment:(Event *)evt {
    [self.attachments removeObject:evt.data];
    [self updateSubmitButtonState];
    [self showAttachments];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 3 && indexPath.row == 0) {
        [self.tableView findAndResignFirstResponder];
        
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take photo", @"Choose from library", nil];
        [sheet showInView:self.view];
    }
}

#pragma mark - Navigation buttons
- (IBAction)backButtonPressed:(id)sender {
    UIViewController * popTo = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if (controller.class == [FundClaimViewController class]) {
            popTo = controller;
            break;
        }
    }
    if (popTo) {
        [self.navigationController popToViewController:popTo animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (IBAction)submitButtonPressed:(id)sender {
    NSString *officeName = [Utils trim:self.officeName.text];
    NSString *firstName = [Utils trim:self.tfFirstName.text];
    NSString *lastName = [Utils trim:self.tfLastName.text];
    NSString *street = [Utils trim:self.tfStreet.text];
    NSString *city = [Utils trim:self.tfCity.text];
    NSString *state = [Utils trim:self.tfState.text];
    NSString *postalCode = [Utils trim:self.tfPostalCode.text];
    NSArray *proof = self.attachments;
    CGFloat claimAmount = [self getFloatAmount:self.amout.text];
    
    NSDictionary *dict = @{
                           @"office":  officeName,
                           @"first_name": firstName,
                           @"last_name": lastName,
                           @"amount":    @(claimAmount),
                           @"shipping_street": street,
                           @"shipping_city": city,
                           @"shipping_state": state,
                           @"shipping_zip": postalCode,
                           };
    [NetworkLoadingView show];
    [[GlowFirst sharedInstance] createClaim:dict withImages:proof];
}

- (void)fundClaimError:(Event *)event {
    [NetworkLoadingView hide];
}

- (void)fundClaimSuccess:(Event *)event {
    [NetworkLoadingView hide];
    
    UIViewController * popTo = nil;
    for (UIViewController * controller in self.navigationController.viewControllers) {
        if (controller.class == [FundClaimViewController class]) {
            popTo = controller;
            break;
        }
    }
    if (popTo) {
        [self.navigationController popToViewController:popTo animated:YES];
    } else {
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (void)updateSubmitButtonState {
    BOOL done = YES;
    
    if (![self.attachments count]) {
        done = NO;
    } else if ([self getFloatAmount:self.amout.text] == 0) {
        done = NO;
    } else {
        NSArray *tfArrays = @[self.officeName, self.tfFirstName, self.tfLastName, self.tfStreet, self.tfCity, self.tfState, self.tfPostalCode];
        for (UITextField *tf  in tfArrays) {
            if ([[Utils trim:tf.text] isEqualToString:@""]) {
                done = NO;
                break;
            }
        }
    }
    
    self.submitButton.enabled = done;

}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.officeName) {
        [self.tfFirstName becomeFirstResponder];
    } else if (textField == self.tfFirstName) {
        [self.tfLastName becomeFirstResponder];
    } else if (textField == self.tfLastName) {
        [self.tfStreet becomeFirstResponder];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    } else if (textField == self.tfStreet) {
        [self.tfCity becomeFirstResponder];
    } else if (textField == self.tfCity) {
        [self.tfState becomeFirstResponder];
    } else if (textField == self.tfState) {
        [self.tfPostalCode becomeFirstResponder];
    } else if (textField == self.tfPostalCode) {
        [textField resignFirstResponder];
    } else if (textField == self.amout) {
        return YES;
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.amout) {
        [UIView animateWithDuration:0.2 animations:^(void){} completion:^(BOOL finished) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }];
    }
}

- (IBAction)textFieldValueChanged:(id)sender {
    [self updateSubmitButtonState];
}

- (CGFloat)getFloatAmount:(NSString *)text {
    if (text.length == 0) return 0;
    NSString * s = [text substringFromIndex:1];
    return [s floatValue];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.amout) {
        NSInteger lengthOfString = string.length;
        NSString * old = textField.text;
        NSString * new = nil;
        
        if (!lengthOfString) {
            new =  [old substringToIndex:old.length - 1];
            CGFloat curValue = [self getFloatAmount:new];
            if (curValue == 0) {
                textField.text = @"";
            } else {
                textField.text = [NSString stringWithFormat:@"$%.2f", curValue / 10.0];
            }
        } else if (lengthOfString > 1) {
            return NO;
        } else {
            unichar character = [string characterAtIndex:0];
            if (character < 48) return NO; // 48 unichar for 0
            if (character > 57) return NO; // 57 unichar for 9
            
            int v = [string intValue];
            CGFloat curValue = [self getFloatAmount:old];
            CGFloat newValue = (curValue * 10 * 100 + v) * 1.0 / 100;
            textField.text = [NSString stringWithFormat:@"$%.2f", newValue];
        }
        [self updateSubmitButtonState];
        return NO;
    }
    return YES;
}


#pragma mark - UIImagePickerControllerDelegate
- (BOOL) startMediaBrowser:(UIImagePickerControllerSourceType)type fromViewController: (UIViewController*) controller
                               usingDelegate: (id <UIImagePickerControllerDelegate,
                                               UINavigationControllerDelegate>) delegate {
    
    if (([UIImagePickerController isSourceTypeAvailable:
          type] == NO)
        || (delegate == nil)
        || (controller == nil))
        return NO;
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = type;
    mediaUI.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:
     type];
    
    mediaUI.allowsEditing = YES;
    mediaUI.delegate = delegate;
    
    [controller presentViewController:mediaUI animated:YES completion:nil];
    return YES;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    [self.attachments addObject:image];

    [browser reloadData];
    
    [self updateSubmitButtonState];
    [self showAttachments];
}


#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self startMediaBrowser:UIImagePickerControllerSourceTypeCamera
                 fromViewController: self
                      usingDelegate: self];
            
            break;
        case 1:
            [self startMediaBrowser:UIImagePickerControllerSourceTypePhotoLibrary
                 fromViewController: self
                      usingDelegate: self];
            break;
        default:
            break;
    }

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];

}

#pragma mark -
- (void)showAttachments {
    [self.attachmentsContainer.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.attachmentsContainer addSubview: self.attachmentsView];
    [self.attachmentsView setGalleryImages:self.attachments];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return self.attachments.count;
}

- (MWPhoto *)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    if (index < self.attachments.count) {
        return [MWPhoto photoWithImage:[self.attachments objectAtIndex:index]];
    }
    return nil;
}
@end

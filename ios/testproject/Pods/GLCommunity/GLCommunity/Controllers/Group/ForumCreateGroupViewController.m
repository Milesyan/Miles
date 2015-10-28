//
//  CreateGroupViewController.m
//  emma
//
//  Created by Xin Zhao on 7/15/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLImagePicker.h>
#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/UIImage+Resize.h>
#import <GLFoundation/UIView+FindAndResignFirstResponder.h>
#import <GLFoundation/GLPillButton.h>
#import <Masonry/Masonry.h>
#import "Forum.h"
#import "ForumCreateGroupViewController.h"
#import "GroupCategoryRow.h"

@interface ForumCreateGroupViewController () <GLImagePickerDelegate,
    UIScrollViewDelegate, GLExclusivePillButtonGroupDelegate,
    UITextViewDelegate, UITableViewDataSource, UITableViewDelegate>
{
    NSMutableArray *groupCategories;
    GLExclusivePillButtonGroup *categoryButtonGroup;
    int64_t selectedCid;
}

@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *descPlaceholder;
@property (weak, nonatomic) IBOutlet UITextView *groupDescTextView;
@property (weak, nonatomic) IBOutlet UIView *categoryButtonsContainer;
@property (weak, nonatomic) IBOutlet UIView *step3Container;
@property (weak, nonatomic) IBOutlet UITableView *categoriesTable;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *addGroupPhotoView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *uploadImageLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextBarButtonItem;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryTableViewContainerHeightConstraint;
@property (weak, nonatomic) IBOutlet UIView *containerView;
@end

@implementation ForumCreateGroupViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    categoryButtonGroup = [[GLExclusivePillButtonGroup alloc] init];
    categoryButtonGroup.delegate = self;
  
    [self.groupNameTextField addTarget:self action:
        @selector(nameTextFieldDidChange:) forControlEvents:
        UIControlEventEditingChanged];
   
    self.groupDescTextView.delegate = self;
    
    self.scrollView.delegate = self;
    
    [self.categoriesTable registerNib:[UINib nibWithNibName:@"GroupCategoryRow"
        bundle:nil] forCellReuseIdentifier:CELL_ID_GROUP_CATEGORY];
    self.categoriesTable.delegate = self;
    self.categoriesTable.dataSource = self;
    
    self.addGroupPhotoView.layer.cornerRadius =
        self.addGroupPhotoView.frame.size.height / 2;
    self.addGroupPhotoView.clipsToBounds = YES;
    
    selectedCid = 0;
    [self layoutCategoriesButtons];
    [self.containerView mas_updateConstraints:^(MASConstraintMaker *maker)
    {
        maker.width.equalTo(@([UIScreen mainScreen].bounds.size.width));
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
//    [self repositionImageUploaderContainer];
    [self refreshNextButton];
    
    [self layoutUploadImageView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_CREATE_GROUP];
}

- (void)viewDidLayoutSubviews
{
    self.scrollView.contentSize = [self.containerView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
}

- (void)setGroupCategories:(NSArray *)categories
{
    groupCategories = [categories mutableCopy];
}

#pragma mark - naviagation and nav bar button items
- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)nextButtonClicked:(id)sender {
    if (!selectedCid) {
        [self showSimpleAlertViewWithtMesssage:@"Please choose one category."];
        return;
    }
    if (![Forum isLoggedIn]) {
        [Forum actionRequiresLogin];
        return;
    }
    [Forum log:BTN_CLK_FORUM_CREATE_GROUP];

    self.nextBarButtonItem.enabled = NO;
    UIImage *photo = self.imageView.image ? self.imageView.image : nil;
    [GLNetworkLoadingView showWithDelay:10];
    [Forum createGroupWithName: self.groupNameTextField.text categoryId:
        selectedCid desc:self.groupDescTextView.text
        photo:photo callback:^(NSDictionary *result, NSError *error) {
        
        [GLNetworkLoadingView hide];
        [self createGroupCompletionResult:result error:error];
    }];
}

- (void)createGroupCompletionResult:(NSDictionary *)res error:(NSError *)err
{
    if (!err && [res[@"rc"] intValue] == RC_SUCCESS) {
        [self.navigationController popViewControllerAnimated:NO from:self];
        ForumGroup *group = [[ForumGroup alloc] initWithDictionary:res[@"group"]];
        [self publish:EVENT_FORUM_GROUP_CREATED data:group];
        return;
    } else {
        NSString *errMsg = res[@"msg"] ?: @"Creating group failed. Please try again later.";
        [self showSimpleAlertViewWithtMesssage:errMsg];
        self.nextBarButtonItem.enabled = YES;
    }
}

- (void)refreshNextButton
{
    GLLog(@"zx debug %@", [self.groupNameTextField.text stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]]);
    
    BOOL currentStatus = self.nextBarButtonItem.enabled;
    if (![[self.groupNameTextField.text stringByTrimmingCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqual:@""] &&
        selectedCid != 0 &&
        self.imageView.image) {
        self.nextBarButtonItem.enabled = YES;
        if (!currentStatus) {
            [[GLDropdownMessageController sharedInstance] postMessage:@"Click “Create” and you’re done!" duration:3 position:84 inView:[GLUtils keyWindow]];
        }
    }
    else {
        self.nextBarButtonItem.enabled = NO;
    }
}

#pragma mark - group name text field
- (void)nameTextFieldDidChange:(id)sender {
    [self refreshNextButton];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return NO;
    }
    NSUInteger newLength = textView.text.length + text.length - range.length;
    NSUInteger maxLength = 0;
    maxLength = 100;
    
    self.descPlaceholder.hidden = newLength > 0;
    return (newLength > maxLength) ? NO : YES;
}

# pragma mark - add group phote/image
- (void)layoutUploadImageView
{
    if (!self.imageView.image) {
        self.addGroupPhotoView.hidden = YES;
        self.uploadImageLabel.text = @"Add a group photo";
    } else {
        self.addGroupPhotoView.hidden = NO;
        self.uploadImageLabel.text = @"          Update photo";
    }
}

- (IBAction)insertImage:(id)sender {
    [[GLImagePicker sharedInstance] showInController:self withTitle:
        @"Choose photo to insert" destructiveButtonTitle:nil allowsEditing:NO];
}

- (void)imagePickerDidCancel:(GLImagePicker *)imagePicker
{
    [self layoutUploadImageView];
    [self refreshNextButton];
}

- (void)imagePicker:(GLImagePicker *)imagePicker didPickedImage:(UIImage *)image
{
    if (image.size.width > 148.0) {
        image = [image resizedImage:(CGSize){148.0,
            image.size.height / image.size.width * 148.0}
            interpolationQuality:kCGInterpolationMedium];
        [self.imageView setImage:image];
    }
    [self layoutUploadImageView];
    [self refreshNextButton];
}


# pragma mark - category buttons
- (void)fetchGroupCategoriesCompletionResult:(NSDictionary *)res
    error:(NSError *)err
{
    if (!err && res[@"categories"]) {
        groupCategories = [res[@"categories"] mutableCopy];
        [self.categoriesTable reloadData];
        [self layoutCategoriesButtons];
        // set categories labels
    }
}

- (void)pillButtonDidChange:(GLGroupedPillButton *)button
{
    [self refreshNextButton];
}

- (void)layoutCategoriesButtons {
    if (groupCategories.count == 0) {
        return;
    }
    self.categoryTableViewContainerHeightConstraint.constant = groupCategories.count * 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return groupCategories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= groupCategories.count) {
        return nil;
    }
    GroupCategoryRow *cell = [tableView dequeueReusableCellWithIdentifier:
        CELL_ID_GROUP_CATEGORY forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    NSDictionary *category = groupCategories[indexPath.row];
    [cell setupWithColor:UIColorFromRGB([category[@"category_color"] intValue]) name:category[@"name"]];
    if (selectedCid == [groupCategories[indexPath.row][@"id"]
        unsignedLongLongValue]) {
        [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
    } else {
        [cell setAccessoryType:UITableViewCellAccessoryNone];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedCid = [groupCategories[indexPath.row][@"id"] unsignedLongLongValue];
    [self.categoriesTable reloadData];
    [self refreshNextButton];
}

# pragma mark - alert view
- (void)showSimpleAlertViewWithtMesssage:(NSString *)msg
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
        message:msg delegate:self cancelButtonTitle:@"OK"
        otherButtonTitles:nil];
    [alertView show];
}

# pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view findAndResignFirstResponder];
}

@end

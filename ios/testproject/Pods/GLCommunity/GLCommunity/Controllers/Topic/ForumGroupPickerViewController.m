//
//  ForumGroupPickerViewController.m
//  emma
//
//  Created by Allen Hsu on 8/26/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLFoundation.h>
#import "ForumGroupPickerViewController.h"
#import "Forum.h"

@interface ForumGroupPickerCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UIView *colorCircle;

- (void)setupWithColor:(UIColor *)color name:(NSString *)name;

@end

@implementation ForumGroupPickerCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWithColor:(UIColor *)color name:(NSString *)name
{
    self.colorCircle.layer.cornerRadius = self.colorCircle.frame.size.height / 2;
    self.colorCircle.clipsToBounds = YES;
    self.colorCircle.backgroundColor = color;
    self.title.text = name;
}

@end

@interface ForumGroupPickerViewController ()

@property (strong, nonatomic) NSArray *groups;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@end

@implementation ForumGroupPickerViewController

+ (id)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"GroupPicker"];
}

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
    
    self.groups = [[Forum sharedInstance].subscribedGroups copy];
    @weakify(self)
    [Forum fetchGroupsPageCallback:^(NSDictionary *result, NSError *error) {
        @strongify(self)
        self.groups = [[Forum sharedInstance].subscribedGroups copy];
        [self.tableView reloadData];
    }];
    UIImage *closeImg = [UIImage imageNamed:@"gl-community-topnav-close"];
    UIImage *closeImgPressed = [UIImage imageNamed:@"gl-community-topnav-close-press"];
    
    SEL leftButtonAction = nil;
    UIImage *leftImg = nil;
    UIImage *leftImgPressed = nil;
   
    if (self.navigationController.viewControllers.count > 1) {
        
    } else {
        leftImg = closeImg;
        leftImgPressed = closeImgPressed;
        leftButtonAction = @selector(dismissSelf:);
         self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:leftImg style:UIBarButtonItemStylePlain target:self action:leftButtonAction];
    }
    
    self.enabled = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [Forum log:PAGE_IMP_FORUM_CREATE_PICK_GROUP];
}

- (IBAction)goBack:(id)sender
{
    if ([self.navigationController.viewControllers lastObject] == self) {
        // we already checked here
        [self.navigationController popViewControllerAnimated:YES from:self];
    }
}

- (IBAction)dismissSelf:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.groups.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ForumGroupPickerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GroupPickerCell" forIndexPath:indexPath];
    
    if (indexPath.row < self.groups.count) {
        ForumGroup *group = self.groups[indexPath.row];
        ForumCategory *category = [Forum categoryFromGroup:group];
        UIColor *color = category ? [UIColor colorFromWebHexValue:category.backgroundColor] : GLOW_COLOR_PURPLE;
        [cell setupWithColor:color name:group.name];
        if (self.selectedIndexPath && [self.selectedIndexPath isEqual:indexPath]) {
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
        } else {
            [cell setAccessoryType:UITableViewCellAccessoryNone];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.enabled && indexPath.row < self.groups.count) {
        self.selectedIndexPath = indexPath;
        [self.tableView reloadData];
        [self refreshNextButton];
    }
}

- (void)refreshNextButton
{
    if (self.selectedIndexPath) {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

- (IBAction)nextButtonClicked:(id)sender {
    if (self.selectedIndexPath && self.selectedIndexPath.row < self.groups.count) {
        ForumGroup *group = self.groups[self.selectedIndexPath.row];
        [Forum log:BTN_CLK_FORUM_CREATE_PICK_GROUP eventData:@{@"group_id": @(group.identifier)}];
        if ([self.delegate respondsToSelector:@selector(groupPicker:didPickGroup:)]) {
            [self.delegate groupPicker:self didPickGroup:group];
        }
    }
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        self.navigationItem.leftBarButtonItem.enabled = enabled;
        self.tableView.allowsSelection = enabled;
        if (enabled) {
            [self refreshNextButton];
        } else {
            self.navigationItem.rightBarButtonItem.enabled = enabled;
        }
    }
}

@end

//
//  ForumGroupsViewController.m
//  emma
//
//  Created by Jirong Wang on 8/20/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import <GLFoundation/GLNetworkLoadingView.h>
#import <GLFoundation/GLDropdownMessageController.h>
#import <GLFoundation/GLFoundation.h>
#import <GLFoundation/GLPillGradientButton.h>
#import <GLFoundation/GLIOS67CompatibleUIButton.h>
#import <GLFoundation/UIImage+Utils.h>
#import "ForumGroupsViewController.h"
#import "ForumMyGroupsViewController.h"
#import "ForumFeaturedGroupsViewController.h"
#import "ForumSeeAllViewController.h"
#import "Forum.h"
#import "ForumCreateGroupViewController.h"
#import "ForumGroupRoomViewController.h"

#define SEGMENT_FEATURED_GROUP 0
#define SEGMENT_MY_GROUP       1

@interface ForumGroupsViewController () <UIScrollViewDelegate>

@property (nonatomic) NSMutableArray *categoriesAndGroupsPreview;

@property (weak, nonatomic) IBOutlet UITableView *featuredTable;
@property (weak, nonatomic) IBOutlet UITableView *myGroupTable;

@property (weak, nonatomic) IBOutlet GLPillGradientButton *createButton;
@property (weak, nonatomic) IBOutlet UIView *createButtonView;

@property (nonatomic) ForumMyGroupsViewController * myGroupsViewController;
@property (nonatomic) ForumFeaturedGroupsViewController * featuredGroupsViewController;
@property (weak, nonatomic) IBOutlet UISegmentedControl *myGroupSegment;

- (IBAction)backButtonClicked:(id)sender;
- (IBAction)createClicked:(id)sender;
- (IBAction)segmentClicked:(id)sender;

@end

@implementation ForumGroupsViewController

+ (ForumGroupsViewController *)viewController
{
    return [[Forum storyboard] instantiateViewControllerWithIdentifier:@"groupsViewController"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.isMyGroups = NO;
    [self.createButton setupColorWithNoBorder:[UIColor whiteColor] toColor:UIColorFromRGB(0xf5f6f7)];
    if (self.isMyGroups) {
        if ([self.navigationController.viewControllers firstObject] == self) {
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(didClickDone:)];
            self.navigationItem.rightBarButtonItem = doneButton;
        }
        self.createButtonView.hidden = YES;
        self.myGroupTable.editing = YES;
        self.navigationItem.title = @"My groups";
        self.myGroupsViewController = [[ForumMyGroupsViewController alloc] init];
        self.myGroupsViewController.tableView = self.myGroupTable;
        self.myGroupsViewController.scrollDelegate = self;
        self.myGroupTable.delegate = self.myGroupsViewController;
        self.myGroupTable.dataSource = self.myGroupsViewController;
        [self.myGroupsViewController setup];
        [self addChildViewController:self.myGroupsViewController];
    } else {
        if ([self.navigationController.viewControllers firstObject] == self) {
            UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(didClickDone:)];
            self.navigationItem.rightBarButtonItem = doneButton;
        }
        self.createButtonView.hidden = NO;
        self.navigationItem.title = @"Add groups";
        self.featuredGroupsViewController = [[ForumFeaturedGroupsViewController alloc] init];
        self.featuredGroupsViewController.tableView = self.featuredTable;
        self.featuredGroupsViewController.scrollDelegate = self;
        self.featuredTable.delegate = self.featuredGroupsViewController;
        self.featuredTable.dataSource = self.featuredGroupsViewController;
        [self.featuredGroupsViewController setup];
        [self addChildViewController:self.featuredGroupsViewController];
        [self subscribe:EVENT_FORUM_GROUP_CREATED selector:@selector(newGroupCreated:)];
    }
    
//    GLIOS67CompatibleUIButton *customButton = [[GLIOS67CompatibleUIButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 39.0)];
//    customButton.backgroundColor = [UIColor clearColor];
//
//    UIImage *backImage = [UIImage imageNamed:@"gl-community-top-nav-dropdown"];
//    backImage = [backImage imageWithTintColor:UIColorFromRGB(0x6C6DD3)];
//    
//    UIImageView *arrowImage = [[UIImageView alloc] initWithImage:backImage];
//    arrowImage.contentMode = UIViewContentModeCenter;
//    arrowImage.frame = CGRectMake(-8, 7, backImage.size.width, backImage.size.height);
//    [customButton addSubview:arrowImage];
//    arrowImage.transform = CGAffineTransformRotate(CGAffineTransformIdentity, (90 * M_PI) / 180.0);
    
//    self.createButton.layer.cornerRadius = 19;
    self.createButtonView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.createButtonView.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    self.createButtonView.layer.shadowOpacity = 0.25;
    self.createButtonView.layer.shadowRadius = 1.0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

//- (void)viewDidLayoutSubviews
//{
//    self.createButtonView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.createButtonView.bounds].CGPath;
//}


# pragma mark - IB action
- (IBAction)backButtonClicked:(id)sender {
    [Forum log:BTN_CLK_BACK_TO_GROUPS_HOME];
    [self.navigationController popViewControllerAnimated:YES from:self];
}

- (IBAction)createClicked:(id)sender {
    [Forum log:BTN_CLK_MY_GROUPS_CREATE_GROUP];
    // [self _hideSearchBar];
    [GLNetworkLoadingView showWithDelay:10];
    [Forum fetchPrerequisiteForCreatingGroupCallback:^(NSDictionary *result, NSError *error) {
        [GLNetworkLoadingView hide];
        if (error) {
            [[GLDropdownMessageController sharedInstance] postMessage:@"Network error. Please try again later." duration:3 position:84 inView:[GLUtils keyWindow]];
            return;
        }
        if ([result[@"qualified"] boolValue]) {
            [self performSegueWithIdentifier:@"createGroup" sender:result[@"categories"] from:self];
        } else {
            NSString *msg = result[@"msg"] ? result[@"msg"] : @"You cannot create group for now. Please try later.";
            [[GLDropdownMessageController sharedInstance] postMessage:msg duration:3 position:84 inView:[GLUtils keyWindow]];
        }
    }];
}

- (void)newGroupCreated:(Event *)event {
    ForumGroup *group = (ForumGroup *)event.data;
    [self performSegueWithIdentifier:@"viewGroup" sender:group from:self];
}

- (IBAction)segmentClicked:(id)sender {
    switch (self.myGroupSegment.selectedSegmentIndex) {
        case SEGMENT_FEATURED_GROUP:
            self.isMyGroups = NO;
            [Forum log:BTN_CLK_FORUM_GROUP_FEATURED];
            break;
        case SEGMENT_MY_GROUP:
            [Forum log:BTN_CLK_FORUM_MY_GROUPS];
            self.isMyGroups = YES;
            break;
        default:
            break;
    }
    [self refresh];
}

- (void)refresh {
    self.featuredTable.hidden = self.isMyGroups;
    self.myGroupTable.hidden  = !self.isMyGroups;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([@"findToSeeall" isEqualToString:segue.identifier]) {
        ForumSeeAllViewController *dest = (ForumSeeAllViewController *)segue.destinationViewController;
        NSDictionary *category = (NSDictionary*)sender;
        dest.category = [[ForumCategory alloc] initWithDictionary:category];
    } else if ([@"createGroup" isEqualToString:segue.identifier]) {
        ForumCreateGroupViewController *dest = (ForumCreateGroupViewController *)segue.destinationViewController;
        NSArray *categories = (NSArray *)sender;
        [dest setGroupCategories:categories];
    } else if ([@"viewGroup" isEqualToString:segue.identifier]) {
        ForumGroup *group = (ForumGroup *)sender;
        ForumCategory *cat = [Forum categoryFromGroup:group];
        ForumGroupRoomViewController *controller = (ForumGroupRoomViewController *)segue.destinationViewController;
        controller.category = cat;
        controller.group = group;
    } else if ([@"viewBookmarkGroup" isEqualToString:segue.identifier]) {
//        ForumCategoryType categoryType = [[(NSDictionary *)sender objectForKey:@"bookmarkType"] intValue];
        ForumGroupRoomViewController *controller = (ForumGroupRoomViewController *)segue.destinationViewController;
        controller.category = [ForumCategory bookmarkCategory];
//        controller.bookmarkType = categoryType;
        ForumGroup *group = [ForumGroup bookmarkedGroup];
        controller.group = group;
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.scrollDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)]) {
        [self.scrollDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ([self.scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)]) {
        [self.scrollDelegate scrollViewDidEndDecelerating:scrollView];
    }
}

- (IBAction)didClickDone:(id)sender
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

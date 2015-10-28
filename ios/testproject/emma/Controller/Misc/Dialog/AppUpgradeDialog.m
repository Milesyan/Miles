//
//  AppUpgradeDialog.m
//  emma
//
//  Created by Jirong Wang on 4/10/13.
//  Copyright (c) 2013 Upward Labs. All rights reserved.
//

#import "AppUpgradeDialog.h"
#import "Logging.h"
#import "Network.h"
#import "PillGradientButton.h"
#import "Logging.h"
#import "Utils.h"
#import "AppDelegate.h"

@interface NewVersionInfoCell()

@property (weak, nonatomic) IBOutlet UILabel *updateInfoLabel;
@property (weak, nonatomic) IBOutlet UIImageView *infoCellStar;

@end

@implementation NewVersionInfoCell

- (void)awakeFromNib {
    [self.infoCellStar setImage:[Utils imageNamed:@"star" withColor:UIColorFromRGB(0xffc000)]];
    self.infoCellStar.backgroundColor = [UIColor clearColor];
}

- (void)setLabelText:(NSString *)text {
    self.updateInfoLabel.text = text;
    [self.updateInfoLabel setFrame:setRectHeight(self.updateInfoLabel.frame, [NewVersionInfoCell getTextHeight:text])];
}

+ (CGFloat)getTextHeight:(NSString *)text {
    CGSize size = [text boundingRectWithSize:CGSizeMake(205, 1000)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:@{NSFontAttributeName: [Utils lightFont:15]}
                                       context:nil].size;
    return roundf(size.height) + 16;
}

@end


@interface AppUpgradeDialog () {
    NSString * latestVersion;
    NSArray * newVersionInfo;
    
    __weak IBOutlet UILabel *versionLabel;
    __weak IBOutlet PillGradientButton *downloadButton;
    __weak IBOutlet UIView *topGradientMask;
    __weak IBOutlet UIView *bottomGradientMask;
}
@property (weak, nonatomic) IBOutlet UITableView *infoTableView;
@property (nonatomic)BOOL upgradeDlgOpened;

- (IBAction)downloadButtonPressed:(id)sender;

@end

@implementation AppUpgradeDialog

static AppUpgradeDialog *_upgradeDlg = nil;
// We have to use static value, because Both "Network" and "NetworkWithLog" are using this
static NSDate *_remindUpgradeTime = nil;

+ (AppUpgradeDialog *)getInstance {
    if (!_upgradeDlg) {
        _upgradeDlg = [[AppUpgradeDialog alloc] init];
    }
    return _upgradeDlg;
}

- (id)init {
    self = [super init];
    
    @weakify(self)
    [self subscribe:EVENT_UPGRADE_APP_VERSION handler:^(Event *evt){
        @strongify(self)
        NSDictionary *result = (NSDictionary *)evt.data;
        [self checkUpgradeAppVersion:result];
    }];
    self.upgradeDlgOpened = NO;
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)setLatestVersion:(NSString *)version versionInfo:(NSArray *)versionInfo {
    latestVersion = [[NSString alloc] initWithString:version];
    newVersionInfo = [NSArray arrayWithArray:versionInfo];
    [versionLabel setText:latestVersion];
    [self.infoTableView reloadData];
}

- (void)checkUpgradeAppVersion:(NSDictionary *)result {
    NSNumber *rc         = [result objectForKey:@"rc"];
    NSNumber *tooOld     = [result objectForKey:@"too_old_version"];
    NSNumber *newVersion = [result objectForKey:@"has_new_version"];
    NSString *latest     = [result objectForKey:@"latest_version"];
    NSArray *versionInfo = [result objectForKey:@"version_info"];
    
    if ((rc && [rc intValue] == -100) && (tooOld && [tooOld intValue] == 1)) {
        // remind timer is less than now. open the remind upgrade dialog
        [self setLatestVersion:latest versionInfo:versionInfo];
        [((AppDelegate *)[UIApplication sharedApplication].delegate) pushDialog:@{@"dialog":self, @"type":@(AppUpgradeDialogPresentTypeEnforce)}];
//        [self presentWithEnforce];
    } else if (newVersion && [newVersion intValue] == 1) {
        if ([self.remindUpgradeTime compare:[NSDate date]] == NSOrderedAscending) {
            // remind timer is less than now. open the remind upgrade dialog
            [self setLatestVersion:latest versionInfo:versionInfo];
            [((AppDelegate *)[UIApplication sharedApplication].delegate) pushDialog:@{@"dialog":self, @"type":@(AppUpgradeDialogPresentTypeRemind)}];
//            [self presentWithRemind];
        }
    } else {
        // The current version is the latest version. clear the remindUpgradeTime
        self.remindUpgradeTime = nil;
    }
}

- (void)setRemindUpgradeTime:(NSDate *)date {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:date forKey:@"remindUpgradeTime"];
    [defaults synchronize];
    _remindUpgradeTime = date;
}

- (NSDate *)remindUpgradeTime {
    if (!_remindUpgradeTime) {
        _remindUpgradeTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"remindUpgradeTime"];
        if (!_remindUpgradeTime) {
            NSDate *date = [NSDate dateWithTimeIntervalSinceNow:-1];
            [self setRemindUpgradeTime:date];
            _remindUpgradeTime = date;
        }
    }
    return _remindUpgradeTime;
}

- (void)delayRemindUpgrade {
    self.remindUpgradeTime = [NSDate dateWithTimeIntervalSinceNow: DELAY_REMIND_TIME];
}

- (void)presentWithRemind {
    self.dialog = [GLDialogViewController sharedInstance];
    if (([self.dialog isOpened]) || (self.upgradeDlgOpened)) {
        // if a dialog is opened, do not open "remind upgrade dialog" to protect the main logic
        return;
    }
    
    self.upgradeDlgOpened = YES;
    [self subscribeOnce:EVENT_DIALOG_CLOSE_BUTTON_CLICKED obj:self.dialog selector:@selector(onCloseButtonClicked:)];
    [Logging log:PAGE_IMP_APP_UPGRADE_DLG];
    [self.dialog presentWithContentController:self canClose:YES];
}

- (void)presentWithEnforce {
    self.dialog = [GLDialogViewController sharedInstance];
    // if "upgrade app dialog is opened", do nothing.
    if (self.upgradeDlgOpened) {
        return;
    }
    // if a dialog is open, but not the "upgrade app dialog", close it
    if ([self.dialog isOpened]) {
        // we must ask user to upgrade the app
        [self.dialog close];
    }
    
    // Yes, in this path, user could not continue the main logic, because "upgradeDlgOpened" will never be NO again.
    self.upgradeDlgOpened = YES;
    [Logging log:PAGE_IMP_APP_UPGRADE_DLG];
    [self.dialog presentWithContentController:self canClose:NO];
}

- (void)onCloseButtonClicked:(Event *)evt {
    [self delayRemindUpgrade];
    self.upgradeDlgOpened = NO;
    // logging
    [Logging log:BTN_CLK_UPGRADE_CANCEL eventData:@{@"latest_version": @([Utils versionToNumber:latestVersion])}];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [versionLabel setText:latestVersion];
    
    // set button color
    [downloadButton setupWithColor:[UIColor whiteColor] toColor:UIColorFromRGB(0xf2f4f5)];
    
    // upgrade information table views
    [self.infoTableView registerNib:[UINib nibWithNibName:@"NewVersionInfoCell" bundle:nil] forCellReuseIdentifier:@"NewVersionInfoCell"];
    
    // gradient masks
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = topGradientMask.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGBA(0xfbfaf7ff) CGColor], (id)[UIColorFromRGBA(0xfbfaf700) CGColor], nil];
    [topGradientMask.layer insertSublayer:gradient atIndex:0];
    
    CAGradientLayer *gradient2 = [CAGradientLayer layer];
    gradient2.frame = bottomGradientMask.bounds;
    gradient2.colors = [NSArray arrayWithObjects:(id)[UIColorFromRGBA(0xfbfaf700) CGColor], (id)[UIColorFromRGBA(0xfbfaf7ff) CGColor], nil];
    [bottomGradientMask.layer insertSublayer:gradient2 atIndex:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return newVersionInfo.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewVersionInfoCell *cell = [self.infoTableView dequeueReusableCellWithIdentifier:@"NewVersionInfoCell"];
    [cell setLabelText:[newVersionInfo objectAtIndex:indexPath.row]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [NewVersionInfoCell getTextHeight:[newVersionInfo objectAtIndex:indexPath.row]];
}

- (IBAction)downloadButtonPressed:(id)sender {
    [Logging syncLog:BTN_CLK_UPGRADE_DOWNLOAD eventData:@{@"latest_version": @([Utils versionToNumber:latestVersion])}];
    // Go to glowing.com/downloadapp
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:DOWNLOAD_APP_URL]];
}
@end

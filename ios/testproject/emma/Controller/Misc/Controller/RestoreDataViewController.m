//
//  RestoreDataViewController.m
//  emma
//
//  Created by Ryan Ye on 4/16/14.
//  Copyright (c) 2014 Upward Labs. All rights reserved.
//

#import "RestoreDataViewController.h"
#import "ZipArchive.h"

@interface RestoreDataViewController () {
    IBOutlet UILabel *downloadLabel;
    IBOutlet UIActivityIndicatorView *spinner;
    IBOutlet UILabel *instructionLabel;
}

@property (nonatomic, strong) NSString *userToken;
@end

@implementation RestoreDataViewController

- (id)initWithUserToken:(NSString *)userToken {
    self = [super initWithNibName:@"RestoreDataViewController" bundle:nil];
    if (self) {
        self.userToken = userToken;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self download];
    // Do any additional setup after loading the view.
}

- (void)download {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *url=[Utils apiUrl:@"users/debug_report" query:@{@"ut": self.userToken}];
        GLLog(@"download url:%@", url);
        NSData *reportData = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        BOOL success = (reportData != nil);
        if (reportData) {
            [self restoreDataFrom:reportData];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [spinner stopAnimating];
            if (success) {
                downloadLabel.text = @"Download completed!";
                instructionLabel.hidden = NO;
            } else {
                downloadLabel.text = @"Unable to download the data. Please try again later.";
            }
        });
    });
}

- (void)restoreDataFrom:(NSData *)data {
    [Utils clearAllAppData];

    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *zipFilePath = [cacheDir stringByAppendingPathComponent:@"debug_report.zip"];
    [data writeToFile:zipFilePath atomically:YES];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    ZipArchive *zip = [[ZipArchive alloc] initWithFileManager:fileManager]; 
    NSString *unzipDir = [cacheDir stringByAppendingPathComponent:@"debug_report"];
    [zip UnzipOpenFile:zipFilePath];
    [zip UnzipFileTo:unzipDir overWrite:YES];

    // put core data file to support directory
    NSString *unzippedDbPath = [unzipDir stringByAppendingPathComponent:@"default.db"];
    NSString *supportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [fileManager moveItemAtPath:unzippedDbPath
                         toPath:[supportDir stringByAppendingPathComponent:@"default.db"]
                          error:nil];
    NSString *unzippedJournalPath = [NSString stringWithFormat:@"%@-wal", unzippedDbPath]; 
    if ([fileManager fileExistsAtPath:unzippedJournalPath]) {
        [fileManager moveItemAtPath:unzippedJournalPath
                             toPath:[supportDir stringByAppendingPathComponent:@"default.db-wal"]
                              error:nil];
    }
    // put user default to preference directory
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *settingsPath = [NSString stringWithFormat:@"Preferences/%@.plist",[[NSBundle mainBundle] bundleIdentifier]];
    [fileManager moveItemAtPath:[unzipDir stringByAppendingPathComponent:@"user_settings.plist"]
                         toPath:[libDir stringByAppendingPathComponent:settingsPath]
                          error:nil];
}

- (void)clearAppData {
    // clear NSUserDefaults
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    // clear local files
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [Utils clearDirectory:docDir];
    NSString *supportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    [Utils clearDirectory:supportDir];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

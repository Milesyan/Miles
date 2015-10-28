//
//  User+Misc.m
//  emma
//
//  Created by Peng Gu on 5/7/15.
//  Copyright (c) 2015 Upward Labs. All rights reserved.
//

#import "User+Misc.h"
#import "ZipArchive.h"
#import "NetworkLoadingView.h"
#import "Network.h"

@implementation User (Misc)


- (void)sendDebugReportWithShowingNetwork:(BOOL)showNetwork
{
    // save all pending changes in coredata to disk
    [self save];
    
    // create a zip file
    NSString *rootDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *zipFilePath = [rootDir stringByAppendingPathComponent:@"debug_report.zip"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    ZipArchive *zip = [[ZipArchive alloc] initWithFileManager:fileManager];
    [zip CreateZipFile2:zipFilePath];
    // add core data db
    NSString *dbPath = [DataStore getDBFilePath:@"default"];
    [zip addFileToZip:dbPath newname:@"default.db"];
    // check whether there's a WAL journey file
    NSString *dbJournalPath = [NSString stringWithFormat:@"%@-wal", dbPath];
    if ([fileManager fileExistsAtPath:dbJournalPath]) {
        [zip addFileToZip:dbJournalPath newname:@"default.db-wal"];
    }
    // add NSUserDefaults
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *settingsPath = [NSString stringWithFormat:@"Preferences/%@.plist",[[NSBundle mainBundle] bundleIdentifier]];
    settingsPath = [libDir stringByAppendingPathComponent:settingsPath];
    [zip addFileToZip:settingsPath newname:@"user_settings.plist"];
    [zip CloseZipFile2];
    
    NSDictionary *report = @{
                             @"name": @"report",
                             @"filename": @"report.zip",
                             @"data": [NSData dataWithContentsOfFile:zipFilePath]
                             };
    
    if (showNetwork) {
        [NetworkLoadingView showWithoutAutoClose];
    }
    
    [[Network sharedNetwork] asyncPostFile:@"users/debug_report"
                                      data:[self postRequest:@{}]
                              requireLogin:YES files:@[report]
                         completionHandler:^(NSDictionary *result, NSError *err)
    {
        if (!showNetwork) {
            return;
        }
        
        NSString *msg = nil;
        if (!err) {
            msg = @"The debug report has been successfully uploaded!";
        } else {
            msg = @"Oops, we encounter some errors when uploading the debug report. Please try again!";
        }
        [[[UIAlertView alloc] initWithTitle:nil
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        
        [NetworkLoadingView hide];
    }];

}


@end
